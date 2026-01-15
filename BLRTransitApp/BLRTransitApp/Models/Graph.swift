//
//  Graph.swift
//  BLRTransitApp
//
//  Graph structure for metro network with adjacency list
//

import Foundation

struct Edge {
    let from: String
    let to: String
    let weight: Double // Time in seconds
    let distance: Double // Meters
    let line: String
}

class TransitGraph {
    var nodes: [String: Station] = [:]
    var edges: [String: [Edge]] = [:]
    
    func addStation(_ station: Station) {
        nodes[station.id] = station
    }
    
    func addEdge(from: String, to: String, weight: Double, distance: Double, line: String) {
        let edge = Edge(from: from, to: to, weight: weight, distance: distance, line: line)
        if edges[from] == nil {
            edges[from] = []
        }
        edges[from]?.append(edge)
    }
    
    func getNeighbors(for stationId: String) -> [Edge] {
        return edges[stationId] ?? []
    }
    
    func getStation(by id: String) -> Station? {
        return nodes[id]
    }
    
    var allStations: [Station] {
        Array(nodes.values).sorted { $0.name < $1.name }
    }
}
