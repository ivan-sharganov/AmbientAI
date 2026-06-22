import UIKit

final class ShimmerPlaceholderView: UIView {
    private let shimmer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 31 / 255, green: 25 / 255, blue: 31 / 255, alpha: 1)
        isUserInteractionEnabled = false

        shimmer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.09).cgColor,
            UIColor.clear.cgColor
        ]
        shimmer.locations = [-0.5, -0.25, 0]
        shimmer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(shimmer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shimmer.frame = bounds
        if !isHidden, window != nil { startAnimating() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        window == nil ? stopAnimating() : startAnimating()
    }

    func show() {
        alpha = 1
        isHidden = false
        setNeedsLayout()
        startAnimating()
    }

    func hide(animated: Bool) {
        guard animated else {
            stopAnimating()
            isHidden = true
            alpha = 1
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.stopAnimating()
            self.isHidden = true
            self.alpha = 1
        })
    }

    private func startAnimating() {
        guard !bounds.isEmpty,
              !isHidden,
              shimmer.animation(forKey: "shimmer") == nil else { return }

        let duration: CFTimeInterval = 1.6
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-0.5, -0.25, 0]
        animation.toValue = [1, 1.25, 1.5]
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)

        let mediaTime = CACurrentMediaTime()
        let localTime = shimmer.convertTime(mediaTime, from: nil)
        animation.beginTime = localTime - mediaTime.truncatingRemainder(dividingBy: duration)
        shimmer.add(animation, forKey: "shimmer")
    }

    private func stopAnimating() {
        shimmer.removeAnimation(forKey: "shimmer")
    }
}
