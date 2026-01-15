//
//  Station.swift
//  BLRTransitApp
//
//  Metro station model
//

import Foundation
import CoreLocation

struct Station: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let coordinates: CLLocationCoordinate2D
    let lines: [String]
    let isInterchange: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, coordinates, lines, isInterchange
    }
    
    init(id: String, name: String, coordinates: CLLocationCoordinate2D, lines: [String], isInterchange: Bool) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.lines = lines
        self.isInterchange = isInterchange
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        lines = try container.decode([String].self, forKey: .lines)
        isInterchange = try container.decode(Bool.self, forKey: .isInterchange)
        
        let coords = try container.decode([Double].self, forKey: .coordinates)
        coordinates = CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode([coordinates.longitude, coordinates.latitude], forKey: .coordinates)
        try container.encode(lines, forKey: .lines)
        try container.encode(isInterchange, forKey: .isInterchange)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Station, rhs: Station) -> Bool {
        lhs.id == rhs.id
    }
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
