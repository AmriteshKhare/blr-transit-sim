//
//  UIView+Glass.swift
//  BLRTransitApp
//
//  Extension for applying Apple Liquid Glass effects to UIViews
//

import UIKit

extension UIView {
    
    /// Applies a liquid glass (frosted glass) effect to the view
    /// - Parameters:
    ///   - style: The blur style to use (.systemUltraThinMaterial recommended for glass)
    ///   - cornerRadius: Corner radius for rounded glass effect
    func applyGlassEffect(style: UIBlurEffect.Style = .systemUltraThinMaterial, cornerRadius: CGFloat = 20) {
        // Remove existing blur if any
        subviews.filter { $0 is UIVisualEffectView && $0.tag == 999 }.forEach { $0.removeFromSuperview() }
        
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.tag = 999
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = cornerRadius
        blurView.clipsToBounds = true
        
        insertSubview(blurView, at: 0)
        
        // Apply corner radius and shadow for depth
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        
        // Subtle shadow for elevation
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 24
        layer.shadowOpacity = 0.15
    }
    
    /// Applies a more prominent glass effect with border
    func applyElevatedGlassEffect(cornerRadius: CGFloat = 24) {
        applyGlassEffect(style: .systemChromeMaterial, cornerRadius: cornerRadius)
        
        // Add subtle border
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
    }
    
    /// Applies a subtle tinted glass effect
    /// - Parameter tintColor: The tint color overlaid on the glass
    func applyTintedGlassEffect(tintColor: UIColor, cornerRadius: CGFloat = 16) {
        applyGlassEffect(style: .systemThinMaterial, cornerRadius: cornerRadius)
        
        // Add tint overlay
        let tintView = UIView()
        tintView.backgroundColor = tintColor.withAlphaComponent(0.1)
        tintView.frame = bounds
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tintView.layer.cornerRadius = cornerRadius
        tintView.isUserInteractionEnabled = false
        tintView.tag = 998
        
        // Remove existing tint
        subviews.filter { $0.tag == 998 }.forEach { $0.removeFromSuperview() }
        
        insertSubview(tintView, at: 1)
    }
}

// MARK: - Glass Button

class GlassButton: UIButton {
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGlass()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGlass()
    }
    
    private func setupGlass() {
        backgroundColor = .clear
        
        blurView.isUserInteractionEnabled = false
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true
        insertSubview(blurView, at: 0)
        
        layer.cornerRadius = 12
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        setTitleColor(.label, for: .normal)
        
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.alpha = self.isHighlighted ? 0.8 : 1.0
            }
        }
    }
}
