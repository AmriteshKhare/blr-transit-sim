# BLR Transit Engine

A high-fidelity transit simulation engine for Bengaluru, comparing **Namma Metro** travel times against realistic road traffic scenarios to demonstrate rail network efficiency ("Delhi-NCR Parity" Model).

## Features

*   **Interactive Map**: Visualizes Metro lines (including Phase 2/2B) and road bottlenecks.
*   **Pathfinding Engine**: 
    *   **Metro**: Custom Dijkstra algorithm with interchange penalties (Majestic, etc.) and peak headway delays.
    *   **Road**: Turf.js spatial analysis with real-time congestion zones (Silk Board, Hebbal).
*   **Search**: Searchable autocomplete for 60+ metro stations.
*   **Comparison Dashboard**: Real-time "Time Saved" metrics and efficiency gains.
*   **Editorial Design**: Premium, "Warm Stone" aesthetic with high-contrast data visualization.

## Methodology
See [METHODOLOGY.md](./METHODOLOGY.md) for detailed algorithms, speed assumptions, and data sources.

## Data Sources
*   **Metro Data**: OpenStreetMap & BMRCL (Phase 1, 2, 2A, 2B alignments).
*   **Traffic Models**: TomTom Traffic Index citations for peak/off-peak speeds.

## Development

### Prerequisites
*   Node.js (v18+)
*   npm

### Setup
```bash
git clone https://github.com/your-username/blr-transit-sim.git
cd blr-transit-sim
npm install
```

### Run Locally
```bash
npm run dev
```

## Deployment

### Deploy to Vercel
Click the button below to deploy your own instance of the BLR Transit Engine to Vercel.

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2FAmriteshKhare%2Fblr-transit-sim)

### Manual Deployment
1.  Build the project:
    ```bash
    npm run build
    ```
2.  Deploy the `dist` folder to any static host (Vercel, Netlify, GitHub Pages).

---
*Built with React, TypeScript, Leaflet, and Turf.js*
