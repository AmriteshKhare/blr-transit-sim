//
//  MainViewController.swift
//  BLRTransitApp
//
//  Main container with MapKit and floating glass panels
//

import UIKit
import MapKit

class MainViewController: UIViewController {
    
    // MARK: - Properties
    
    private let graph: TransitGraph
    private let pathfindingService = PathfindingService()
    private let roadCalculator = RoadTimeCalculator()
    
    private var originStation: Station?
    private var destinationStation: Station?
    private var timeOfDayIsMorning = true
    private var roadMode: RoadMode = .car
    
    // MARK: - UI Components
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = false
        map.mapType = .standard
        map.overrideUserInterfaceStyle = .light
        return map
    }()
    
    private let controlPanel = ControlPanelView()
    private let resultsCard = ResultsCardView()
    
    private let speedInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "METRO: 34-60 KM/H  |  ROAD: 10-20 KM/H"
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let speedInfoContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    
    init() {
        let loader = StationDataLoader()
        self.graph = loader.loadGraph()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let loader = StationDataLoader()
        self.graph = loader.loadGraph()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMap()
        addMetroLines()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.99, green: 0.98, blue: 0.97, alpha: 1.0) // Warm cream
        
        // Add map
        view.addSubview(mapView)
        
        // Speed info with glass background
        speedInfoContainer.applyGlassEffect(style: .systemUltraThinMaterial, cornerRadius: 8)
        speedInfoContainer.addSubview(speedInfoLabel)
        view.addSubview(speedInfoContainer)
        
        // Control panel
        controlPanel.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.delegate = self
        view.addSubview(controlPanel)
        
        // Results card (initially hidden)
        resultsCard.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.alpha = 0
        view.addSubview(resultsCard)
        
        NSLayoutConstraint.activate([
            // Map fills the view
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Speed info at top
            speedInfoContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            speedInfoContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            speedInfoLabel.topAnchor.constraint(equalTo: speedInfoContainer.topAnchor, constant: 8),
            speedInfoLabel.bottomAnchor.constraint(equalTo: speedInfoContainer.bottomAnchor, constant: -8),
            speedInfoLabel.leadingAnchor.constraint(equalTo: speedInfoContainer.leadingAnchor, constant: 16),
            speedInfoLabel.trailingAnchor.constraint(equalTo: speedInfoContainer.trailingAnchor, constant: -16),
            
            // Control panel at bottom left
            controlPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            controlPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            controlPanel.widthAnchor.constraint(equalToConstant: 280),
            
            // Results card at bottom right
            resultsCard.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            resultsCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            resultsCard.widthAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    private func setupMap() {
        mapView.delegate = self
        
        // Center on Bengaluru
        let bengaluru = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
        let region = MKCoordinateRegion(center: bengaluru, latitudinalMeters: 25000, longitudinalMeters: 25000)
        mapView.setRegion(region, animated: false)
    }
    
    private func addMetroLines() {
        // Add station annotations
        for station in graph.allStations {
            let annotation = StationAnnotation(station: station)
            mapView.addAnnotation(annotation)
        }
        
        // Add polylines for metro lines (simplified)
        addMetroPolylines()
    }
    
    private func addMetroPolylines() {
        // Group stations by line and draw polylines
        let lines = ["purple", "green", "blue"]
        
        for line in lines {
            let lineStations = graph.allStations.filter { $0.lines.contains(line) }
            guard lineStations.count > 1 else { continue }
            
            let coordinates = lineStations.map { $0.coordinates }
            let polyline = MetroPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.lineColor = line
            
            mapView.addOverlay(polyline)
        }
    }
    
    // MARK: - Route Calculation
    
    private func calculateRoutes() {
        guard let origin = originStation, let destination = destinationStation else {
            hideResults()
            return
        }
        
        // Metro path
        guard let metroResult = pathfindingService.findPath(in: graph, from: origin.id, to: destination.id) else {
            hideResults()
            return
        }
        
        // Road time
        let roadResult = roadCalculator.calculate(
            from: origin.coordinates,
            to: destination.coordinates,
            mode: roadMode,
            isPeakMorning: timeOfDayIsMorning
        )
        
        // Update UI
        resultsCard.update(
            metroTime: metroResult.totalTime,
            roadTime: roadResult.time,
            roadMode: roadMode,
            hasBottlenecks: roadResult.bottlenecksHit
        )
        
        showResults()
        
        // Draw route on map
        highlightPath(metroResult.path)
    }
    
    private func highlightPath(_ stationIds: [String]) {
        // Remove existing route overlays
        let existingRoutes = mapView.overlays.filter { $0 is RoutePolyline }
        mapView.removeOverlays(existingRoutes)
        
        // Add new route
        var coordinates: [CLLocationCoordinate2D] = []
        for id in stationIds {
            if let station = graph.getStation(by: id) {
                coordinates.append(station.coordinates)
            }
        }
        
        if coordinates.count > 1 {
            let routeLine = RoutePolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(routeLine, level: .aboveLabels)
        }
    }
    
    private func showResults() {
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.resultsCard.alpha = 1
            self.resultsCard.transform = .identity
        }
    }
    
    private func hideResults() {
        UIView.animate(withDuration: 0.3) {
            self.resultsCard.alpha = 0
            self.resultsCard.transform = CGAffineTransform(translationX: 0, y: 20)
        }
    }
    
    // MARK: - Station Selection
    
    private func showStationPicker(for type: SelectionType) {
        let picker = StationPickerViewController(stations: graph.allStations)
        picker.selectionType = type
        picker.delegate = self
        
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(nav, animated: true)
    }
}

// MARK: - ControlPanelDelegate

extension MainViewController: ControlPanelDelegate {
    
    func controlPanel(_ panel: ControlPanelView, didSelectOrigin station: Station?) {
        showStationPicker(for: .origin)
    }
    
    func controlPanel(_ panel: ControlPanelView, didSelectDestination station: Station?) {
        showStationPicker(for: .destination)
    }
    
    func controlPanel(_ panel: ControlPanelView, didChangeTimeOfDay isMorning: Bool) {
        timeOfDayIsMorning = isMorning
        calculateRoutes()
    }
    
    func controlPanel(_ panel: ControlPanelView, didChangeRoadMode mode: RoadMode) {
        roadMode = mode
        calculateRoutes()
    }
}

// MARK: - StationPickerDelegate

extension MainViewController: StationPickerDelegate {
    
    func stationPicker(_ picker: StationPickerViewController, didSelect station: Station, for type: SelectionType) {
        switch type {
        case .origin:
            originStation = station
            controlPanel.setOrigin(station)
        case .destination:
            destinationStation = station
            controlPanel.setDestination(station)
        }
        
        calculateRoutes()
        picker.dismiss(animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension MainViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let stationAnnotation = annotation as? StationAnnotation else { return nil }
        
        let identifier = "StationPin"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if view == nil {
            view = MKMarkerAnnotationView(annotation: stationAnnotation, reuseIdentifier: identifier)
            view?.canShowCallout = true
        }
        
        if let markerView = view as? MKMarkerAnnotationView {
            let station = stationAnnotation.station
            
            // Color based on line
            if station.lines.contains("purple") {
                markerView.markerTintColor = .purple
            } else if station.lines.contains("green") {
                markerView.markerTintColor = .systemGreen
            } else if station.lines.contains("blue") {
                markerView.markerTintColor = .systemBlue
            } else {
                markerView.markerTintColor = .gray
            }
            
            // Highlight interchanges
            if station.isInterchange {
                markerView.glyphImage = UIImage(systemName: "arrow.triangle.2.circlepath")
            } else {
                markerView.glyphImage = UIImage(systemName: "tram.fill")
            }
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MetroPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            
            switch polyline.lineColor {
            case "purple":
                renderer.strokeColor = UIColor.purple.withAlphaComponent(0.8)
            case "green":
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.8)
            case "blue":
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8)
            default:
                renderer.strokeColor = UIColor.gray.withAlphaComponent(0.8)
            }
            
            renderer.lineWidth = 4
            return renderer
        }
        
        if let route = overlay as? RoutePolyline {
            let renderer = MKPolylineRenderer(polyline: route)
            renderer.strokeColor = UIColor.systemOrange
            renderer.lineWidth = 6
            renderer.lineCap = .round
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let stationAnnotation = view.annotation as? StationAnnotation else { return }
        
        // Quick tap to set origin/destination
        if originStation == nil {
            originStation = stationAnnotation.station
            controlPanel.setOrigin(stationAnnotation.station)
        } else if destinationStation == nil {
            destinationStation = stationAnnotation.station
            controlPanel.setDestination(stationAnnotation.station)
            calculateRoutes()
        }
        
        mapView.deselectAnnotation(view.annotation, animated: true)
    }
}

// MARK: - Supporting Types

class StationAnnotation: NSObject, MKAnnotation {
    let station: Station
    
    var coordinate: CLLocationCoordinate2D {
        station.coordinates
    }
    
    var title: String? {
        station.name
    }
    
    var subtitle: String? {
        station.lines.joined(separator: ", ").uppercased()
    }
    
    init(station: Station) {
        self.station = station
    }
}

class MetroPolyline: MKPolyline {
    var lineColor: String = "gray"
}

class RoutePolyline: MKPolyline {}

enum SelectionType {
    case origin
    case destination
}
