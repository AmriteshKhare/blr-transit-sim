import { useState, useEffect, useMemo } from 'react';

import MapComponent from './components/MapComponent';
import { SearchableSelect } from './components/SearchableSelect';
import { buildGraph } from './utils/transitNetwork';
import type { Graph } from './utils/transitNetwork';

import { findMetroPath, calculateRoadTime } from './utils/pathfinding';
import { Car, Bike, Train, MapPin, AlertTriangle } from 'lucide-react';

import clsx from 'clsx';

function App() {
  const [graph, setGraph] = useState<Graph | null>(null);
  const [origin, setOrigin] = useState<string | null>(null);
  const [dest, setDest] = useState<string | null>(null);
  const [selectionMode, setSelectionMode] = useState<'origin' | 'destination'>('origin');

  const [timeOfDay, setTimeOfDay] = useState<'morning' | 'evening'>('morning');
  const [roadMode, setRoadMode] = useState<'car' | 'bike'>('car');

  const [metroResult, setMetroResult] = useState<{ time: number, path: string[] } | null>(null);
  const [roadResult, setRoadResult] = useState<{ time: number, distance: number, bottlenecks: boolean } | null>(null);

  useEffect(() => {
    const g = buildGraph();
    setGraph(g);
  }, []);

  useEffect(() => {
    if (graph && origin && dest) {
      // Calculate Metro Path
      const mPath = findMetroPath(graph, origin, dest);
      if (mPath) {
        setMetroResult({ time: mPath.totalTime || 0, path: mPath.path });

      } else {
        setMetroResult(null);
      }

      // Calculate Road Path
      const startNode = graph.nodes.get(origin);
      const endNode = graph.nodes.get(dest);
      if (startNode && endNode) {
        const rRes = calculateRoadTime(
          [startNode.coordinates[0], startNode.coordinates[1]], // Turf expects [lon, lat]
          [endNode.coordinates[0], endNode.coordinates[1]],   // graph nodes store [lon, lat]
          roadMode,
          timeOfDay === 'morning'
        );
        setRoadResult({
          time: rRes.time,
          distance: rRes.distance,
          bottlenecks: rRes.bottlenecksHit
        });
      }
    } else {
      setMetroResult(null);
      setRoadResult(null);
    }
  }, [graph, origin, dest, timeOfDay, roadMode]);

  const handleStationSelect = (id: string) => {
    if (selectionMode === 'origin') {
      setOrigin(id);
      setSelectionMode('destination');
    } else {
      setDest(id);
      setSelectionMode('origin'); // or null?
    }
  };

  const formatTime = (seconds: number) => {
    const min = Math.floor(seconds / 60);
    return `${min} min`;
  };

  const stationOptions = useMemo(() => {
    if (!graph) return [];
    return Array.from(graph.nodes.values()).map(n => ({
      id: n.id,
      label: n.name,
      subLabel: n.lines.join(', ') // Add line info as subtext
    })).sort((a, b) => a.label.localeCompare(b.label));
  }, [graph]);

  return (

    <div className="flex h-screen bg-gray-900 text-white overflow-hidden">
      {/* Sidebar */}
      <div className="w-96 flex-shrink-0 flex flex-col border-r border-gray-800 bg-gray-950 p-6 z-10 shadow-xl">
        <h1 className="text-2xl font-bold mb-2 bg-gradient-to-r from-purple-400 to-pink-500 bg-clip-text text-transparent">
          BLR Transit Engine
        </h1>
        <p className="text-gray-400 text-sm mb-6">Delhi-NCR Parity Model Simulation</p>

        {/* Controls */}
        <div className="space-y-6">
          <div className="space-y-2">
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Peak Hour</label>
            <div className="flex bg-gray-900 rounded p-1">
              <button
                onClick={() => setTimeOfDay('morning')}
                className={clsx("flex-1 py-2 text-sm rounded transition-colors", timeOfDay === 'morning' ? "bg-blue-600 text-white" : "text-gray-400 hover:text-white")}
              >
                Morning (08-11)
              </button>
              <button
                onClick={() => setTimeOfDay('evening')}
                className={clsx("flex-1 py-2 text-sm rounded transition-colors", timeOfDay === 'evening' ? "bg-orange-600 text-white" : "text-gray-400 hover:text-white")}
              >
                Evening (15-19)
              </button>
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Road Mode</label>
            <div className="flex bg-gray-900 rounded p-1">
              <button
                onClick={() => setRoadMode('car')}
                className={clsx("flex-1 py-2 text-sm rounded flex items-center justify-center gap-2 transition-colors", roadMode === 'car' ? "bg-indigo-600 text-white" : "text-gray-400 hover:text-white")}
              >
                <Car size={16} /> Car
              </button>
              <button
                onClick={() => setRoadMode('bike')}
                className={clsx("flex-1 py-2 text-sm rounded flex items-center justify-center gap-2 transition-colors", roadMode === 'bike' ? "bg-green-600 text-white" : "text-gray-400 hover:text-white")}
              >
                <Bike size={16} /> Bike
              </button>
            </div>
          </div>

          <div className="space-y-4">
            <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Route</label>

            <SearchableSelect
              placeholder="Select Origin"
              options={stationOptions}
              value={origin}
              onChange={(val) => {
                setOrigin(val);
                if (val) setSelectionMode('destination');
              }}
              icon={<MapPin size={16} className={origin ? "text-green-500" : "text-gray-600"} />}
              activeColor="border-green-500"
            />

            <SearchableSelect
              placeholder="Select Destination"
              options={stationOptions}
              value={dest}
              onChange={(val) => {
                setDest(val);
                if (val) setSelectionMode('origin');
              }}
              icon={<MapPin size={16} className={dest ? "text-red-500" : "text-gray-600"} />}
              activeColor="border-red-500"
            />
          </div>

        </div>

        <div className="my-6 border-t border-gray-800" />

        {/* Results */}
        {metroResult && roadResult ? (
          <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="bg-gray-800/50 p-4 rounded-lg border border-gray-700">
              <div className="flex justify-between items-center mb-2">
                <span className="text-gray-400 flex items-center gap-2"><Train size={16} /> Namma Metro</span>
                <span className="text-2xl font-bold text-green-400">{formatTime(metroResult.time)}</span>
              </div>
              <div className="h-1 bg-gray-700 rounded-full overflow-hidden">
                <div className="h-full bg-green-500" style={{ width: '100%' }}></div>
              </div>
            </div>

            <div className="bg-gray-800/50 p-4 rounded-lg border border-gray-700">
              <div className="flex justify-between items-center mb-2">
                <span className="text-gray-400 flex items-center gap-2">
                  {roadMode === 'car' ? <Car size={16} /> : <Bike size={16} />} Road ({timeOfDay})
                </span>
                <span className="text-2xl font-bold text-red-400">{formatTime(roadResult.time)}</span>
              </div>
              <div className="h-1 bg-gray-700 rounded-full overflow-hidden">
                {/* Scale bar relative to metro? Just full for visual */}
                <div className="h-full bg-red-500" style={{ width: `${Math.min(100, (roadResult.time / metroResult.time) * 100)}%` }}></div>
              </div>
              {roadResult.bottlenecks && (
                <div className="mt-2 text-xs text-orange-400 flex items-center gap-1">
                  <AlertTriangle size={12} /> High Congestion Zones Detected
                </div>
              )}
            </div>

            <div className="text-center pt-4">
              <div className="text-gray-400 text-xs uppercase tracking-wide">Time Saved</div>
              <div className="text-4xl font-black text-transparent bg-clip-text bg-gradient-to-tr from-green-400 to-emerald-600">
                {formatTime(Math.max(0, roadResult.time - metroResult.time))}
              </div>
            </div>
          </div>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-700">
            Select Origin & Destination on Map
          </div>
        )}
      </div>

      {/* Map */}
      <div className="flex-1 h-full relative">
        {graph && (
          <MapComponent
            graph={graph}
            pathNodes={metroResult?.path || []}
            onStationSelect={handleStationSelect}
            selectionMode={selectionMode}
            originId={origin}
            destId={dest}
          />
        )}
        <div className="absolute bottom-4 right-4 bg-black/80 backdrop-blur p-2 rounded text-xs text-gray-400 pointer-events-none z-[1000]">
          Metro: 34-60 km/h | Road: 10-20 km/h
        </div>
      </div>
    </div>
  );
}

export default App;
