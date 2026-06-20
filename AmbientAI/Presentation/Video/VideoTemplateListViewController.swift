import Photos
import UIKit

final class VideoTemplateListViewController: UIViewController {
    var onClose: (() -> Void)?
    var onSelectTemplate: ((VideoTemplate, [VideoTemplate]) -> Void)?
    var onOpenHistory: (() -> Void)?

    private enum State {
        case loading
        case content
        case error(String)
    }

    private let loadingCategoryTitles = ["Popular", "Funny", "Sad", "Trends", "Dances"]
    private let service: PixverseServiceProtocol
    private var state: State = .loading
    private var categories: [VideoTemplateCategory] = []
    private var selectedCategoryIndex = 0
    private var selectedTemplates: [VideoTemplate] = []
    private let errorLabel = UILabel()

    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(VideoCategoryCell.self, forCellWithReuseIdentifier: VideoCategoryCell.reuseIdentifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    private lazy var templatesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 34, right: 16)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsVerticalScrollIndicator = false
        collection.alwaysBounceVertical = true
        collection.dataSource = self
        collection.delegate = self
        collection.register(VideoTemplateCell.self, forCellWithReuseIdentifier: VideoTemplateCell.reuseIdentifier)
        collection.register(VideoTemplateSkeletonCell.self, forCellWithReuseIdentifier: VideoTemplateSkeletonCell.reuseIdentifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    init(service: PixverseServiceProtocol) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        render(.loading)
        loadTemplates()
    }

    private func setupUI() {
        view.backgroundColor = VideoCatalogStyle.background

        let headerBackground = UIView()
        headerBackground.backgroundColor = VideoCatalogStyle.card.withAlphaComponent(0.4)
        headerBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBackground)

        let headerContents = makeHeaderContents()
        view.addSubview(headerContents)
        view.addSubview(categoryCollectionView)
        view.addSubview(templatesCollectionView)

        errorLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        errorLabel.font = VideoCatalogStyle.font(size: 16, weight: .regular)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            headerBackground.topAnchor.constraint(equalTo: view.topAnchor),
            headerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBackground.bottomAnchor.constraint(equalTo: headerContents.bottomAnchor),

            headerContents.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContents.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContents.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContents.heightAnchor.constraint(equalToConstant: 64),

            categoryCollectionView.topAnchor.constraint(equalTo: headerContents.bottomAnchor, constant: 24),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 34),

            templatesCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 24),
            templatesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            templatesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            templatesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorLabel.centerYAnchor.constraint(equalTo: templatesCollectionView.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func makeHeaderContents() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let backButton = UIButton(type: .custom)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        let backIcon = UIImageView(image: UIImage(named: "VideoBackVector"))
        backIcon.contentMode = .scaleAspectFit
        backIcon.transform = CGAffineTransform(scaleX: -1, y: 1)
        backIcon.translatesAutoresizingMaskIntoConstraints = false
        backButton.addSubview(backIcon)

        let avatar = GradientView(
            colors: [VideoCatalogStyle.blue, VideoCatalogStyle.pink],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        avatar.layer.cornerRadius = 16
        avatar.layer.cornerCurve = .continuous
        avatar.layer.masksToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        let avatarIcon = UIImageView(image: UIImage(named: "HomeVideoIcon"))
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(avatarIcon)

        let title = UILabel()
        title.text = "AI Video"
        title.textColor = .white
        title.font = VideoCatalogStyle.font(size: 20, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false

        let historyButton = UIButton(type: .custom)
        historyButton.setImage(UIImage(named: "VideoHistoryIcon"), for: .normal)
        historyButton.imageView?.contentMode = .scaleAspectFit
        historyButton.addTarget(self, action: #selector(openHistoryTapped), for: .touchUpInside)
        historyButton.translatesAutoresizingMaskIntoConstraints = false

        [backButton, avatar, title, historyButton].forEach(container.addSubview)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            backIcon.centerXAnchor.constraint(equalTo: backButton.centerXAnchor),
            backIcon.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            backIcon.widthAnchor.constraint(equalToConstant: 9),
            backIcon.heightAnchor.constraint(equalToConstant: 18),

            avatar.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 32),
            avatar.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 32),
            avatar.heightAnchor.constraint(equalToConstant: 32),
            avatarIcon.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 24),
            avatarIcon.heightAnchor.constraint(equalToConstant: 24),

            title.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            title.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            historyButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            historyButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            historyButton.widthAnchor.constraint(equalToConstant: 24),
            historyButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        return container
    }

    private func loadTemplates() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let loadedCategories = try await service.loadTemplateCategories()
                categories = loadedCategories
                selectedCategoryIndex = 0
                selectedTemplates = loadedCategories.first?.templates ?? []
                render(.content)
            } catch {
                render(.error(error.localizedDescription))
            }
        }
    }

    private func render(_ newState: State) {
        state = newState
        switch newState {
        case .loading:
            errorLabel.isHidden = true
            categoryCollectionView.isUserInteractionEnabled = false
        case .content:
            errorLabel.isHidden = true
            categoryCollectionView.isUserInteractionEnabled = true
        case let .error(message):
            errorLabel.text = message
            errorLabel.isHidden = false
            categoryCollectionView.isUserInteractionEnabled = false
        }
        categoryCollectionView.reloadData()
        templatesCollectionView.reloadData()
    }

    private func categoryTitle(at index: Int) -> String {
        if case .loading = state { return loadingCategoryTitles[index] }
        return categories[index].title
    }

    private func openTemplateWithPhotoPermission(_ template: VideoTemplate) {
        let open = { [weak self] in
            self?.onSelectTemplate?(template, self?.selectedTemplates ?? [template])
        }
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            open()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    status == .authorized || status == .limited ? open() : self?.showPhotoAccessAlert()
                }
            }
        default:
            showPhotoAccessAlert()
        }
    }

    private func showPhotoAccessAlert() {
        let alert = UIAlertController(
            title: "Allow access to photos?",
            message: "To upload an image, the app needs access to your photo gallery.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }

    @objc private func closeTapped() { onClose?() }
    @objc private func openHistoryTapped() { onOpenHistory?() }
}

extension VideoTemplateListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === categoryCollectionView {
            if case .loading = state { return loadingCategoryTitles.count }
            return categories.count
        }
        if case .loading = state { return 6 }
        return selectedTemplates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: VideoCategoryCell.reuseIdentifier,
                for: indexPath
            ) as! VideoCategoryCell
            let isSelected = indexPath.item == selectedCategoryIndex
            cell.configure(title: categoryTitle(at: indexPath.item), isSelected: isSelected)
            return cell
        }

        if case .loading = state {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: VideoTemplateSkeletonCell.reuseIdentifier,
                for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoTemplateCell.reuseIdentifier,
            for: indexPath
        ) as! VideoTemplateCell
        cell.configure(template: selectedTemplates[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case .content = state else { return }
        if collectionView === categoryCollectionView {
            selectedCategoryIndex = indexPath.item
            selectedTemplates = categories[indexPath.item].templates
            categoryCollectionView.reloadData()
            templatesCollectionView.setContentOffset(.zero, animated: false)
            templatesCollectionView.reloadData()
        } else {
            openTemplateWithPhotoPermission(selectedTemplates[indexPath.item])
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView === categoryCollectionView {
            let title = categoryTitle(at: indexPath.item) as NSString
            let width = title.size(withAttributes: [
                .font: VideoCatalogStyle.font(size: 14, weight: .regular)
            ]).width + 32
            return CGSize(width: max(76, ceil(width)), height: 34)
        }
        let width = floor((collectionView.bounds.width - 48) / 2)
        return CGSize(width: width, height: 232)
    }
}

private final class VideoCategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoCategoryCell"
    private let selectedBackground = GradientView(
        colors: [VideoCatalogStyle.blue, VideoCatalogStyle.pink],
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
    )
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = VideoCatalogStyle.card.withAlphaComponent(0.6)
        contentView.layer.cornerRadius = 17
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true

        selectedBackground.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectedBackground)
        selectedBackground.pinToSuperviewEdges()

        titleLabel.font = VideoCatalogStyle.font(size: 14, weight: .regular)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        titleLabel.pinToSuperviewEdges(insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.alpha = isSelected ? 1 : 0.5
        selectedBackground.isHidden = !isSelected
    }
}

private final class VideoTemplateCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoTemplateCell"
    private let previewImageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = VideoCatalogStyle.card
        contentView.layer.cornerRadius = 24
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(previewImageView)
        previewImageView.pinToSuperviewEdges()

        let overlay = GradientView(
            colors: [UIColor.clear, VideoCatalogStyle.card.withAlphaComponent(0.6)],
            startPoint: CGPoint(x: 0.5, y: 0),
            endPoint: CGPoint(x: 0.5, y: 1)
        )
        overlay.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(overlay)
        overlay.pinToSuperviewEdges()

        titleLabel.textColor = .white
        titleLabel.font = VideoCatalogStyle.font(size: 16, weight: .regular)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        previewImageView.image = UIImage(named: "VideoTemplateFallback")
    }

    func configure(template: VideoTemplate) {
        titleLabel.text = template.title
        previewImageView.image = UIImage(named: "VideoTemplateFallback")
    }
}

private final class VideoTemplateSkeletonCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoTemplateSkeletonCell"
    private let baseGradient = CAGradientLayer()
    private let shimmer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = VideoCatalogStyle.card.withAlphaComponent(0.28)
        contentView.layer.cornerRadius = 24
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true

        baseGradient.colors = [
            UIColor.clear.cgColor,
            VideoCatalogStyle.card.withAlphaComponent(0.6).cgColor
        ]
        baseGradient.startPoint = CGPoint(x: 0.5, y: 0)
        baseGradient.endPoint = CGPoint(x: 0.5, y: 1)
        contentView.layer.addSublayer(baseGradient)

        shimmer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.08).cgColor,
            UIColor.clear.cgColor
        ]
        shimmer.locations = [0, 0.5, 1]
        shimmer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmer.endPoint = CGPoint(x: 1, y: 0.5)
        contentView.layer.addSublayer(shimmer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        baseGradient.frame = contentView.bounds
        shimmer.frame = contentView.bounds.insetBy(dx: -contentView.bounds.width, dy: 0)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        window == nil ? stopShimmer() : startShimmer()
    }

    private func startShimmer() {
        guard shimmer.animation(forKey: "shimmer") == nil else { return }
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -contentView.bounds.width
        animation.toValue = contentView.bounds.width
        animation.duration = 1.35
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmer.add(animation, forKey: "shimmer")
    }

    private func stopShimmer() {
        shimmer.removeAnimation(forKey: "shimmer")
    }
}

private enum VideoCatalogStyle {
    static let background = UIColor(red: 11 / 255, green: 7 / 255, blue: 14 / 255, alpha: 1)
    static let card = UIColor(red: 31 / 255, green: 25 / 255, blue: 31 / 255, alpha: 1)
    static let blue = UIColor(red: 152 / 255, green: 198 / 255, blue: 247 / 255, alpha: 1)
    static let pink = UIColor(red: 235 / 255, green: 91 / 255, blue: 146 / 255, alpha: 1)

    static func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let name: String
        switch weight {
        case .bold: name = "Inter-Bold"
        case .semibold: name = "Inter-SemiBold"
        case .medium: name = "Inter-Medium"
        default: name = "Inter-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}
