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

    <div className="flex h-screen bg-black text-white overflow-hidden font-sans selection:bg-white selection:text-black">
      {/* Sidebar */}
      <div className="w-[400px] flex-shrink-0 flex flex-col border-r border-white/10 bg-black p-8 z-20 shadow-2xl relative">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-emerald-500 via-blue-500 to-purple-500 opacity-50"></div>

        <div className="mb-12">
          <h1 className="text-sm font-medium tracking-[0.2em] uppercase text-white mb-2">
            BLR Transit Engine
          </h1>
          <p className="text-neutral-500 text-xs tracking-wide">Delhi-NCR Parity Model / v1.0</p>
        </div>

        {/* Controls */}
        <div className="space-y-10">
          <div className="space-y-3">
            <label className="text-[10px] font-bold text-neutral-500 uppercase tracking-widest">Temporal Mode</label>
            <div className="flex border border-white/10 rounded-sm p-1 gap-1">
              <button
                onClick={() => setTimeOfDay('morning')}
                className={clsx("flex-1 py-2 text-xs font-medium tracking-wide transition-all rounded-sm", timeOfDay === 'morning' ? "bg-white text-black shadow-sm" : "text-neutral-500 hover:text-neutral-300")}
              >
                MORNING (08-11)
              </button>
              <button
                onClick={() => setTimeOfDay('evening')}
                className={clsx("flex-1 py-2 text-xs font-medium tracking-wide transition-all rounded-sm", timeOfDay === 'evening' ? "bg-white text-black shadow-sm" : "text-neutral-500 hover:text-neutral-300")}
              >
                EVENING (15-19)
              </button>
            </div>
          </div>

          <div className="space-y-3">
            <label className="text-[10px] font-bold text-neutral-500 uppercase tracking-widest">Road Mode</label>
            <div className="flex gap-2">
              <button
                onClick={() => setRoadMode('car')}
                className={clsx("flex-1 py-3 px-4 border text-xs font-medium tracking-wide transition-all flex items-center justify-center gap-2 rounded-sm", roadMode === 'car' ? "border-white bg-white/5 text-white" : "border-white/10 text-neutral-500 hover:border-white/20")}
              >
                <Car size={14} /> CAR
              </button>
              <button
                onClick={() => setRoadMode('bike')}
                className={clsx("flex-1 py-3 px-4 border text-xs font-medium tracking-wide transition-all flex items-center justify-center gap-2 rounded-sm", roadMode === 'bike' ? "border-white bg-white/5 text-white" : "border-white/10 text-neutral-500 hover:border-white/20")}
              >
                <Bike size={14} /> BIKE
              </button>
            </div>
          </div>


          <div className="space-y-4">
            <label className="text-[10px] font-bold text-neutral-500 uppercase tracking-widest">Journey Constraints</label>

            <div className="space-y-3">
              <SearchableSelect
                placeholder="ORIGIN STATION"
                options={stationOptions}
                value={origin}
                onChange={(val) => {
                  setOrigin(val);
                  if (val) setSelectionMode('destination');
                }}
                icon={<div className="w-1.5 h-1.5 rounded-full bg-emerald-500"></div>}
                activeColor="border-emerald-500/50"
              />

              <div className="mx-4 border-l border-white/10 h-2"></div>

              <SearchableSelect
                placeholder="DESTINATION STATION"
                options={stationOptions}
                value={dest}
                onChange={(val) => {
                  setDest(val);
                  if (val) setSelectionMode('origin');
                }}
                icon={<div className="w-1.5 h-1.5 rounded-full bg-rose-500"></div>}
                activeColor="border-rose-500/50"
              />
            </div>
          </div>

        </div>

        {/* Results / Data Visualization */}
        {metroResult && roadResult ? (
          <div className="mt-8 pt-8 border-t border-white/10 animate-in fade-in duration-700">

            {/* Time Saved Hero */}
            <div className="mb-8">
              <div className="text-neutral-500 text-[10px] uppercase tracking-widest mb-1">Efficiency Gain</div>
              <div className="flex items-baseline gap-2">
                <span className="text-5xl font-light tracking-tighter text-emerald-400 tabular-nums">
                  {formatTime(Math.max(0, roadResult.time - metroResult.time)).replace(' min', '')}
                </span>
                <span className="text-sm font-medium text-emerald-500/80">MIN SAVED</span>
              </div>
            </div>

            {/* Comparison Table */}
            <div className="space-y-4">
              {/* Metro Row */}
              <div className="group">
                <div className="flex justify-between items-center mb-1">
                  <span className="text-sm text-white/70 group-hover:text-white transition-colors flex items-center gap-2">
                    <Train size={14} className="text-neutral-500" /> Namma Metro
                  </span>
                  <span className="text-lg font-light tabular-nums text-white">{formatTime(metroResult.time)}</span>
                </div>
                <div className="h-0.5 w-full bg-white/10">
                  <div className="h-full bg-white" style={{ width: '100%' }}></div>
                </div>
              </div>

              {/* Road Row */}
              <div className="group">
                <div className="flex justify-between items-center mb-1">
                  <span className="text-sm text-neutral-500 group-hover:text-neutral-300 transition-colors flex items-center gap-2">
                    {roadMode === 'car' ? <Car size={14} /> : <Bike size={14} />} Road Traffic
                  </span>
                  <span className="text-lg font-light tabular-nums text-neutral-400">{formatTime(roadResult.time)}</span>
                </div>
                <div className="h-0.5 w-full bg-white/5">
                  <div className="h-full bg-rose-500/50" style={{ width: `${Math.min(100, (roadResult.time / metroResult.time) * 100)}%` }}></div>
                </div>
                {roadResult.bottlenecks && (
                  <div className="mt-2 text-[10px] text-rose-400/80 flex items-center gap-1.5 tracking-wide">
                    <AlertTriangle size={10} /> HEAVY CONGESTION DETECTED
                  </div>
                )}
              </div>
            </div>

          </div>
        ) : (
          <div className="mt-auto pt-8 border-t border-white/5 flex flex-col items-center justify-center text-center opacity-30 min-h-[200px]">
            <div className="w-12 h-12 rounded-full border border-white/20 flex items-center justify-center mb-4">
              <MapPin size={20} />
            </div>
            <p className="text-xs uppercase tracking-widest max-w-[150px]">Select endpoints on the map to begin analysis</p>
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
        <div className="absolute top-4 right-4 bg-black/80 backdrop-blur-md border border-white/10 px-3 py-2 rounded-sm text-[10px] font-medium tracking-wide text-white/60 pointer-events-none z-[1000] uppercase">
          METRO: 34-60 KM/H &nbsp;|&nbsp; ROAD: 10-20 KM/H
        </div>
      </div>
    </div>
  );
}

export default App;
