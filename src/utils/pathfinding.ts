import type { Graph } from './transitNetwork';

import * as turf from '@turf/turf';



const PEAK_HEADWAY = 180; // 3 min
const TRANSFER_PENALTY = 450; // 7.5 min
const INITIAL_WAIT = 90; // 1.5 min

export const findMetroPath = (graph: Graph, startId: string, endId: string) => {
    // Dijkstra
    const dists = new Map<string, number>();
    const prev = new Map<string, { id: string, line: string }>();

    // Priority Queue (simplified as array for now)
    const pq: { id: string; cost: number; lastLine: string | null }[] = [];

    // Initialize
    graph.nodes.forEach(n => {
        dists.set(n.id, Infinity);
    });

    dists.set(startId, INITIAL_WAIT); // Initial wait time
    pq.push({ id: startId, cost: INITIAL_WAIT, lastLine: null });

    while (pq.length > 0) {
        pq.sort((a, b) => a.cost - b.cost);
        const u = pq.shift()!;

        if (dists.get(u.id)! < u.cost) continue;
        if (u.id === endId) break; // Found

        const neighbors = graph.edges.get(u.id) || [];
        for (const edge of neighbors) {
            let extraCost = 0;

            // Transfer penalty logic
            // If we are already on a line (lastLine != null) and switching lines:
            if (u.lastLine !== null && u.lastLine !== edge.line && edge.line !== 'TRANSFER') {
                extraCost += TRANSFER_PENALTY + PEAK_HEADWAY;
            }
            // Note: If edge.line IS 'TRANSFER', the edge weight itself handles walking time.
            // But we might still add headway when ENTERING the new line?
            // If we took a TRANSFER edge, our 'lastLine' becomes 'TRANSFER'.
            // Then from 'TRANSFER' node to a color line, we add headway?
            // Simplify: 
            // If edge.line differs from lastLine, add penalty.
            // Exception: 'TRANSFER' edges are just walking.

            const newCost = u.cost + edge.weight + extraCost;

            if (newCost < (dists.get(edge.to) || Infinity)) {
                dists.set(edge.to, newCost);
                prev.set(edge.to, { id: u.id, line: edge.line });
                pq.push({ id: edge.to, cost: newCost, lastLine: edge.line });
            }
        }
    }

    // Reconstruct
    if (dists.get(endId) === Infinity) return null;

    const path: string[] = [];
    // const fullPath: any[] = [];

    let curr: string | undefined = endId;

    while (curr) {
        path.unshift(curr);
        const p = prev.get(curr);
        if (p) {
            // ...
            curr = p.id;
        } else {
            curr = undefined;
        }
    }

    return {
        totalTime: dists.get(endId),
        path
    };
};

export const calculateRoadTime = (
    startCoords: [number, number],
    endCoords: [number, number],
    mode: 'car' | 'bike',
    isPeakMorning: boolean
) => {
    // Mode Velocities (km/h)
    let speed = 0;
    if (mode === 'car') speed = isPeakMorning ? 12 : 10;
    else speed = isPeakMorning ? 20 : 18;

    const distKm = turf.distance(startCoords, endCoords, { units: 'kilometers' });
    const tortuosity = 1.4; // Road distance factor
    const roadDistKm = distKm * tortuosity;

    const travelTimeHours = roadDistKm / speed;
    let travelTimeSec = travelTimeHours * 3600;

    // Bottlenecks
    const bottlenecks = [
        { name: 'Silk Board', coords: [77.6245, 12.9176] },
        { name: 'Hebbal', coords: [77.589, 13.033] },
        { name: 'Tin Factory', coords: [77.661, 12.996] }
    ];

    const routeLine = turf.lineString([startCoords, endCoords]);
    let delay = 0;

    bottlenecks.forEach(bn => {
        const pt = turf.point(bn.coords);
        const distToRoute = turf.pointToLineDistance(pt, routeLine, { units: 'kilometers' });

        // If route passes close to bottleneck (e.g. 1km)
        if (distToRoute < 1.0) {
            delay += 600; // 10 mins penalty
        }
    });

    return {
        time: travelTimeSec + delay,
        distance: roadDistKm,
        bottlenecksHit: delay > 0
    };
};
