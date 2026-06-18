import UIKit

final class MessageCell: UITableViewCell {
    static let reuseIdentifier = "MessageCell"

    private let bubble = UIView()
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

        bubble.layer.cornerRadius = 18
        bubble.layer.masksToBounds = true
        bubble.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)

        messageLabel.numberOfLines = 0
        messageLabel.font = DesignSystem.Font.body
        messageLabel.textColor = .white
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(messageLabel)

        leadingConstraint = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),
            messageLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
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
            bubble.backgroundColor = DesignSystem.Color.pink
            messageLabel.font = DesignSystem.Font.captionSemibold
        case .assistant:
            leadingConstraint.isActive = true
            bubble.backgroundColor = DesignSystem.Color.card
            messageLabel.font = DesignSystem.Font.body
        }
    }
}
