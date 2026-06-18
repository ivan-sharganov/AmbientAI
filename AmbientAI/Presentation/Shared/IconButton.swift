import UIKit

final class IconButton: UIButton {
    init(systemName: String, pointSize: CGFloat = 16) {
        super.init(frame: .zero)
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        tintColor = .white
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        layer.cornerRadius = 18
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 36),
            heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
