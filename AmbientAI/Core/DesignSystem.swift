import UIKit

enum DesignSystem {
    enum Color {
        static let background = UIColor(red: 0.03, green: 0.02, blue: 0.05, alpha: 1)
        static let backgroundElevated = UIColor(red: 0.09, green: 0.06, blue: 0.10, alpha: 1)
        static let card = UIColor(red: 0.12, green: 0.08, blue: 0.13, alpha: 1)
        static let border = UIColor.white.withAlphaComponent(0.14)
        static let primaryText = UIColor.white
        static let secondaryText = UIColor.white.withAlphaComponent(0.58)
        static let mutedText = UIColor.white.withAlphaComponent(0.36)
        static let pink = UIColor(red: 0.91, green: 0.29, blue: 0.58, alpha: 1)
        static let lavender = UIColor(red: 0.67, green: 0.72, blue: 0.98, alpha: 1)
        static let purple = UIColor(red: 0.37, green: 0.15, blue: 0.51, alpha: 1)
    }

    enum Font {
        static let title = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let navTitle = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let bodySemibold = UIFont.systemFont(ofSize: 15, weight: .semibold)
        static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
        static let captionSemibold = UIFont.systemFont(ofSize: 12, weight: .semibold)
    }
}

extension UIView {
    func pinToSuperviewEdges(insets: UIEdgeInsets = .zero) {
        guard let superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom)
        ])
    }
}

extension UIStackView {
    convenience init(axis: NSLayoutConstraint.Axis, spacing: CGFloat, alignment: UIStackView.Alignment = .fill, distribution: UIStackView.Distribution = .fill) {
        self.init(frame: .zero)
        self.axis = axis
        self.spacing = spacing
        self.alignment = alignment
        self.distribution = distribution
        translatesAutoresizingMaskIntoConstraints = false
    }
}
