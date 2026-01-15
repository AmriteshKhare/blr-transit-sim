//
//  ControlPanelView.swift
//  BLRTransitApp
//
//  Floating glass control panel with mode selectors
//

import UIKit

protocol ControlPanelDelegate: AnyObject {
    func controlPanel(_ panel: ControlPanelView, didSelectOrigin station: Station?)
    func controlPanel(_ panel: ControlPanelView, didSelectDestination station: Station?)
    func controlPanel(_ panel: ControlPanelView, didChangeTimeOfDay: Bool) // true = morning
    func controlPanel(_ panel: ControlPanelView, didChangeRoadMode: RoadMode)
}

class ControlPanelView: UIView {
    
    weak var delegate: ControlPanelDelegate?
    
    // MARK: - UI Components
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "BLR TRANSIT ENGINE"
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Delhi-NCR Parity Model / v1.0"
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeSegmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["MORNING", "EVENING"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let modeSegmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["🚗 CAR", "🏍️ BIKE"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let originButton: GlassButton = {
        let button = GlassButton()
        button.setTitle("SELECT ORIGIN", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let destinationButton: GlassButton = {
        let button = GlassButton()
        button.setTitle("SELECT DESTINATION", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        layer.cornerRadius = 24
        layer.masksToBounds = true
        
        // Add blur background
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Container for content
        let contentView = blurView.contentView
        
        // Stack view for layout
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 2
        
        // Time section
        let timeLabel = createSectionLabel("TEMPORAL MODE")
        let timeStack = UIStackView(arrangedSubviews: [timeLabel, timeSegmentControl])
        timeStack.axis = .vertical
        timeStack.spacing = 8
        
        // Mode section
        let modeLabel = createSectionLabel("ROAD MODE")
        let modeStack = UIStackView(arrangedSubviews: [modeLabel, modeSegmentControl])
        modeStack.axis = .vertical
        modeStack.spacing = 8
        
        // Station buttons
        let stationLabel = createSectionLabel("JOURNEY CONSTRAINTS")
        let stationStack = UIStackView(arrangedSubviews: [originButton, destinationButton])
        stationStack.axis = .vertical
        stationStack.spacing = 8
        
        let journeyStack = UIStackView(arrangedSubviews: [stationLabel, stationStack])
        journeyStack.axis = .vertical
        journeyStack.spacing = 8
        
        stackView.addArrangedSubview(headerStack)
        stackView.addArrangedSubview(dividerView)
        stackView.addArrangedSubview(timeStack)
        stackView.addArrangedSubview(modeStack)
        stackView.addArrangedSubview(journeyStack)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            
            dividerView.heightAnchor.constraint(equalToConstant: 0.5),
            originButton.heightAnchor.constraint(equalToConstant: 44),
            destinationButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Actions
        timeSegmentControl.addTarget(self, action: #selector(timeChanged), for: .valueChanged)
        modeSegmentControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        originButton.addTarget(self, action: #selector(originTapped), for: .touchUpInside)
        destinationButton.addTarget(self, action: #selector(destinationTapped), for: .touchUpInside)
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 30
        layer.shadowOpacity = 0.2
        layer.masksToBounds = false
    }
    
    private func createSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .tertiaryLabel
        return label
    }
    
    // MARK: - Actions
    
    @objc private func timeChanged() {
        delegate?.controlPanel(self, didChangeTimeOfDay: timeSegmentControl.selectedSegmentIndex == 0)
    }
    
    @objc private func modeChanged() {
        let mode: RoadMode = modeSegmentControl.selectedSegmentIndex == 0 ? .car : .bike
        delegate?.controlPanel(self, didChangeRoadMode: mode)
    }
    
    @objc private func originTapped() {
        delegate?.controlPanel(self, didSelectOrigin: nil)
    }
    
    @objc private func destinationTapped() {
        delegate?.controlPanel(self, didSelectDestination: nil)
    }
    
    // MARK: - Public
    
    func setOrigin(_ station: Station?) {
        originButton.setTitle(station?.name.uppercased() ?? "SELECT ORIGIN", for: .normal)
    }
    
    func setDestination(_ station: Station?) {
        destinationButton.setTitle(station?.name.uppercased() ?? "SELECT DESTINATION", for: .normal)
    }
}
