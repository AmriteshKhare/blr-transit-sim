import { useMemo } from 'react';
import { MapContainer, TileLayer, CircleMarker, Popup, Polyline } from 'react-leaflet';
import L from 'leaflet';
import stationsData from '../data/stations.json';
import type { Graph } from '../utils/transitNetwork';

// Fix Leaflet marker icons
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

let DefaultIcon = L.icon({
    iconUrl: icon,
    shadowUrl: iconShadow,
    iconSize: [25, 41],
    iconAnchor: [12, 41]
});
L.Marker.prototype.options.icon = DefaultIcon;

interface MapProps {
    graph: Graph;
    pathNodes: string[]; // List of station IDs in path
    onStationSelect: (stationId: string) => void;
    selectionMode?: 'origin' | 'destination' | null; // Optional to avoid strict check if prop passed
    originId: string | null;
    destId: string | null;
}

const LINE_COLORS: any = {
    purple: '#9b59b6',
    green: '#2ecc71',
    yellow: '#f1c40f',
    blue: '#3498db',
    pink: '#e91e63',
    orange: '#e67e22',
    gray: '#95a5a6'
};

const MapComponent = ({ graph, pathNodes, onStationSelect, originId, destId }: MapProps) => {



    // Convert GeoJSON lines to Polylines for better control than <GeoJSON>
    const lines = useMemo(() => {
        const rawLines = stationsData.features.filter(f => f.geometry.type === 'LineString');
        return rawLines.map((f, idx) => {
            const desc = f.properties?.description?.toLowerCase() || '';
            let color = '#999';
            if (desc.includes('purple')) color = LINE_COLORS.purple;
            else if (desc.includes('green')) color = LINE_COLORS.green;
            else if (desc.includes('yellow')) color = LINE_COLORS.yellow;
            else if (desc.includes('pink')) color = LINE_COLORS.pink;
            else if (desc.includes('blue')) color = LINE_COLORS.blue;

            // Swap lat/lon for Leaflet [lat, lon]
            const positions = (f.geometry as any).coordinates.map((c: any) => [c[1], c[0]]);

            return <Polyline key={idx} positions={positions} pathOptions={{ color, weight: 3, opacity: 0.7 }} />
        });
    }, []);

    // Stations
    const stationMarkers = useMemo(() => {
        return Array.from(graph.nodes.values()).map(node => {
            const isOrigin = node.id === originId;
            const isDest = node.id === destId;
            const inPath = pathNodes.includes(node.id);

            let color = '#fff';
            if (isOrigin) color = '#00ff00';
            else if (isDest) color = '#ff0000';
            else if (inPath) color = '#00ffff';

            const radius = (isOrigin || isDest) ? 8 : (inPath ? 6 : 3);

            return (
                <CircleMarker
                    key={node.id}
                    center={[node.coordinates[1], node.coordinates[0]]}
                    pathOptions={{ color: color, fillColor: color, fillOpacity: 0.8 }}
                    radius={radius}
                    eventHandlers={{
                        click: () => onStationSelect(node.id)
                    }}
                >
                    <Popup>
                        <div className="text-sm font-bold">{node.name}</div>
                        <div className="text-xs">{node.lines.join(', ')}</div>
                    </Popup>
                </CircleMarker>
            );
        });
    }, [graph, pathNodes, originId, destId, onStationSelect]);

    return (
        <MapContainer
            center={[12.9716, 77.5946]}
            zoom={11}
            style={{ height: '100%', width: '100%', background: '#111' }}
        >
            <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
                url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
            />
            {lines}
            {stationMarkers}
        </MapContainer>
    );
};

export default MapComponent;
