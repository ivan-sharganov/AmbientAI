import UIKit

final class HistoryCell: UITableViewCell {
    static let reuseIdentifier = "HistoryCell"

    private let container = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()

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

        container.backgroundColor = DesignSystem.Color.card
        container.layer.cornerRadius = 18
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        iconView.image = UIImage(systemName: "sparkles")
        iconView.tintColor = DesignSystem.Color.lavender
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

        titleLabel.font = DesignSystem.Font.captionSemibold
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        timeLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = DesignSystem.Color.secondaryText
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),

            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
    }

    func configure(with session: ChatSession) {
        titleLabel.text = session.lastMessagePreview
        timeLabel.text = DateFormatting.timeFormatter.string(from: session.updatedAt)
    }
}
