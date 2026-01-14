# Transit Simulation Engine: Methodology & System Design

## 1. Overview
The **BLR Transit Engine** compares travel times between the **Namma Metro** network and realistic road traffic scenarios in Bengaluru. The goal is to demonstrate the efficiency of the metro system against the city's notorious traffic congestion to reasonable accuracy ("Delhi-NCR Parity" benchmark).

## 2. Methodology

### 2.1 Metro Travel Time Calculation
Metro travel is modeled as a graph traversal problem using **Dijkstra's Algorithm**.

*   **Graph Structure**:
    *   **Nodes**: Metro stations and key interchanges.
    *   **Edges**: Segments connecting adjacent stations.
    *   **Weights**: Travel time in seconds.

*   **Speed Assumptions**:
    *   **Normal Lines** (Purple, Green, Yellow, etc.): `34 km/h` (Average operational speed including dwell times).
    *   **Airport Line** (Blue - Phase 2B): `60 km/h` (Higher speed design).

*   **Penalties & Delays**:
    *   **Initial Wait Time**: `1.5 minutes` (Assumed average arrival mid-headway).
    *   **Interchange Penalty**: `7.5 minutes` (Fixed penalty for walking between platforms at major interchanges like Majestic).
    *   **Peak Headway Penalty**: `3 minutes` additional wait time added when switching lines during transfers.

*   **Total Time Formula**:
    $$ T_{metro} = T_{travel} + T_{initial\_wait} + \sum (T_{transfer\_walk} + T_{headway}) $$

### 2.2 Road Travel Time Calculation
Road travel is modeled using geospatial distance with congestion factors types.

*   **Distance**: Calculated using `Turf.js` (Haversine formula) between origin and destination coordinates.
*   **Tortuosity Factor**: `1.4x` multiplier applied to the straight-line distance to account for road network winding.
*   **Speeds** (Derived from avg. Bengaluru traffic data):
    *   **Car (Peak)**: `12 km/h`
    *   **Car (Off-Peak)**: `10 km/h` (Severe congestion assumption for specific zones)
    *   **Bike (Peak)**: `20 km/h`
    *   **Bike (Off-Peak)**: `18 km/h`

*   **Bottleneck Detection**:
    The engine checks if the straight-line path intersects within `1km` of known congestion zones:
    *   Silk Board
    *   Hebbal
    *   Tin Factory
    
    **Penalty**: `+10 minutes` added to road travel time for each bottleneck encountered.

## 3. Data Sources

### 3.1 Geospatial Data
*   **Stations & Lines**: Sourced from generic BMRCL / OpenStreetMap GeoJSON data.
*   **Coordinates**: Standard WGS84 (Lat/Lon).

### 3.2 References
*   **Namma Metro Operational Data**: Speeds approximated from BMRCL public disclosures (avg ~32-35 km/h).
*   **Traffic Speeds**: Based on TomTom Traffic Index and local reports citing average peak speeds of ~18 km/h in Outer Ring Road areas.

## 4. Tech Stack
*   **Frontend**: React + Vite (TypeScript)
*   **Visualization**: Leaflet (React-Leaflet) + CartoDB Positron Tiles (Light Theme)
*   **Spatial Analysis**: Turf.js
*   **Pathfinding**: Custom Dijkstra Implementation
