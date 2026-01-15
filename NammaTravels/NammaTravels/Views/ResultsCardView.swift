//
//  ResultsCardView.swift
//  NammaTravels
//
//  Premium frosted glass results card showing time comparison
//

import UIKit

class ResultsCardView: UIView {
    
    // MARK: - UI Components
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemChromeMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let heroContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let efficiencyLabel: UILabel = {
        let label = UILabel()
        label.text = "TIME SAVED WITH METRO"
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = UIColor.systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeSavedLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = .systemFont(ofSize: 56, weight: .ultraLight)
        label.textColor = UIColor.systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let minSavedLabel: UILabel = {
        let label = UILabel()
        label.text = "MINUTES"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.systemGreen.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let metroRowView = ComparisonRowView(mode: .metro)
    private let roadRowView = ComparisonRowView(mode: .road)
    
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
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        let contentView = blurView.contentView
        
        // Hero section
        contentView.addSubview(heroContainer)
        heroContainer.addSubview(efficiencyLabel)
        heroContainer.addSubview(timeSavedLabel)
        heroContainer.addSubview(minSavedLabel)
        
        // Comparison rows
        metroRowView.translatesAutoresizingMaskIntoConstraints = false
        roadRowView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metroRowView)
        contentView.addSubview(roadRowView)
        
        NSLayoutConstraint.activate([
            heroContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            heroContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            efficiencyLabel.topAnchor.constraint(equalTo: heroContainer.topAnchor, constant: 16),
            efficiencyLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 16),
            
            timeSavedLabel.topAnchor.constraint(equalTo: efficiencyLabel.bottomAnchor, constant: 4),
            timeSavedLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 16),
            timeSavedLabel.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -16),
            
            minSavedLabel.leadingAnchor.constraint(equalTo: timeSavedLabel.trailingAnchor, constant: 8),
            minSavedLabel.bottomAnchor.constraint(equalTo: timeSavedLabel.bottomAnchor, constant: -12),
            
            metroRowView.topAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: 16),
            metroRowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            metroRowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            metroRowView.heightAnchor.constraint(equalToConstant: 44),
            
            roadRowView.topAnchor.constraint(equalTo: metroRowView.bottomAnchor, constant: 8),
            roadRowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            roadRowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            roadRowView.heightAnchor.constraint(equalToConstant: 44),
            roadRowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Shadow
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 24
        layer.shadowOpacity = 0.15
        
        // Border
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
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
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var progressWidthConstraint: NSLayoutConstraint?
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️"
        label.font = .systemFont(ofSize: 12)
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
            containerView.backgroundColor = UIColor.systemGray6
            progressBar.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        case .road:
            iconLabel.text = "🚗"
            titleLabel.text = "BY ROAD"
            containerView.backgroundColor = UIColor.systemGray6
            progressBar.backgroundColor = UIColor.systemRed.withAlphaComponent(0.7)
        }
        
        addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(progressBar)
        containerView.addSubview(warningLabel)
        
        let widthConstraint = progressBar.widthAnchor.constraint(equalToConstant: 0)
        progressWidthConstraint = widthConstraint
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            warningLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -4),
            warningLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            progressBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            progressBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4),
            widthConstraint
        ])
    }
    
    func update(time: Double, progress: Double) {
        let minutes = Int(time / 60)
        timeLabel.text = "\(minutes) min"
        
        // Animate progress bar
        layoutIfNeeded()
        progressWidthConstraint?.constant = bounds.width * CGFloat(min(progress, 1.0))
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.layoutIfNeeded()
        }
    }
    
    func setMode(_ roadMode: RoadMode) {
        guard mode == .road else { return }
        iconLabel.text = roadMode == .car ? "🚗" : "🏍️"
    }
    
    func showBottleneckWarning(_ show: Bool) {
        warningLabel.isHidden = !show
        if show {
            progressBar.backgroundColor = UIColor.systemRed
        }
    }
}
