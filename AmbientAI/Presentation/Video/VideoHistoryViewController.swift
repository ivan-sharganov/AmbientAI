import UIKit

final class VideoHistoryViewController: UIViewController {
    var onClose: (() -> Void)?

    private let items: [VideoHistoryItem]
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 18, left: 24, bottom: 28, right: 24)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.register(VideoHistoryCell.self, forCellWithReuseIdentifier: VideoHistoryCell.reuseIdentifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    init(items: [VideoHistoryItem] = VideoHistoryItem.mockItems) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background
        let background = GradientView(colors: [UIColor(red: 0.13, green: 0.08, blue: 0.16, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        let header = makeHeader()
        view.addSubview(header)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            header.heightAnchor.constraint(equalToConstant: 44),

            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if items.isEmpty {
            setupEmptyState()
        }
    }

    private func makeHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let backButton = IconButton(systemName: "chevron.left", pointSize: 18)
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let title = UILabel()
        title.text = "AI Video History"
        title.textColor = .white
        title.font = DesignSystem.Font.navTitle
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(backButton)
        container.addSubview(title)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            title.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func setupEmptyState() {
        collectionView.isHidden = true

        let ghostGrid = UIView()
        ghostGrid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ghostGrid)

        for row in 0..<3 {
            for column in 0..<2 {
                let placeholder = UIView()
                placeholder.backgroundColor = DesignSystem.Color.card.withAlphaComponent(0.34)
                placeholder.layer.cornerRadius = 12
                placeholder.translatesAutoresizingMaskIntoConstraints = false
                ghostGrid.addSubview(placeholder)
                NSLayoutConstraint.activate([
                    placeholder.topAnchor.constraint(equalTo: ghostGrid.topAnchor, constant: CGFloat(row) * 150),
                    placeholder.leadingAnchor.constraint(equalTo: ghostGrid.leadingAnchor, constant: CGFloat(column) * 148),
                    placeholder.widthAnchor.constraint(equalToConstant: 132),
                    placeholder.heightAnchor.constraint(equalToConstant: 132)
                ])
            }
        }

        let icon = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
        icon.tintColor = DesignSystem.Color.pink
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "No videos yet"
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Create your first video to see it here"
        subtitle.textColor = DesignSystem.Color.secondaryText
        subtitle.font = DesignSystem.Font.caption
        subtitle.textAlignment = .center

        let stack = UIStackView(axis: .vertical, spacing: 10, alignment: .center)
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            ghostGrid.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
            ghostGrid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            ghostGrid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            ghostGrid.heightAnchor.constraint(equalToConstant: 440),

            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48),

            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -8)
        ])
    }

    @objc private func closeTapped() {
        onClose?()
    }
}

extension VideoHistoryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoHistoryCell.reuseIdentifier, for: indexPath) as! VideoHistoryCell
        cell.configure(item: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 56) / 2)
        return CGSize(width: width, height: width * 1.36)
    }
}

struct VideoHistoryItem {
    let title: String
    let symbolName: String
    let gradient: [UIColor]

    static let mockItems: [VideoHistoryItem] = [
        VideoHistoryItem(title: "Portrait", symbolName: "person.fill", gradient: [UIColor(red: 0.95, green: 0.47, blue: 0.33, alpha: 1), UIColor(red: 0.18, green: 0.12, blue: 0.20, alpha: 1)]),
        VideoHistoryItem(title: "Cartoon", symbolName: "face.smiling", gradient: [UIColor(red: 0.55, green: 0.78, blue: 0.31, alpha: 1), UIColor(red: 0.13, green: 0.34, blue: 0.53, alpha: 1)]),
        VideoHistoryItem(title: "Anime", symbolName: "sparkles", gradient: [UIColor(red: 0.99, green: 0.67, blue: 0.28, alpha: 1), UIColor(red: 0.83, green: 0.40, blue: 0.57, alpha: 1)]),
        VideoHistoryItem(title: "Family", symbolName: "camera.fill", gradient: [UIColor(red: 0.58, green: 0.36, blue: 0.22, alpha: 1), UIColor(red: 0.93, green: 0.64, blue: 0.50, alpha: 1)]),
        VideoHistoryItem(title: "Pet", symbolName: "pawprint.fill", gradient: [UIColor(red: 0.76, green: 0.55, blue: 0.36, alpha: 1), UIColor(red: 0.37, green: 0.24, blue: 0.18, alpha: 1)]),
        VideoHistoryItem(title: "Flower", symbolName: "camera.macro", gradient: [UIColor(red: 0.43, green: 0.78, blue: 0.55, alpha: 1), UIColor(red: 0.95, green: 0.62, blue: 0.34, alpha: 1)])
    ]
}

private final class VideoHistoryCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoHistoryCell"
    private let artwork = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.addSubview(artwork)
        artwork.pinToSuperviewEdges()

        iconView.tintColor = .white.withAlphaComponent(0.9)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        titleLabel.textColor = .white
        titleLabel.font = DesignSystem.Font.captionSemibold
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -8),
            iconView.widthAnchor.constraint(equalToConstant: 54),
            iconView.heightAnchor.constraint(equalToConstant: 54),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: VideoHistoryItem) {
        artwork.update(colors: item.gradient)
        iconView.image = UIImage(systemName: item.symbolName)
        titleLabel.text = item.title
    }
}
