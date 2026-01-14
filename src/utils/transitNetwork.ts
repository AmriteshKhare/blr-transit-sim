import stationsData from '../data/stations.json';
import * as turf from '@turf/turf';

// Types
export interface Station {
    id: string; // unique ID (can be name if unique, or generated)
    name: string;
    coordinates: [number, number]; // [lon, lat]
    lines: string[]; // Line names this station belongs to
    isInterchange: boolean;
}

export interface Edge {
    from: string;
    to: string;
    weight: number; // Time in seconds
    line: string;
    distance: number; // meters
}

export interface Graph {
    nodes: Map<string, Station>;
    edges: Map<string, Edge[]>;
}

const WALKING_SPEED_MPS = 1.0; // ~3.6 km/h for transfers
const TRANSFER_PENALTY_SEC = 450; // 7.5 minutes

// const WAIT_TIME_SEC = PEAK_HEADWAY_SEC / 2; // Average wait



const SPEED_NORMAL_MPS = (34 * 1000) / 3600; // ~9.44 m/s
const SPEED_AIRPORT_MPS = (60 * 1000) / 3600; // ~16.66 m/s

// Helper to normalize station names
const normalizeName = (name: string) => name.trim().replace(/\*$/, '').replace(/\n/g, '');

export const buildGraph = (): Graph => {
    const rawStations = stationsData.features.filter(f => f.geometry.type === 'Point');
    const rawLines = stationsData.features.filter(f => f.geometry.type === 'LineString');

    const nodes = new Map<string, Station>();
    const edges = new Map<string, Edge[]>();

    // 1. Process Lines to identify them
    // We group by Name/Description.
    // Descriptions: purple, green, yellow, pink, blue
    const lines: { name: string; color: string; geometry: any; isAirport: boolean }[] = [];

    rawLines.forEach(f => {
        const desc = f.properties?.description?.toLowerCase() || '';
        const name = f.properties?.Name || '';

        let color = 'gray';
        if (desc.includes('purple')) color = 'purple';
        else if (desc.includes('green')) color = 'green';
        else if (desc.includes('yellow')) color = 'yellow';
        else if (desc.includes('pink')) color = 'pink';
        else if (desc.includes('blue')) color = 'blue';
        else if (desc.includes('orange')) color = 'orange'; // Phase 3?

        // Check for Airport line (Phase 2B)
        // Heuristic: "KIAL" or "Airport" in name, or "Line-5" and north of KR Puram?
        // Actually, the GeoJSON has separate LineStrings. 
        // Feature 137: "Line-5: KR Puram - KIAL" -> distinct segment.
        const isAirport = name.includes('KIAL') || name.includes('Airport');
        // Or if it is the Blue line segment roughly north of lat 13.0 (KR Puram is ~13.0)

        lines.push({
            name: name,
            color,
            geometry: f.geometry,
            isAirport
        });
    });

    // 2. Map Stations to Lines
    // Since stations don't list their lines, we spatially match them.
    // A station can belong to multiple lines -> Interchange.
    // We'll create a dictionary of Station Name -> Lines it belongs to.

    // First, consolidate stations by Name (fuzzy match?) to identify single physical nodes.
    // The GeoJSON seems to have separate points for some lines? No, looks like unique points mostly.
    // Except "Majestic" (20) vs "City Railway Station" (37). They are connected but distinct?
    // "Majestic" is the interchange.

    // We will assume Points in GeoJSON are unique physical locations.
    // But we need to assign them to lines.

    const stationAssignments: { [key: string]: { id: string, dist: number }[] } = {}; // stationId -> list of {lineIndex, distOnLine}

    // Temporary list of station objects
    const tempStations: any[] = [];

    rawStations.forEach((f, idx) => {
        const id = idx.toString();
        const coords = (f.geometry as any).coordinates;
        const name = normalizeName(f.properties?.Name || `Station ${id}`);

        tempStations.push({ id, name, coords });
    });

    // For each line, find stations that are 'close' (within buffer)
    const BUFFER_DIST_KM = 0.1; // 100 meters

    lines.forEach((line) => {

        const lineStr = turf.lineString(line.geometry.coordinates);

        tempStations.forEach(st => {
            const pt = turf.point(st.coords);
            const dist = turf.pointToLineDistance(pt, lineStr, { units: 'kilometers' });

            if (dist < BUFFER_DIST_KM) {
                // Determine 'chainage' (distance along line) for sorting
                const snapped = turf.nearestPointOnLine(lineStr, pt);
                // const location = snapped.properties?.location || 0; 

                // turf.nearestPointOnLine returns 'location' in km if units not specified? 
                // Wait, turf types say index and distance.
                // We shouldn't rely on 'location' property directly across versions without checking.
                // Better: turf.length(turf.lineSlice(start, snapped, line))

                const start = turf.point(line.geometry.coordinates[0]);
                const slice = turf.lineSlice(start, snapped, lineStr);
                const distAlong = turf.length(slice, { units: 'kilometers' });

                if (!stationAssignments[st.id]) stationAssignments[st.id] = [];
                stationAssignments[st.id].push({
                    lineName: line.name,
                    lineColor: line.color,
                    isAirport: line.isAirport,
                    distAlong
                } as any);
            }
        });
    });

    // 3. Build Nodes
    tempStations.forEach(st => {
        const assignments = stationAssignments[st.id];
        if (!assignments || assignments.length === 0) {
            // Station not close to any line? Orphan. 
            // Might be a depot or planned station far off line?
            // Include it but it won't be connected.
            nodes.set(st.name, { // Use Name as ID for simplicity in Dijkstra if unique?
                // Warning: Names might duplicate "Kengeri", "Kengeri*".
                // Better use unique IDs.
                id: st.id,
                name: st.name,
                coordinates: st.coords,
                lines: [],
                isInterchange: false
            });
        } else {
            // Check for interchange
            // Using a Set of colors to count distinct lines
            const lineColors = new Set(assignments.map((a: any) => a.lineColor));
            const isInterchange = lineColors.size > 1;

            nodes.set(st.id, {
                id: st.id,
                name: st.name,
                coordinates: st.coords,
                lines: assignments.map((a: any) => a.lineColor), // Store colors as line IDs for now
                isInterchange
            });
        }
    });

    // 4. Build Edges (Line connections)
    // Group assignments by Line
    const lineStations: { [key: string]: { id: string, dist: number, isAirport: boolean }[] } = {};

    Object.keys(stationAssignments).forEach(stId => {
        stationAssignments[stId].forEach(((assignment: any) => {
            const key = assignment.lineName; // Use exact line name to segregate segments
            if (!lineStations[key]) lineStations[key] = [];
            lineStations[key].push({ id: stId, dist: assignment.distAlong, isAirport: assignment.isAirport });
        }));
    });

    Object.entries(lineStations).forEach(([lineName, stations]) => {
        // Sort by distance along line
        stations.sort((a, b) => a.dist - b.dist);

        for (let i = 0; i < stations.length - 1; i++) {
            const u = stations[i];
            const v = stations[i + 1];

            const distKm = Math.abs(v.dist - u.dist);
            const distM = distKm * 1000;

            // Determine speed
            // If segment is airport check
            const isAirportParams = u.isAirport || v.isAirport; // If the line segment is airport
            const speed = isAirportParams ? SPEED_AIRPORT_MPS : SPEED_NORMAL_MPS;

            const time = distM / speed; // seconds

            addEdge(edges, u.id, v.id, time, distM, lineName);
            addEdge(edges, v.id, u.id, time, distM, lineName);
        }
    });

    // 5. Build Interchanges (Transfers)
    // Implicit transfers: Same station ID serves multiple lines (handled by shared node).
    // BUT we need to add the Headway/Wait time penalty for switching lines?
    // In this model, if it's the SAME Node ID, logic implies instant transfer?
    // Realistically, you get off, change platform, wait.
    // To model this properly: "Split Node" approach relative to lines?
    // Or simplified: Add penalty to the *pathfinding* when 'line' property of incoming edge != outgoing edge.
    // We will do the latter in Dijkstra.

    // Explicit transfers between spatially distinct nodes with same name?
    // Let's check duplicates.
    const nameToIds: { [key: string]: string[] } = {};
    nodes.forEach(n => {
        const clean = normalizeName(n.name).toLowerCase();
        if (!nameToIds[clean]) nameToIds[clean] = [];
        nameToIds[clean].push(n.id);
    });

    Object.values(nameToIds).forEach(ids => {
        if (ids.length > 1) {
            // Connect them with Transfer edges
            for (let i = 0; i < ids.length; i++) {
                for (let j = i + 1; j < ids.length; j++) {
                    const u = ids[i];
                    const v = ids[j];
                    const dist = turf.distance(nodes.get(u)!.coordinates, nodes.get(v)!.coordinates, { units: 'meters' });

                    // Only connect if reasonable distance (e.g. < 500m)
                    if (dist < 500) {
                        const walkTime = dist / WALKING_SPEED_MPS;
                        const totalCost = walkTime + TRANSFER_PENALTY_SEC;

                        addEdge(edges, u, v, totalCost, dist, 'TRANSFER');
                        addEdge(edges, v, u, totalCost, dist, 'TRANSFER');
                    }
                }
            }
        }
    });

    return { nodes, edges };
};

function addEdge(edges: Map<string, Edge[]>, from: string, to: string, weight: number, dist: number, line: string) {
    if (!edges.has(from)) edges.set(from, []);
    edges.get(from)!.push({ from, to, weight, distance: dist, line });
}
