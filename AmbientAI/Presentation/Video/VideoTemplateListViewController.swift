import Photos
import UIKit

final class VideoTemplateListViewController: UIViewController {
    var onClose: (() -> Void)?
    var onSelectTemplate: ((VideoTemplate) -> Void)?
    var onOpenHistory: (() -> Void)?

    private let categories = VideoTemplateCatalog.categories
    private var selectedCategoryIndex = 0
    private lazy var selectedTemplates = categories[selectedCategoryIndex].templates

    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
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
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 14, left: 18, bottom: 24, right: 18)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.dataSource = self
        collection.delegate = self
        collection.alwaysBounceVertical = true
        collection.register(VideoTemplateCell.self, forCellWithReuseIdentifier: VideoTemplateCell.reuseIdentifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background
        let background = GradientView(colors: [UIColor(red: 0.16, green: 0.13, blue: 0.24, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        let header = makeHeader()
        view.addSubview(header)
        view.addSubview(categoryCollectionView)
        view.addSubview(templatesCollectionView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            header.heightAnchor.constraint(equalToConstant: 44),

            categoryCollectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 34),

            templatesCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 4),
            templatesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            templatesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            templatesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let backButton = IconButton(systemName: "chevron.left", pointSize: 18)
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let avatar = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
        avatar.layer.cornerRadius = 15
        avatar.layer.masksToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        let avatarIcon = UIImageView(image: UIImage(systemName: "camera.filters"))
        avatarIcon.tintColor = .white
        avatarIcon.contentMode = .scaleAspectFit
        avatar.addSubview(avatarIcon)
        avatarIcon.pinToSuperviewEdges(insets: UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7))

        let title = UILabel()
        title.text = "AI Video"
        title.textColor = .white
        title.font = DesignSystem.Font.navTitle
        title.translatesAutoresizingMaskIntoConstraints = false

        let refreshButton = IconButton(systemName: "arrow.triangle.2.circlepath", pointSize: 17)
        refreshButton.addTarget(self, action: #selector(openHistoryTapped), for: .touchUpInside)

        container.addSubview(backButton)
        container.addSubview(avatar)
        container.addSubview(title)
        container.addSubview(refreshButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            avatar.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 10),
            avatar.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 30),
            avatar.heightAnchor.constraint(equalToConstant: 30),

            title.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            title.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            refreshButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            refreshButton.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func openTemplateWithPhotoPermission(_ template: VideoTemplate) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            onSelectTemplate?(template)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.onSelectTemplate?(template)
                    } else {
                        self?.showPhotoAccessAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPhotoAccessAlert()
        @unknown default:
            showPhotoAccessAlert()
        }
    }

    private func showPhotoAccessAlert() {
        let alert = UIAlertController(title: "Allow access to photos?", message: "To upload an image, the app needs access to your photo gallery.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func openHistoryTapped() {
        onOpenHistory?()
    }
}

extension VideoTemplateListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView === categoryCollectionView ? categories.count : selectedTemplates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCategoryCell.reuseIdentifier, for: indexPath) as! VideoCategoryCell
            cell.configure(title: categories[indexPath.item].title, isSelected: indexPath.item == selectedCategoryIndex)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoTemplateCell.reuseIdentifier, for: indexPath) as! VideoTemplateCell
        cell.configure(template: selectedTemplates[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === categoryCollectionView {
            selectedCategoryIndex = indexPath.item
            selectedTemplates = categories[indexCategorySafe: selectedCategoryIndex]?.templates ?? []
            categoryCollectionView.reloadData()
            templatesCollectionView.reloadSections(IndexSet(integer: 0))
            return
        }
        openTemplateWithPhotoPermission(selectedTemplates[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === categoryCollectionView {
            let title = categories[indexPath.item].title as NSString
            return CGSize(width: max(70, title.size(withAttributes: [.font: DesignSystem.Font.captionSemibold]).width + 28), height: 30)
        }
        let width = floor((collectionView.bounds.width - 48) / 2)
        return CGSize(width: width, height: 210)
    }
}

private extension Array {
    subscript(indexCategorySafe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private final class VideoCategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoCategoryCell"
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 15
        contentView.layer.masksToBounds = true
        titleLabel.font = DesignSystem.Font.captionSemibold
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        titleLabel.pinToSuperviewEdges(insets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .white : DesignSystem.Color.secondaryText
        contentView.backgroundColor = isSelected ? DesignSystem.Color.pink : UIColor.white.withAlphaComponent(0.06)
    }
}

private final class VideoTemplateCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoTemplateCell"
    private let artwork = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = DesignSystem.Color.card

        artwork.layer.cornerRadius = 18
        artwork.layer.masksToBounds = true
        artwork.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(artwork)
        artwork.pinToSuperviewEdges()

        iconView.tintColor = .white.withAlphaComponent(0.82)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        let textBackground = GradientView(colors: [UIColor.clear, UIColor.black.withAlphaComponent(0.72)], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        contentView.addSubview(textBackground)
        textBackground.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.textColor = .white
        titleLabel.font = DesignSystem.Font.bodySemibold
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        subtitleLabel.font = DesignSystem.Font.caption
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -16),
            iconView.widthAnchor.constraint(equalToConstant: 54),
            iconView.heightAnchor.constraint(equalToConstant: 54),

            textBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            textBackground.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -4),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(template: VideoTemplate) {
        artwork.update(colors: template.gradient)
        iconView.image = UIImage(systemName: template.symbolName)
        titleLabel.text = template.title
        subtitleLabel.text = template.subtitle
    }
}
