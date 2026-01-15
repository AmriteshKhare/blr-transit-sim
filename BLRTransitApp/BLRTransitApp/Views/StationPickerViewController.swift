//
//  StationPickerViewController.swift
//  BLRTransitApp
//
//  Station search and selection with glass styling
//

import UIKit

protocol StationPickerDelegate: AnyObject {
    func stationPicker(_ picker: StationPickerViewController, didSelect station: Station, for type: SelectionType)
}

class StationPickerViewController: UIViewController {
    
    weak var delegate: StationPickerDelegate?
    var selectionType: SelectionType = .origin
    
    private let allStations: [Station]
    private var filteredStations: [Station] = []
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        return table
    }()
    
    // MARK: - Init
    
    init(stations: [Station]) {
        self.allStations = stations
        self.filteredStations = stations
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        title = selectionType == .origin ? "Select Origin" : "Select Destination"
        navigationItem.largeTitleDisplayMode = .never
        
        // Search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search stations..."
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // Cancel button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StationCell.self, forCellReuseIdentifier: "StationCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    private func filterStations(with query: String) {
        if query.isEmpty {
            filteredStations = allStations
        } else {
            filteredStations = allStations.filter { station in
                station.name.localizedCaseInsensitiveContains(query) ||
                station.lines.joined(separator: " ").localizedCaseInsensitiveContains(query)
            }
        }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension StationPickerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredStations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as! StationCell
        let station = filteredStations[indexPath.row]
        cell.configure(with: station)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension StationPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let station = filteredStations[indexPath.row]
        delegate?.stationPicker(self, didSelect: station, for: selectionType)
    }
}

// MARK: - UISearchResultsUpdating

extension StationPickerViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterStations(with: searchController.searchBar.text ?? "")
    }
}

// MARK: - Station Cell

class StationCell: UITableViewCell {
    
    private let iconView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let linesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let interchangeBadge: UILabel = {
        let label = UILabel()
        label.text = "⇄"
        label.font = .systemFont(ofSize: 14)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(linesLabel)
        contentView.addSubview(interchangeBadge)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 12),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            linesLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            linesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            linesLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            interchangeBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            interchangeBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with station: Station) {
        nameLabel.text = station.name
        linesLabel.text = station.lines.map { $0.uppercased() }.joined(separator: " • ")
        interchangeBadge.isHidden = !station.isInterchange
        
        // Line color
        if station.lines.contains("purple") {
            iconView.backgroundColor = .purple
        } else if station.lines.contains("green") {
            iconView.backgroundColor = .systemGreen
        } else if station.lines.contains("blue") {
            iconView.backgroundColor = .systemBlue
        } else {
            iconView.backgroundColor = .gray
        }
    }
}
