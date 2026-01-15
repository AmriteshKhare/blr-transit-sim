//
//  MetroLine.swift
//  BLRTransitApp
//
//  Metro line model with color definitions
//

import UIKit

struct MetroLine: Identifiable {
    let id: String
    let name: String
    let color: UIColor
    let isAirportLine: Bool
    
    /// Speed in meters per second
    var speedMPS: Double {
        isAirportLine ? 16.67 : 9.44 // 60 km/h or 34 km/h
    }
    
    static let purple = MetroLine(id: "purple", name: "Purple Line", color: UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0), isAirportLine: false)
    static let green = MetroLine(id: "green", name: "Green Line", color: UIColor(red: 0.0, green: 0.6, blue: 0.3, alpha: 1.0), isAirportLine: false)
    static let yellow = MetroLine(id: "yellow", name: "Yellow Line", color: UIColor(red: 0.9, green: 0.8, blue: 0.0, alpha: 1.0), isAirportLine: false)
    static let pink = MetroLine(id: "pink", name: "Pink Line", color: UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0), isAirportLine: false)
    static let blue = MetroLine(id: "blue", name: "Blue Line (Airport)", color: UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0), isAirportLine: true)
    
    static let allLines: [MetroLine] = [.purple, .green, .yellow, .pink, .blue]
    
    static func line(forColor colorId: String) -> MetroLine? {
        allLines.first { $0.id == colorId.lowercased() }
    }
}
