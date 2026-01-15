//
//  RoadTimeCalculator.swift
//  BLRTransitApp
//
//  Road travel time calculator with bottleneck detection
//

import Foundation
import CoreLocation

struct RoadResult {
    let time: Double // Seconds
    let distance: Double // Kilometers
    let bottlenecksHit: Bool
}

enum RoadMode {
    case car
    case bike
}

class RoadTimeCalculator {
    
    // Bottleneck locations
    private let bottlenecks: [(name: String, coordinate: CLLocationCoordinate2D)] = [
        ("Silk Board", CLLocationCoordinate2D(latitude: 12.9176, longitude: 77.6245)),
        ("Hebbal", CLLocationCoordinate2D(latitude: 13.033, longitude: 77.589)),
        ("Tin Factory", CLLocationCoordinate2D(latitude: 12.996, longitude: 77.661))
    ]
    
    private let tortuosity: Double = 1.4 // Road winding factor
    private let bottleneckRadius: Double = 1.0 // km
    private let bottleneckDelay: Double = 600 // 10 minutes in seconds
    
    func calculate(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        mode: RoadMode,
        isPeakMorning: Bool
    ) -> RoadResult {
        
        // Speed in km/h based on mode and time
        let speed: Double
        switch mode {
        case .car:
            speed = isPeakMorning ? 12 : 10
        case .bike:
            speed = isPeakMorning ? 20 : 18
        }
        
        // Calculate distance using Haversine formula
        let distanceKm = haversineDistance(from: start, to: end)
        let roadDistanceKm = distanceKm * tortuosity
        
        // Travel time
        let travelTimeHours = roadDistanceKm / speed
        var travelTimeSec = travelTimeHours * 3600
        
        // Check for bottlenecks
        var delay: Double = 0
        var hitBottleneck = false
        
        for bottleneck in bottlenecks {
            let distToRoute = pointToLineDistance(
                point: bottleneck.coordinate,
                lineStart: start,
                lineEnd: end
            )
            
            if distToRoute < bottleneckRadius {
                delay += bottleneckDelay
                hitBottleneck = true
            }
        }
        
        return RoadResult(
            time: travelTimeSec + delay,
            distance: roadDistanceKm,
            bottlenecksHit: hitBottleneck
        )
    }
    
    // MARK: - Haversine Distance
    
    private func haversineDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
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
    
    // MARK: - Point to Line Distance
    
    private func pointToLineDistance(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> Double {
        // Simplified: distance from point to midpoint of line
        let midLat = (lineStart.latitude + lineEnd.latitude) / 2
        let midLon = (lineStart.longitude + lineEnd.longitude) / 2
        let midpoint = CLLocationCoordinate2D(latitude: midLat, longitude: midLon)
        
        return haversineDistance(from: point, to: midpoint)
    }
}
