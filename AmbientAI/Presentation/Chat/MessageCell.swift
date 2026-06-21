import UIKit

final class MessageCell: UITableViewCell {
    static let reuseIdentifier = "MessageCell"

    private let bubble = GradientView(
        colors: [MessageStyle.card, MessageStyle.card],
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
    )
    private let messageLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        bubble.layer.cornerRadius = 12
        bubble.layer.cornerCurve = .continuous
        bubble.layer.masksToBounds = true
        bubble.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)

        messageLabel.numberOfLines = 0
        messageLabel.font = MessageStyle.font(size: 15, weight: .regular)
        messageLabel.textColor = .white
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(messageLabel)

        leadingConstraint = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.88),
            messageLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -12)
        ])
    }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.text
        leadingConstraint.isActive = false
        trailingConstraint.isActive = false

        switch message.role {
        case .user:
            trailingConstraint.isActive = true
            bubble.update(colors: [MessageStyle.blue, MessageStyle.pink])
            messageLabel.font = MessageStyle.font(size: 15, weight: .regular)

        case .assistant:
            leadingConstraint.isActive = true
            bubble.update(colors: [MessageStyle.card, MessageStyle.card])
            messageLabel.font = MessageStyle.font(size: 15, weight: .regular)
        }
    }
}

private enum MessageStyle {
    static let card = UIColor(red: 27 / 255, green: 20 / 255, blue: 29 / 255, alpha: 1)
    static let blue = UIColor(red: 152 / 255, green: 198 / 255, blue: 247 / 255, alpha: 1)
    static let pink = UIColor(red: 235 / 255, green: 91 / 255, blue: 146 / 255, alpha: 1)

    static func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        UIFont(name: "Inter-Regular", size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}
