//
//  ControlPanelView.swift
//  NammaTravels
//
//  Premium floating glass control panel with iOS 26 Liquid Glass design
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
        let blur = UIBlurEffect(style: .systemChromeMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let gradientOverlay: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor
        ]
        layer.locations = [0.0, 0.5]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "NAMMA TRAVELS"
        label.font = .systemFont(ofSize: 13, weight: .black)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Metro vs Road • Bengaluru"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeSegmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["🌅 MORNING", "🌆 EVENING"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = UIColor(red: 0.98, green: 0.6, blue: 0.2, alpha: 1.0) // Orange
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 11, weight: .bold)
        ], for: .selected)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.darkGray,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ], for: .normal)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let modeSegmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["🚗 CAR", "🏍️ BIKE"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0) // Dark
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 11, weight: .bold)
        ], for: .selected)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.darkGray,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ], for: .normal)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var originButton: UIButton = {
        let button = createStationButton(title: "SELECT ORIGIN", color: UIColor.systemGreen)
        button.addTarget(self, action: #selector(originTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var destinationButton: UIButton = {
        let button = createStationButton(title: "SELECT DESTINATION", color: UIColor.systemRed)
        button.addTarget(self, action: #selector(destinationTapped), for: .touchUpInside)
        return button
    }()
    
    private let connectionLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray4
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientOverlay.frame = bounds
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        
        // Add blur background
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add gradient overlay for glass depth
        layer.addSublayer(gradientOverlay)
        
        // Container for content
        let contentView = blurView.contentView
        
        // Header
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        // Divider
        let divider = createDivider()
        contentView.addSubview(divider)
        
        // Time section
        let timeLabel = createSectionLabel("PEAK HOURS")
        contentView.addSubview(timeLabel)
        contentView.addSubview(timeSegmentControl)
        
        // Mode section
        let modeLabel = createSectionLabel("COMPARE WITH")
        contentView.addSubview(modeLabel)
        contentView.addSubview(modeSegmentControl)
        
        // Divider 2
        let divider2 = createDivider()
        contentView.addSubview(divider2)
        
        // Station buttons
        let journeyLabel = createSectionLabel("YOUR JOURNEY")
        contentView.addSubview(journeyLabel)
        contentView.addSubview(originButton)
        contentView.addSubview(connectionLine)
        contentView.addSubview(destinationButton)
        
        NSLayoutConstraint.activate([
            // Header
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            // Divider 1
            divider.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            // Time section
            timeLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 20),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            timeSegmentControl.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 12),
            timeSegmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            timeSegmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            timeSegmentControl.heightAnchor.constraint(equalToConstant: 40),
            
            // Mode section
            modeLabel.topAnchor.constraint(equalTo: timeSegmentControl.bottomAnchor, constant: 20),
            modeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            modeSegmentControl.topAnchor.constraint(equalTo: modeLabel.bottomAnchor, constant: 12),
            modeSegmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            modeSegmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            modeSegmentControl.heightAnchor.constraint(equalToConstant: 40),
            
            // Divider 2
            divider2.topAnchor.constraint(equalTo: modeSegmentControl.bottomAnchor, constant: 20),
            divider2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            divider2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            divider2.heightAnchor.constraint(equalToConstant: 1),
            
            // Journey section
            journeyLabel.topAnchor.constraint(equalTo: divider2.bottomAnchor, constant: 20),
            journeyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            originButton.topAnchor.constraint(equalTo: journeyLabel.bottomAnchor, constant: 12),
            originButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            originButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            originButton.heightAnchor.constraint(equalToConstant: 52),
            
            connectionLine.topAnchor.constraint(equalTo: originButton.bottomAnchor),
            connectionLine.centerXAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
            connectionLine.widthAnchor.constraint(equalToConstant: 2),
            connectionLine.heightAnchor.constraint(equalToConstant: 12),
            
            destinationButton.topAnchor.constraint(equalTo: connectionLine.bottomAnchor),
            destinationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            destinationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            destinationButton.heightAnchor.constraint(equalToConstant: 52),
            destinationButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        // Actions
        timeSegmentControl.addTarget(self, action: #selector(timeChanged), for: .valueChanged)
        modeSegmentControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        
        // Premium shadow
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 16)
        layer.shadowRadius = 40
        layer.shadowOpacity = 0.2
        
        // Border for glass effect
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
    }
    
    private func createSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = UIColor.tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    private func createStationButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.filled()
        config.title = title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            return outgoing
        }
        config.baseForegroundColor = .darkGray
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.7)
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "mappin.circle.fill")
        config.imagePadding = 10
        config.imagePlacement = .leading
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        
        button.configuration = config
        button.tintColor = color
        
        // Add subtle border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray5.cgColor
        button.layer.cornerRadius = 12
        
        return button
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
        animateButton(originButton)
        delegate?.controlPanel(self, didSelectOrigin: nil)
    }
    
    @objc private func destinationTapped() {
        animateButton(destinationButton)
        delegate?.controlPanel(self, didSelectDestination: nil)
    }
    
    private func animateButton(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
    
    // MARK: - Public
    
    func setOrigin(_ station: Station?) {
        var config = originButton.configuration
        config?.title = station?.name.uppercased() ?? "SELECT ORIGIN"
        config?.baseBackgroundColor = station != nil ? UIColor.systemGreen.withAlphaComponent(0.15) : UIColor.white.withAlphaComponent(0.7)
        originButton.configuration = config
        
        if station != nil {
            originButton.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.5).cgColor
        }
    }
    
    func setDestination(_ station: Station?) {
        var config = destinationButton.configuration
        config?.title = station?.name.uppercased() ?? "SELECT DESTINATION"
        config?.baseBackgroundColor = station != nil ? UIColor.systemRed.withAlphaComponent(0.15) : UIColor.white.withAlphaComponent(0.7)
        destinationButton.configuration = config
        
        if station != nil {
            destinationButton.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.5).cgColor
        }
    }
}
