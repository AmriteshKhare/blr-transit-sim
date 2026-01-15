//
//  PathfindingService.swift
//  BLRTransitApp
//
//  Dijkstra's algorithm implementation for metro routing
//

import Foundation

struct PathResult {
    let totalTime: Double // Seconds
    let path: [String] // Station IDs
}

class PathfindingService {
    
    // Constants (matching web app)
    private let peakHeadway: Double = 180 // 3 min
    private let transferPenalty: Double = 450 // 7.5 min
    private let initialWait: Double = 90 // 1.5 min
    
    func findPath(in graph: TransitGraph, from startId: String, to endId: String) -> PathResult? {
        var distances: [String: Double] = [:]
        var previous: [String: (id: String, line: String)] = [:]
        
        // Priority queue as sorted array (simplified)
        var queue: [(id: String, cost: Double, lastLine: String?)] = []
        
        // Initialize distances
        for stationId in graph.nodes.keys {
            distances[stationId] = .infinity
        }
        
        distances[startId] = initialWait
        queue.append((id: startId, cost: initialWait, lastLine: nil))
        
        while !queue.isEmpty {
            // Sort by cost (min-heap simulation)
            queue.sort { $0.cost < $1.cost }
            let current = queue.removeFirst()
            
            // Skip if we've found a better path
            if current.cost > distances[current.id] ?? .infinity {
                continue
            }
            
            // Found destination
            if current.id == endId {
                break
            }
            
            // Explore neighbors
            let neighbors = graph.getNeighbors(for: current.id)
            for edge in neighbors {
                var extraCost: Double = 0
                
                // Transfer penalty
                if let lastLine = current.lastLine,
                   lastLine != edge.line,
                   edge.line != "TRANSFER" {
                    extraCost += transferPenalty + peakHeadway
                }
                
                let newCost = current.cost + edge.weight + extraCost
                
                if newCost < distances[edge.to] ?? .infinity {
                    distances[edge.to] = newCost
                    previous[edge.to] = (id: current.id, line: edge.line)
                    queue.append((id: edge.to, cost: newCost, lastLine: edge.line))
                }
            }
        }
        
        // Reconstruct path
        guard let totalTime = distances[endId], totalTime != .infinity else {
            return nil
        }
        
        var path: [String] = []
        var currentId: String? = endId
        
        while let id = currentId {
            path.insert(id, at: 0)
            currentId = previous[id]?.id
        }
        
        return PathResult(totalTime: totalTime, path: path)
    }
}
