import UIKit

final class LoadingDotsView: UIView {
    private let dots = (0..<3).map { _ in UIView() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = DesignSystem.Color.card
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(axis: .horizontal, spacing: 6, alignment: .center)
        addSubview(stack)
        stack.pinToSuperviewEdges(insets: UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))

        for (index, dot) in dots.enumerated() {
            dot.backgroundColor = index == 0 ? DesignSystem.Color.pink : DesignSystem.Color.secondaryText
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8)
            ])
            stack.addArrangedSubview(dot)
        }
    }

    func startAnimating() {
        for (index, dot) in dots.enumerated() {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0.25
            animation.toValue = 1
            animation.duration = 0.55
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + Double(index) * 0.18
            dot.layer.add(animation, forKey: "pulse")
        }
    }
}
