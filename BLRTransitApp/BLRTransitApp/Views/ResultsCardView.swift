//
//  ResultsCardView.swift
//  BLRTransitApp
//
//  Frosted glass results card showing time comparison
//

import UIKit

class ResultsCardView: UIView {
    
    // MARK: - UI Components
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let efficiencyLabel: UILabel = {
        let label = UILabel()
        label.text = "EFFICIENCY GAIN"
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .systemGreen.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeSavedLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = .systemFont(ofSize: 48, weight: .light)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let minSavedLabel: UILabel = {
        let label = UILabel()
        label.text = "MIN SAVED"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let metroRowView = ComparisonRowView(mode: .metro)
    private let roadRowView = ComparisonRowView(mode: .road)
    
    private let divider: UIView = {
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
        layer.cornerRadius = 20
        layer.masksToBounds = true
        
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        let contentView = blurView.contentView
        
        // Efficiency section background
        let efficiencyBg = UIView()
        efficiencyBg.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        efficiencyBg.layer.cornerRadius = 12
        efficiencyBg.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(efficiencyBg)
        efficiencyBg.addSubview(efficiencyLabel)
        efficiencyBg.addSubview(timeSavedLabel)
        efficiencyBg.addSubview(minSavedLabel)
        
        contentView.addSubview(divider)
        
        metroRowView.translatesAutoresizingMaskIntoConstraints = false
        roadRowView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metroRowView)
        contentView.addSubview(roadRowView)
        
        NSLayoutConstraint.activate([
            efficiencyBg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            efficiencyBg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            efficiencyBg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            efficiencyLabel.topAnchor.constraint(equalTo: efficiencyBg.topAnchor, constant: 12),
            efficiencyLabel.leadingAnchor.constraint(equalTo: efficiencyBg.leadingAnchor, constant: 12),
            
            timeSavedLabel.topAnchor.constraint(equalTo: efficiencyLabel.bottomAnchor, constant: 4),
            timeSavedLabel.leadingAnchor.constraint(equalTo: efficiencyBg.leadingAnchor, constant: 12),
            timeSavedLabel.bottomAnchor.constraint(equalTo: efficiencyBg.bottomAnchor, constant: -12),
            
            minSavedLabel.centerYAnchor.constraint(equalTo: timeSavedLabel.centerYAnchor),
            minSavedLabel.leadingAnchor.constraint(equalTo: timeSavedLabel.trailingAnchor, constant: 8),
            
            divider.topAnchor.constraint(equalTo: efficiencyBg.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            
            metroRowView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            metroRowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            metroRowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            roadRowView.topAnchor.constraint(equalTo: metroRowView.bottomAnchor, constant: 16),
            roadRowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            roadRowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            roadRowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 20
        layer.shadowOpacity = 0.15
        layer.masksToBounds = false
    }
    
    // MARK: - Public
    
    func update(metroTime: Double, roadTime: Double, roadMode: RoadMode, hasBottlenecks: Bool) {
        let timeSaved = max(0, roadTime - metroTime)
        let minutes = Int(timeSaved / 60)
        
        timeSavedLabel.text = "\(minutes)"
        
        metroRowView.update(time: metroTime, progress: 1.0)
        
        let roadProgress = metroTime > 0 ? min(1.0, roadTime / metroTime) : 0
        roadRowView.update(time: roadTime, progress: roadProgress)
        roadRowView.setMode(roadMode)
        roadRowView.showBottleneckWarning(hasBottlenecks)
    }
}

// MARK: - Comparison Row View

class ComparisonRowView: UIView {
    
    enum Mode {
        case metro
        case road
    }
    
    private let mode: Mode
    
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.trackTintColor = .systemGray5
        bar.layer.cornerRadius = 3
        bar.clipsToBounds = true
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️ HEAVY CONGESTION"
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .systemRed
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(mode: Mode) {
        self.mode = mode
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        self.mode = .metro
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        switch mode {
        case .metro:
            iconLabel.text = "🚇"
            titleLabel.text = "NAMMA METRO"
            progressBar.progressTintColor = .darkGray
        case .road:
            iconLabel.text = "🚗"
            titleLabel.text = "ROAD TRAFFIC"
            progressBar.progressTintColor = .systemRed
        }
        
        addSubview(iconLabel)
        addSubview(titleLabel)
        addSubview(timeLabel)
        addSubview(progressBar)
        addSubview(warningLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconLabel.topAnchor.constraint(equalTo: topAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: iconLabel.centerYAnchor),
            
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: iconLabel.centerYAnchor),
            
            progressBar.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 6),
            
            warningLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 6),
            warningLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            warningLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func update(time: Double, progress: Double) {
        let minutes = Int(time / 60)
        timeLabel.text = "\(minutes) min"
        progressBar.setProgress(Float(progress), animated: true)
    }
    
    func setMode(_ roadMode: RoadMode) {
        guard mode == .road else { return }
        iconLabel.text = roadMode == .car ? "🚗" : "🏍️"
    }
    
    func showBottleneckWarning(_ show: Bool) {
        warningLabel.isHidden = !show
    }
}
