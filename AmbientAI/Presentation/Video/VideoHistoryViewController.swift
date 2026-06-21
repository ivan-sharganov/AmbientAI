import UIKit

final class VideoHistoryViewController: UIViewController {
    var onClose: (() -> Void)?
    var onSelectVideo: ((URL) -> Void)?

    private let store: VideoHistoryStore
    private var items: [LocalVideoHistoryItem] = []

    private lazy var collectionView: UICollectionView = {
        let layout = VideoHistoryWaterfallLayout()
        layout.delegate = self
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.contentInsetAdjustmentBehavior = .never
        collection.register(VideoHistoryCell.self, forCellWithReuseIdentifier: VideoHistoryCell.reuseIdentifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    private let emptyContainer = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    init(store: VideoHistoryStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isViewLoaded { loadHistory() }
    }

    private func setupUI() {
        view.backgroundColor = VideoHistoryStyle.background
        let header = makeHeader()
        view.addSubview(header)
        view.addSubview(collectionView)
        setupEmptyState()

        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 44),

            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            emptyContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            emptyContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func makeHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let backButton = UIButton(type: .custom)
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(backButton)

        let backIcon = UIImageView(image: UIImage(named: "VideoBackVector"))
        backIcon.contentMode = .scaleAspectFit
        backIcon.transform = CGAffineTransform(scaleX: -1, y: 1)
        backIcon.translatesAutoresizingMaskIntoConstraints = false
        backButton.addSubview(backIcon)

        let title = UILabel()
        title.text = "AI Video History"
        title.textColor = .white
        title.font = VideoHistoryStyle.font(size: 20, weight: .semibold)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(title)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backIcon.centerXAnchor.constraint(equalTo: backButton.centerXAnchor),
            backIcon.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            backIcon.widthAnchor.constraint(equalToConstant: 9),
            backIcon.heightAnchor.constraint(equalToConstant: 18),

            title.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func setupEmptyState() {
        emptyContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyContainer)

        let ghostGrid = UIView()
        ghostGrid.translatesAutoresizingMaskIntoConstraints = false
        emptyContainer.addSubview(ghostGrid)

        for row in 0..<3 {
            for column in 0..<2 {
                let placeholder = UIView()
                placeholder.backgroundColor = VideoHistoryStyle.card.withAlphaComponent(0.22)
                placeholder.layer.cornerRadius = 12
                placeholder.layer.cornerCurve = .continuous
                placeholder.translatesAutoresizingMaskIntoConstraints = false
                ghostGrid.addSubview(placeholder)
                NSLayoutConstraint.activate([
                    placeholder.topAnchor.constraint(equalTo: ghostGrid.topAnchor, constant: CGFloat(row) * 170),
                    placeholder.leadingAnchor.constraint(equalTo: ghostGrid.leadingAnchor, constant: CGFloat(column) * 183),
                    placeholder.widthAnchor.constraint(equalToConstant: 175),
                    placeholder.heightAnchor.constraint(equalToConstant: 160)
                ])
            }
        }

        let icon = UIImageView(image: UIImage(named: "HomeVideoIcon"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "No videos yet"
        title.textColor = .white
        title.font = VideoHistoryStyle.font(size: 22, weight: .bold)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Create your first video to see it here"
        subtitle.textColor = VideoHistoryStyle.secondaryText
        subtitle.font = VideoHistoryStyle.font(size: 14, weight: .regular)
        subtitle.textAlignment = .center

        let stack = UIStackView(axis: .vertical, spacing: 10, alignment: .center)
        stack.addArrangedSubview(icon)
        stack.setCustomSpacing(18, after: icon)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        emptyContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            ghostGrid.topAnchor.constraint(equalTo: emptyContainer.topAnchor),
            ghostGrid.leadingAnchor.constraint(equalTo: emptyContainer.leadingAnchor),
            ghostGrid.trailingAnchor.constraint(equalTo: emptyContainer.trailingAnchor),
            ghostGrid.heightAnchor.constraint(equalToConstant: 500),

            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48),
            stack.centerXAnchor.constraint(equalTo: emptyContainer.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyContainer.centerYAnchor, constant: -12)
        ])
    }

    private func loadHistory() {
        activityIndicator.startAnimating()
        collectionView.isHidden = true
        emptyContainer.isHidden = true

        Task { [weak self] in
            guard let self else { return }
            do {
                items = try await store.load()
            } catch {
                items = []
                presentLoadError(error)
            }
            activityIndicator.stopAnimating()
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.isHidden = items.isEmpty
            emptyContainer.isHidden = !items.isEmpty
        }
    }

    private func presentLoadError(_ error: Error) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: "Couldn’t load history", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func closeTapped() {
        onClose?()
    }
}

extension VideoHistoryViewController: UICollectionViewDataSource, UICollectionViewDelegate, VideoHistoryWaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoHistoryCell.reuseIdentifier,
            for: indexPath
        ) as! VideoHistoryCell
        cell.configure(item: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectVideo?(items[indexPath.item].videoURL)
    }

    fileprivate func videoHistoryLayout(_ layout: VideoHistoryWaterfallLayout, heightForItemAt indexPath: IndexPath, width: CGFloat) -> CGFloat {
        guard let image = UIImage(contentsOfFile: items[indexPath.item].thumbnailURL.path),
              image.size.width > 0 else { return width * 1.25 }
        let ratio = min(max(image.size.height / image.size.width, 1), 1.55)
        return width * ratio
    }
}

private protocol VideoHistoryWaterfallLayoutDelegate: AnyObject {
    func videoHistoryLayout(_ layout: VideoHistoryWaterfallLayout, heightForItemAt indexPath: IndexPath, width: CGFloat) -> CGFloat
}

private final class VideoHistoryWaterfallLayout: UICollectionViewLayout {
    weak var delegate: VideoHistoryWaterfallLayoutDelegate?
    private let spacing: CGFloat = 8
    private var attributes: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        attributes.removeAll(keepingCapacity: true)
        contentHeight = 0

        let width = floor((collectionView.bounds.width - spacing) / 2)
        var columnHeights: [CGFloat] = [0, 0]
        let count = collectionView.numberOfItems(inSection: 0)
        for item in 0..<count {
            let indexPath = IndexPath(item: item, section: 0)
            let column = columnHeights[0] <= columnHeights[1] ? 0 : 1
            let height = delegate?.videoHistoryLayout(self, heightForItemAt: indexPath, width: width) ?? width * 1.25
            let frame = CGRect(
                x: CGFloat(column) * (width + spacing),
                y: columnHeights[column],
                width: width,
                height: height
            )
            let itemAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            itemAttributes.frame = frame
            attributes.append(itemAttributes)
            columnHeights[column] = frame.maxY + spacing
            contentHeight = max(contentHeight, frame.maxY)
        }
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: collectionView?.bounds.width ?? 0, height: contentHeight + 28)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        attributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        attributes.first { $0.indexPath == indexPath }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        newBounds.width != collectionView?.bounds.width
    }
}

private final class VideoHistoryCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoHistoryCell"
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = VideoHistoryStyle.card
        contentView.layer.cornerRadius = 12
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        imageView.pinToSuperviewEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    func configure(item: LocalVideoHistoryItem) {
        imageView.image = UIImage(contentsOfFile: item.thumbnailURL.path)
    }
}

private enum VideoHistoryStyle {
    static let background = UIColor(red: 11 / 255, green: 7 / 255, blue: 14 / 255, alpha: 1)
    static let card = UIColor(red: 22 / 255, green: 16 / 255, blue: 24 / 255, alpha: 1)
    static let secondaryText = UIColor(red: 96 / 255, green: 96 / 255, blue: 96 / 255, alpha: 1)

    static func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let name: String
        switch weight {
        case .bold: name = "Inter-Bold"
        case .semibold: name = "Inter-SemiBold"
        default: name = "Inter-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}
