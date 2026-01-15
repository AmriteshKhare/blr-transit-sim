//
//  StationDataLoader.swift
//  BLRTransitApp
//
//  Loads and builds the transit graph from bundled JSON
//

import Foundation
import CoreLocation

class StationDataLoader {
    
    private let walkingSpeedMPS: Double = 1.0 // ~3.6 km/h
    private let transferPenaltySec: Double = 450 // 7.5 min
    private let speedNormalMPS: Double = 9.44 // 34 km/h
    private let speedAirportMPS: Double = 16.67 // 60 km/h
    private let bufferDistKm: Double = 0.1 // 100m for station-line matching
    
    func loadGraph() -> TransitGraph {
        let graph = TransitGraph()
        
        // For now, create sample stations representing key nodes
        // In production, load from bundled JSON
        let sampleStations = createSampleStations()
        
        for station in sampleStations {
            graph.addStation(station)
        }
        
        // Build edges between adjacent stations on same line
        buildEdges(for: graph, stations: sampleStations)
        
        return graph
    }
    
    private func createSampleStations() -> [Station] {
        // Sample stations representing key Namma Metro nodes
        return [
            // Purple Line
            Station(id: "0", name: "Whitefield", coordinates: CLLocationCoordinate2D(latitude: 12.9698, longitude: 77.7500), lines: ["purple"], isInterchange: false),
            Station(id: "1", name: "Mahadevapura", coordinates: CLLocationCoordinate2D(latitude: 12.9880, longitude: 77.6999), lines: ["purple"], isInterchange: false),
            Station(id: "2", name: "KR Puram", coordinates: CLLocationCoordinate2D(latitude: 13.0012, longitude: 77.6790), lines: ["purple", "blue"], isInterchange: true),
            Station(id: "3", name: "Indiranagar", coordinates: CLLocationCoordinate2D(latitude: 12.9784, longitude: 77.6408), lines: ["purple"], isInterchange: false),
            Station(id: "4", name: "MG Road", coordinates: CLLocationCoordinate2D(latitude: 12.9757, longitude: 77.6062), lines: ["purple"], isInterchange: false),
            Station(id: "5", name: "Majestic", coordinates: CLLocationCoordinate2D(latitude: 12.9767, longitude: 77.5713), lines: ["purple", "green"], isInterchange: true),
            Station(id: "6", name: "Vijayanagar", coordinates: CLLocationCoordinate2D(latitude: 12.9706, longitude: 77.5363), lines: ["purple"], isInterchange: false),
            Station(id: "7", name: "Mysore Road", coordinates: CLLocationCoordinate2D(latitude: 12.9497, longitude: 77.5174), lines: ["purple"], isInterchange: false),
            Station(id: "8", name: "Kengeri", coordinates: CLLocationCoordinate2D(latitude: 12.9136, longitude: 77.4827), lines: ["purple"], isInterchange: false),
            
            // Green Line
            Station(id: "10", name: "Nagasandra", coordinates: CLLocationCoordinate2D(latitude: 13.0449, longitude: 77.5150), lines: ["green"], isInterchange: false),
            Station(id: "11", name: "Yeshwanthpur", coordinates: CLLocationCoordinate2D(latitude: 13.0277, longitude: 77.5440), lines: ["green"], isInterchange: false),
            Station(id: "12", name: "Rajajinagar", coordinates: CLLocationCoordinate2D(latitude: 12.9917, longitude: 77.5530), lines: ["green"], isInterchange: false),
            Station(id: "13", name: "Chickpete", coordinates: CLLocationCoordinate2D(latitude: 12.9680, longitude: 77.5770), lines: ["green"], isInterchange: false),
            Station(id: "14", name: "Lalbagh", coordinates: CLLocationCoordinate2D(latitude: 12.9503, longitude: 77.5847), lines: ["green"], isInterchange: false),
            Station(id: "15", name: "Jayanagar", coordinates: CLLocationCoordinate2D(latitude: 12.9300, longitude: 77.5830), lines: ["green"], isInterchange: false),
            Station(id: "16", name: "JP Nagar", coordinates: CLLocationCoordinate2D(latitude: 12.9070, longitude: 77.5850), lines: ["green"], isInterchange: false),
            Station(id: "17", name: "Silk Institute", coordinates: CLLocationCoordinate2D(latitude: 12.8631, longitude: 77.5779), lines: ["green"], isInterchange: false),
            
            // Blue Line (Airport)
            Station(id: "20", name: "Hebbal", coordinates: CLLocationCoordinate2D(latitude: 13.0350, longitude: 77.5910), lines: ["blue"], isInterchange: false),
            Station(id: "21", name: "Yelahanka", coordinates: CLLocationCoordinate2D(latitude: 13.1007, longitude: 77.5963), lines: ["blue"], isInterchange: false),
            Station(id: "22", name: "Trumpet Junction", coordinates: CLLocationCoordinate2D(latitude: 13.1500, longitude: 77.6000), lines: ["blue"], isInterchange: false),
            Station(id: "23", name: "KIAL Terminal", coordinates: CLLocationCoordinate2D(latitude: 13.1979, longitude: 77.7063), lines: ["blue"], isInterchange: false),
        ]
    }
    
    private func buildEdges(for graph: TransitGraph, stations: [Station]) {
        // Group stations by line
        var lineStations: [String: [Station]] = [:]
        
        for station in stations {
            for line in station.lines {
                if lineStations[line] == nil {
                    lineStations[line] = []
                }
                lineStations[line]?.append(station)
            }
        }
        
        // Build edges for each line
        for (line, stations) in lineStations {
            let isAirport = line == "blue"
            let speed = isAirport ? speedAirportMPS : speedNormalMPS
            
            for i in 0..<(stations.count - 1) {
                let u = stations[i]
                let v = stations[i + 1]
                
                let distM = distance(from: u.coordinates, to: v.coordinates) * 1000
                let time = distM / speed
                
                graph.addEdge(from: u.id, to: v.id, weight: time, distance: distM, line: line)
                graph.addEdge(from: v.id, to: u.id, weight: time, distance: distM, line: line)
            }
        }
        
        // Add transfer edges for interchanges (same station, different lines)
        let interchanges = stations.filter { $0.isInterchange }
        for station in interchanges {
            // Create virtual transfer between lines at this station
            // (Handled implicitly since same station ID serves multiple lines)
        }
    }
    
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let earthRadius: Double = 6371 // km
        
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}
