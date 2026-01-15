//
//  MainViewController.swift
//  NammaTravels
//
//  Main container with MapKit and floating glass panels - Mobile optimized
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
        map.showsCompass = false
        map.showsScale = false
        return map
    }()
    
    private let controlPanel = ControlPanelView()
    private let resultsCard = ResultsCardView()
    
    private let speedInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "METRO: 34-60 KM/H  |  ROAD: 10-20 KM/H"
        label.font = .systemFont(ofSize: 9, weight: .bold)
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let speedInfoContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtle shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.1
        
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0) // Warm white
        
        // Add map
        view.addSubview(mapView)
        
        // Speed info
        speedInfoContainer.addSubview(speedInfoLabel)
        view.addSubview(speedInfoContainer)
        
        // Control panel (bottom sheet style for mobile)
        controlPanel.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.delegate = self
        view.addSubview(controlPanel)
        
        // Results card (slides up when results ready)
        resultsCard.translatesAutoresizingMaskIntoConstraints = false
        resultsCard.alpha = 0
        resultsCard.transform = CGAffineTransform(translationX: 0, y: 100)
        view.addSubview(resultsCard)
        
        NSLayoutConstraint.activate([
            // Map fills the view
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Speed info at top center
            speedInfoContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            speedInfoContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            speedInfoLabel.topAnchor.constraint(equalTo: speedInfoContainer.topAnchor, constant: 10),
            speedInfoLabel.bottomAnchor.constraint(equalTo: speedInfoContainer.bottomAnchor, constant: -10),
            speedInfoLabel.leadingAnchor.constraint(equalTo: speedInfoContainer.leadingAnchor, constant: 16),
            speedInfoLabel.trailingAnchor.constraint(equalTo: speedInfoContainer.trailingAnchor, constant: -16),
            
            // Control panel - full width at bottom (mobile style)
            controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            controlPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            
            // Results card - above control panel
            resultsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            resultsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            resultsCard.bottomAnchor.constraint(equalTo: controlPanel.topAnchor, constant: -12)
        ])
    }
    
    private func setupMap() {
        mapView.delegate = self
        
        // Center on Bengaluru
        let bengaluru = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
        let region = MKCoordinateRegion(center: bengaluru, latitudinalMeters: 30000, longitudinalMeters: 30000)
        mapView.setRegion(region, animated: false)
    }
    
    private func addMetroLines() {
        // Add station annotations
        for station in graph.allStations {
            let annotation = StationAnnotation(station: station)
            mapView.addAnnotation(annotation)
        }
        
        // Add polylines for metro lines
        addMetroPolylines()
    }
    
    private func addMetroPolylines() {
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
            
            // Zoom to fit route
            let rect = routeLine.boundingMapRect
            let padding = UIEdgeInsets(top: 100, left: 40, bottom: 400, right: 40)
            mapView.setVisibleMapRect(rect, edgePadding: padding, animated: true)
        }
    }
    
    private func showResults() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: []) {
            self.resultsCard.alpha = 1
            self.resultsCard.transform = .identity
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func hideResults() {
        UIView.animate(withDuration: 0.3) {
            self.resultsCard.alpha = 0
            self.resultsCard.transform = CGAffineTransform(translationX: 0, y: 100)
        }
    }
    
    // MARK: - Station Selection
    
    private func showStationPicker(for type: SelectionType) {
        let picker = StationPickerViewController(stations: graph.allStations)
        picker.selectionType = type
        picker.delegate = self
        
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        nav.navigationBar.prefersLargeTitles = false
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
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
                markerView.markerTintColor = UIColor(red: 0.58, green: 0.2, blue: 0.75, alpha: 1.0)
            } else if station.lines.contains("green") {
                markerView.markerTintColor = UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)
            } else if station.lines.contains("blue") {
                markerView.markerTintColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
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
                renderer.strokeColor = UIColor(red: 0.58, green: 0.2, blue: 0.75, alpha: 0.9)
            case "green":
                renderer.strokeColor = UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 0.9)
            case "blue":
                renderer.strokeColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.9)
            default:
                renderer.strokeColor = UIColor.gray.withAlphaComponent(0.8)
            }
            
            renderer.lineWidth = 5
            renderer.lineCap = .round
            return renderer
        }
        
        if let route = overlay as? RoutePolyline {
            let renderer = MKPolylineRenderer(polyline: route)
            renderer.strokeColor = UIColor(red: 0.98, green: 0.6, blue: 0.2, alpha: 1.0) // Orange accent
            renderer.lineWidth = 7
            renderer.lineCap = .round
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let stationAnnotation = view.annotation as? StationAnnotation else { return }
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
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
        station.lines.map { $0.capitalized }.joined(separator: " • ")
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
