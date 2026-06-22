import PhotosUI
import UIKit

final class VideoTemplateDetailViewController: UIViewController {
    var onClose: (() -> Void)?
    var onCreate: ((VideoGenerationRequest) -> Void)?

    private let variants: [VideoTemplate]
    private var selectedTemplateIndex: Int
    private var selectedImage: UIImage?
    private var selectedFormat = "16:9"
    private var selectedQuality = "1080p"
    private let formats = ["16:9", "9:16", "1:1"]
    private let qualities = ["540p", "720p", "1080p", "4K"]

    private let titleLabel = UILabel()
    private let selectedPhotoView = UIImageView()
    private let plusImageView = UIImageView(image: UIImage(named: "VideoAddPhotoPlus"))
    private let removeButton = UIButton(type: .custom)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let formatValueLabel = UILabel()
    private let qualityValueLabel = UILabel()
    private let createButton = UIButton(type: .system)
    private weak var selectionOverlay: VideoSelectionOverlayView?
    private let createGradient = GradientView(
        colors: [VideoDetailStyle.blue, VideoDetailStyle.pink],
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
    )

    private var selectedTemplate: VideoTemplate { variants[selectedTemplateIndex] }
    private lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.decelerationRate = .fast
        collection.clipsToBounds = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(VideoCarouselCell.self, forCellWithReuseIdentifier: VideoCarouselCell.reuseIdentifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    init(template: VideoTemplate, variants: [VideoTemplate]) {
        let availableVariants = variants.isEmpty ? [template] : variants
        self.variants = availableVariants
        self.selectedTemplateIndex = availableVariants.firstIndex(where: { $0.id == template.id }) ?? 0
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderPhoto()
        DispatchQueue.main.async { [weak self] in
            self?.scrollToSelectedTemplate(animated: false)
        }
    }

    private func setupUI() {
        view.backgroundColor = VideoDetailStyle.background

        let header = makeHeader()
        let upload = makeUploadView()
        let rows = makeSettingsRows()
        configureCreateButton()

        view.addSubview(header)
        view.addSubview(carouselCollectionView)
        view.addSubview(upload)
        view.addSubview(rows)
        view.addSubview(createButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 44),

            carouselCollectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            carouselCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carouselCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carouselCollectionView.heightAnchor.constraint(equalToConstant: 311),

            upload.topAnchor.constraint(equalTo: carouselCollectionView.bottomAnchor, constant: 24),
            upload.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            upload.widthAnchor.constraint(equalToConstant: 100),
            upload.heightAnchor.constraint(equalToConstant: 100),

            rows.topAnchor.constraint(equalTo: upload.bottomAnchor, constant: 24),
            rows.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            rows.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func makeHeader() -> UIView {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false

        let backButton = UIButton(type: .custom)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        let backIcon = UIImageView(image: UIImage(named: "VideoBackVector"))
        backIcon.contentMode = .scaleAspectFit
        backIcon.transform = CGAffineTransform(scaleX: -1, y: 1)
        backIcon.translatesAutoresizingMaskIntoConstraints = false
        backButton.addSubview(backIcon)

        titleLabel.text = selectedTemplate.title
        titleLabel.textColor = .white
        titleLabel.font = VideoDetailStyle.font(size: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(backButton)
        header.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            backIcon.centerXAnchor.constraint(equalTo: backButton.centerXAnchor),
            backIcon.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            backIcon.widthAnchor.constraint(equalToConstant: 9),
            backIcon.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -48)
        ])
        return header
    }

    private func makeUploadView() -> UIView {
        let container = VideoPhotoUploadView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPhotoPicker)))

        selectedPhotoView.contentMode = .scaleAspectFill
        selectedPhotoView.clipsToBounds = true
        selectedPhotoView.layer.cornerRadius = 15
        selectedPhotoView.layer.cornerCurve = .continuous
        selectedPhotoView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(selectedPhotoView)
        selectedPhotoView.pinToSuperviewEdges(insets: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1))

        plusImageView.contentMode = .scaleAspectFit
        plusImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(plusImageView)

        loadingIndicator.color = VideoDetailStyle.blue
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(loadingIndicator)

        removeButton.setImage(UIImage(named: "VideoRemovePhotoIcon"), for: .normal)
        removeButton.backgroundColor = .white
        removeButton.layer.cornerRadius = 16
        removeButton.layer.cornerCurve = .continuous
        removeButton.addTarget(self, action: #selector(removePhoto), for: .touchUpInside)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(removeButton)

        NSLayoutConstraint.activate([
            plusImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            plusImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            plusImageView.widthAnchor.constraint(equalToConstant: 32),
            plusImageView.heightAnchor.constraint(equalToConstant: 32),

            loadingIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            removeButton.centerXAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            removeButton.centerYAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            removeButton.widthAnchor.constraint(equalToConstant: 32),
            removeButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        return container
    }

    private func makeSettingsRows() -> UIView {
        let formatRow = makeSettingRow(title: "Format", value: selectedFormat, selector: #selector(formatTapped))
        let qualityRow = makeSettingRow(title: "Quality", value: selectedQuality, selector: #selector(qualityTapped))
        let rows = UIStackView(axis: .vertical, spacing: 8)
        rows.addArrangedSubview(formatRow)
        rows.addArrangedSubview(qualityRow)
        return rows
    }

    private func makeSettingRow(title: String, value: String, selector: Selector?) -> UIView {
        let button = UIButton(type: .system)
        button.backgroundColor = VideoDetailStyle.card.withAlphaComponent(0.5)
        button.layer.cornerRadius = 24
        button.layer.cornerCurve = .continuous
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        if let selector { button.addTarget(self, action: selector, for: .touchUpInside) }

        let titleView = UILabel()
        titleView.text = title
        titleView.textColor = UIColor.white.withAlphaComponent(0.6)
        titleView.font = VideoDetailStyle.font(size: 16, weight: .medium)
        titleView.translatesAutoresizingMaskIntoConstraints = false

        let valueView = title == "Quality" ? qualityValueLabel : formatValueLabel
        valueView.text = value
        valueView.textColor = .white
        valueView.font = VideoDetailStyle.font(size: 16, weight: .medium)
        valueView.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(titleView)
        button.addSubview(valueView)
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            titleView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            valueView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            valueView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        return button
    }

    private func configureCreateButton() {
        createButton.setTitle("Create", for: .normal)
        createButton.titleLabel?.font = VideoDetailStyle.font(size: 16, weight: .semibold)
        createButton.backgroundColor = VideoDetailStyle.card
        createButton.layer.cornerRadius = 24
        createButton.layer.cornerCurve = .continuous
        createButton.clipsToBounds = true
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false

        createGradient.isUserInteractionEnabled = false
        createButton.insertSubview(createGradient, at: 0)
        createGradient.pinToSuperviewEdges()
    }

    private func renderPhoto() {
        let hasPhoto = selectedImage != nil
        selectedPhotoView.image = selectedImage
        selectedPhotoView.isHidden = !hasPhoto
        plusImageView.isHidden = hasPhoto || loadingIndicator.isAnimating
        removeButton.isHidden = !hasPhoto
        createButton.isEnabled = hasPhoto
        createGradient.isHidden = !hasPhoto
        createButton.setTitleColor(
            hasPhoto ? .white : UIColor.white.withAlphaComponent(0.3),
            for: .normal
        )
    }

    private func updateSelectedTemplate(index: Int) {
        guard variants.indices.contains(index), index != selectedTemplateIndex else { return }
        selectedTemplateIndex = index
        titleLabel.text = selectedTemplate.title
    }

    private func scrollToSelectedTemplate(animated: Bool) {
        carouselCollectionView.scrollToItem(
            at: IndexPath(item: selectedTemplateIndex, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
    }

    private func centeredTemplateIndex() -> Int {
        let stride = VideoDetailStyle.carouselWidth + VideoDetailStyle.carouselSpacing
        let index = Int(round(carouselCollectionView.contentOffset.x / stride))
        return min(max(index, 0), variants.count - 1)
    }

    @objc private func formatTapped(_ sender: UIButton) {
        presentSelectionMenu(
            from: sender,
            options: formats,
            selectedValue: selectedFormat
        ) { [weak self] value in
            self?.selectedFormat = value
            self?.formatValueLabel.text = value
        }
    }

    @objc private func qualityTapped(_ sender: UIButton) {
        presentSelectionMenu(
            from: sender,
            options: qualities,
            selectedValue: selectedQuality
        ) { [weak self] value in
            self?.selectedQuality = value
            self?.qualityValueLabel.text = value
        }
    }

    private func presentSelectionMenu(
        from sourceView: UIView,
        options: [String],
        selectedValue: String,
        onSelect: @escaping (String) -> Void
    ) {
        selectionOverlay?.dismiss(animated: false)
        view.layoutIfNeeded()
        let sourceFrame = sourceView.convert(sourceView.bounds, to: view)
        let overlay = VideoSelectionOverlayView(
            options: options,
            selectedValue: selectedValue,
            sourceFrame: sourceFrame,
            onSelect: onSelect
        )
        selectionOverlay = overlay
        view.addSubview(overlay)
        overlay.pinToSuperviewEdges()
        overlay.present()
    }

    @objc private func openPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func removePhoto() {
        selectedImage = nil
        renderPhoto()
    }

    @objc private func createTapped() {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.9) else { return }
        onCreate?(VideoGenerationRequest(
            template: selectedTemplate,
            imageData: imageData,
            quality: selectedQuality
        ))
    }

    @objc private func closeTapped() { onClose?() }
}

extension VideoTemplateDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        plusImageView.isHidden = true
        loadingIndicator.startAnimating()
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loadingIndicator.stopAnimating()
                self.selectedImage = object as? UIImage
                self.renderPhoto()
            }
        }
    }
}

extension VideoTemplateDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        variants.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoCarouselCell.reuseIdentifier,
            for: indexPath
        ) as! VideoCarouselCell
        cell.configure(template: variants[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateSelectedTemplate(index: indexPath.item)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: VideoDetailStyle.carouselWidth, height: 311)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let inset = max(16, (collectionView.bounds.width - VideoDetailStyle.carouselWidth) / 2)
        return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let stride = VideoDetailStyle.carouselWidth + VideoDetailStyle.carouselSpacing
        let proposedIndex = round(targetContentOffset.pointee.x / stride)
        let index = min(max(proposedIndex, 0), CGFloat(variants.count - 1))
        targetContentOffset.pointee.x = index * stride
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedTemplate(index: centeredTemplateIndex())
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateSelectedTemplate(index: centeredTemplateIndex())
    }
}

private final class VideoCarouselCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoCarouselCell"
    private let artwork = UIImageView()
    private let previewSkeleton = ShimmerPlaceholderView()
    private var imageTask: Task<Void, Never>?
    private var representedURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        artwork.contentMode = .scaleAspectFill
        artwork.clipsToBounds = true
        artwork.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(artwork)
        artwork.pinToSuperviewEdges()

        previewSkeleton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(previewSkeleton)
        previewSkeleton.pinToSuperviewEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        representedURL = nil
        artwork.image = nil
        previewSkeleton.show()
    }

    func configure(template: VideoTemplate) {
        artwork.image = nil
        previewSkeleton.show()
        imageTask?.cancel()
        representedURL = template.previewURL
        guard let previewURL = template.previewURL else {
            previewSkeleton.hide(animated: false)
            return
        }

        imageTask = Task { [weak self] in
            let image = await RemoteImageLoader.shared.image(from: previewURL)
            guard let self,
                  !Task.isCancelled,
                  representedURL == previewURL else { return }
            guard let image else {
                previewSkeleton.hide(animated: true)
                return
            }
            UIView.transition(
                with: artwork,
                duration: 0.2,
                options: [.transitionCrossDissolve, .allowAnimatedContent]
            ) {
                self.artwork.image = image
            }
            previewSkeleton.hide(animated: true)
        }
    }
}

private final class VideoSelectionOverlayView: UIControl {
    private let menuView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let options: [String]
    private let selectedValue: String
    private let sourceFrame: CGRect
    private let onSelect: (String) -> Void

    init(
        options: [String],
        selectedValue: String,
        sourceFrame: CGRect,
        onSelect: @escaping (String) -> Void
    ) {
        self.options = options
        self.selectedValue = selectedValue
        self.sourceFrame = sourceFrame
        self.onSelect = onSelect
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        addTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
        setupMenu()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let height = CGFloat(options.count) * 44
        let x = bounds.width - 16 - 175
        let y = max(16, min(sourceFrame.maxY - height, bounds.height - 16 - height))
        menuView.frame = CGRect(x: x, y: y, width: 175, height: height)
    }

    func present() {
        superview?.layoutIfNeeded()
        layoutIfNeeded()
        alpha = 0
        menuView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            .translatedBy(x: 2, y: 4)
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.alpha = 1
            self.menuView.transform = .identity
        }
    }

    func dismiss(animated: Bool) {
        guard animated else {
            removeFromSuperview()
            return
        }
        UIView.animate(withDuration: 0.16, animations: {
            self.alpha = 0
            self.menuView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    private func setupMenu() {
        menuView.clipsToBounds = true
        menuView.layer.cornerRadius = 24
        menuView.layer.cornerCurve = .continuous
        menuView.contentView.backgroundColor = VideoDetailStyle.card.withAlphaComponent(0.4)
        addSubview(menuView)

        let stack = UIStackView(axis: .vertical, spacing: 0)
        menuView.contentView.addSubview(stack)
        stack.pinToSuperviewEdges()

        for (index, option) in options.enumerated() {
            let item = VideoSelectionMenuItem(title: option, isSelected: option == selectedValue)
            item.tag = index
            item.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(item)
            item.heightAnchor.constraint(equalToConstant: 44).isActive = true

            if index < options.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                separator.translatesAutoresizingMaskIntoConstraints = false
                item.addSubview(separator)
                NSLayoutConstraint.activate([
                    separator.leadingAnchor.constraint(equalTo: item.leadingAnchor),
                    separator.trailingAnchor.constraint(equalTo: item.trailingAnchor),
                    separator.bottomAnchor.constraint(equalTo: item.bottomAnchor),
                    separator.heightAnchor.constraint(equalToConstant: 0.5)
                ])
            }
        }
    }

    @objc private func optionTapped(_ sender: UIControl) {
        guard options.indices.contains(sender.tag) else { return }
        onSelect(options[sender.tag])
        dismiss(animated: true)
    }

    @objc private func backgroundTapped() {
        dismiss(animated: true)
    }
}

private final class VideoSelectionMenuItem: UIControl {
    private let titleLabel = UILabel()
    private let gradient = CAGradientLayer()
    private let gradientMaskLabel = UILabel()
    private let isItemSelected: Bool

    init(title: String, isSelected: Bool) {
        self.isItemSelected = isSelected
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textColor = isSelected ? .clear : .white
        titleLabel.font = VideoDetailStyle.font(size: 16, weight: .regular)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        if isSelected {
            gradient.colors = [VideoDetailStyle.blue.cgColor, VideoDetailStyle.pink.cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            gradientMaskLabel.text = title
            gradientMaskLabel.font = VideoDetailStyle.font(size: 16, weight: .regular)
            gradientMaskLabel.textColor = .black
            gradient.mask = gradientMaskLabel.layer
            layer.addSublayer(gradient)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard isItemSelected else { return }
        gradient.frame = bounds
        gradientMaskLabel.frame = CGRect(x: 16, y: 0, width: bounds.width - 32, height: bounds.height)
    }
}

private final class VideoPhotoUploadView: UIView {
    private let borderGradient = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.masksToBounds = false

        borderGradient.colors = [VideoDetailStyle.blue.cgColor, VideoDetailStyle.pink.cgColor]
        borderGradient.startPoint = CGPoint(x: 0, y: 0.5)
        borderGradient.endPoint = CGPoint(x: 1, y: 0.5)
        borderGradient.mask = borderMask
        layer.addSublayer(borderGradient)
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        borderMask.lineWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderGradient.frame = bounds
        borderMask.frame = bounds
        borderMask.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: 15.5
        ).cgPath
    }
}

private enum VideoDetailStyle {
    static let background = UIColor(red: 11 / 255, green: 7 / 255, blue: 14 / 255, alpha: 1)
    static let card = UIColor(red: 31 / 255, green: 25 / 255, blue: 31 / 255, alpha: 1)
    static let blue = UIColor(red: 152 / 255, green: 198 / 255, blue: 247 / 255, alpha: 1)
    static let pink = UIColor(red: 235 / 255, green: 91 / 255, blue: 146 / 255, alpha: 1)
    static let carouselWidth: CGFloat = 331
    static let carouselSpacing: CGFloat = 16

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
