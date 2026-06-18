import PhotosUI
import UIKit

final class VideoTemplateDetailViewController: UIViewController {
    var onClose: (() -> Void)?

    private enum DropdownKind {
        case format
        case quality
    }

    private let template: VideoTemplate
    private let variants: [VideoTemplate]
    private let formats = ["16:9", "9:16", "1:1"]
    private let qualities = ["540p", "720p", "1080p", "4K"]
    private var selectedTemplateIndex = 0
    private var selectedFormat = "16:9"
    private var selectedQuality = "1080p"
    private var selectedImages: [UIImage?] = []
    private var loadingSlots = Set<Int>()
    private var activePhotoSlot = 0

    private var selectedTemplate: VideoTemplate {
        variants[selectedTemplateIndex]
    }

    private var requiredPhotoCount: Int {
        selectedTemplate.id == "clay-fool" ? 2 : 1
    }

    private var hasAllRequiredImages: Bool {
        selectedImages.prefix(requiredPhotoCount).allSatisfy { $0 != nil }
    }

    private lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.decelerationRate = .fast
        collection.dataSource = self
        collection.delegate = self
        collection.register(VideoCarouselCell.self, forCellWithReuseIdentifier: VideoCarouselCell.reuseIdentifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    private let uploadSlotsStack = UIStackView(axis: .horizontal, spacing: 18, alignment: .leading)
    private var uploadContainers: [UIView] = []
    private var plusImageViews: [UIImageView] = []
    private var selectedImageViews: [UIImageView] = []
    private var photoLoadingIndicators: [UIActivityIndicatorView] = []
    private var removePhotoButtons: [UIButton] = []

    private let formatValueLabel = UILabel()
    private let qualityValueLabel = UILabel()
    private let titleLabel = UILabel()
    private let formatRowButton = UIButton(type: .system)
    private let qualityRowButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)
    private let dropdownDimView = UIControl()
    private let dropdownView = UIView()
    private var dropdownTopConstraint: NSLayoutConstraint?

    init(template: VideoTemplate) {
        self.template = template
        self.variants = [template] + Array(VideoTemplateCatalog.categories.flatMap(\.templates).filter { $0.id != template.id }.prefix(4))
        super.init(nibName: nil, bundle: nil)
        self.selectedImages = Array(repeating: nil, count: requiredPhotoCount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderPhotoSlots()
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background
        let background = GradientView(colors: [UIColor(red: 0.15, green: 0.11, blue: 0.20, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        let header = makeHeader()
        view.addSubview(header)
        view.addSubview(carouselCollectionView)

        setupPhotoSlots()
        view.addSubview(uploadSlotsStack)

        let rowsStack = UIStackView(axis: .vertical, spacing: 12)
        rowsStack.addArrangedSubview(makeSettingRow(button: formatRowButton, title: "Format", valueLabel: formatValueLabel, initialValue: selectedFormat, selector: #selector(formatTapped)))
        rowsStack.addArrangedSubview(makeSettingRow(button: qualityRowButton, title: "Quality", valueLabel: qualityValueLabel, initialValue: selectedQuality, selector: #selector(qualityTapped)))
        view.addSubview(rowsStack)

        configureCreateButton()
        view.addSubview(createButton)
        setupDropdownOverlay()

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            header.heightAnchor.constraint(equalToConstant: 44),

            carouselCollectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 28),
            carouselCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carouselCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carouselCollectionView.heightAnchor.constraint(equalToConstant: 255),

            uploadSlotsStack.topAnchor.constraint(equalTo: carouselCollectionView.bottomAnchor, constant: 24),
            uploadSlotsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            uploadSlotsStack.heightAnchor.constraint(equalToConstant: 92),

            rowsStack.topAnchor.constraint(equalTo: uploadSlotsStack.bottomAnchor, constant: 12),
            rowsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            rowsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            createButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func makeHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let backButton = IconButton(systemName: "chevron.left", pointSize: 18)
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        titleLabel.text = selectedTemplate.title
        titleLabel.textColor = .white
        titleLabel.font = DesignSystem.Font.navTitle
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(backButton)
        container.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func setupPhotoSlots() {
        uploadSlotsStack.arrangedSubviews.forEach { view in
            uploadSlotsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        uploadContainers.removeAll()
        plusImageViews.removeAll()
        selectedImageViews.removeAll()
        photoLoadingIndicators.removeAll()
        removePhotoButtons.removeAll()

        (0..<requiredPhotoCount).forEach { index in
            uploadSlotsStack.addArrangedSubview(makePhotoSlot(index: index))
        }
    }

    private func makePhotoSlot(index: Int) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapper.widthAnchor.constraint(equalToConstant: 92),
            wrapper.heightAnchor.constraint(equalToConstant: 92)
        ])

        let container = UIView()
        container.backgroundColor = DesignSystem.Color.background
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = DesignSystem.Color.pink.cgColor
        container.clipsToBounds = true
        container.tag = index
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(photoSlotTapped(_:))))
        wrapper.addSubview(container)

        let plusImageView = UIImageView(image: UIImage(systemName: "plus"))
        plusImageView.tintColor = .white
        plusImageView.contentMode = .scaleAspectFit
        plusImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(plusImageView)

        let selectedImageView = UIImageView()
        selectedImageView.contentMode = .scaleAspectFill
        selectedImageView.clipsToBounds = true
        selectedImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(selectedImageView)
        selectedImageView.pinToSuperviewEdges()

        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.color = DesignSystem.Color.lavender
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(loadingIndicator)

        let removeButton = UIButton(type: .system)
        let removeConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        removeButton.setImage(UIImage(systemName: "xmark", withConfiguration: removeConfig), for: .normal)
        removeButton.tintColor = DesignSystem.Color.pink
        removeButton.backgroundColor = UIColor(red: 0.58, green: 0.57, blue: 0.63, alpha: 1)
        removeButton.layer.cornerRadius = 16
        removeButton.tag = index
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.addTarget(self, action: #selector(removePhotoTapped(_:)), for: .touchUpInside)
        wrapper.addSubview(removeButton)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            container.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 10),
            container.widthAnchor.constraint(equalToConstant: 72),
            container.heightAnchor.constraint(equalToConstant: 72),

            plusImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            plusImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            plusImageView.widthAnchor.constraint(equalToConstant: 28),
            plusImageView.heightAnchor.constraint(equalToConstant: 28),

            loadingIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            removeButton.topAnchor.constraint(equalTo: wrapper.topAnchor),
            removeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 10),
            removeButton.widthAnchor.constraint(equalToConstant: 32),
            removeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        uploadContainers.append(container)
        plusImageViews.append(plusImageView)
        selectedImageViews.append(selectedImageView)
        photoLoadingIndicators.append(loadingIndicator)
        removePhotoButtons.append(removeButton)
        return wrapper
    }

    private func makeSettingRow(button: UIButton, title: String, valueLabel: UILabel, initialValue: String, selector: Selector) -> UIButton {
        button.backgroundColor = DesignSystem.Color.card
        button.layer.cornerRadius = 16
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = DesignSystem.Color.secondaryText
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.text = initialValue
        valueLabel.textColor = .white
        valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(titleLabel)
        button.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20),
            valueLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        return button
    }

    private func configureCreateButton() {
        createButton.setTitle("Create", for: .normal)
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        createButton.layer.cornerRadius = 27
        createButton.clipsToBounds = true
        createButton.translatesAutoresizingMaskIntoConstraints = false

        let gradient = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
        gradient.isUserInteractionEnabled = false
        createButton.insertSubview(gradient, at: 0)
        gradient.pinToSuperviewEdges()
    }

    private func setupDropdownOverlay() {
        dropdownDimView.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        dropdownDimView.alpha = 0
        dropdownDimView.isHidden = true
        dropdownDimView.addTarget(self, action: #selector(hideDropdown), for: .touchUpInside)
        dropdownDimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dropdownDimView)
        dropdownDimView.pinToSuperviewEdges()

        dropdownView.backgroundColor = DesignSystem.Color.card
        dropdownView.layer.cornerRadius = 18
        dropdownView.clipsToBounds = true
        dropdownView.alpha = 0
        dropdownView.isHidden = true
        dropdownView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dropdownView)
        dropdownTopConstraint = dropdownView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        NSLayoutConstraint.activate([
            dropdownTopConstraint!,
            dropdownView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            dropdownView.widthAnchor.constraint(equalToConstant: 224)
        ])
    }

    private func renderPhotoSlots() {
        guard selectedImages.count >= requiredPhotoCount else { return }
        for index in 0..<requiredPhotoCount {
            let image = selectedImages[index]
            let isLoading = loadingSlots.contains(index)
            selectedImageViews[index].image = image
            selectedImageViews[index].isHidden = image == nil
            plusImageViews[index].isHidden = image != nil || isLoading
            removePhotoButtons[index].isHidden = image == nil || isLoading

            if isLoading {
                photoLoadingIndicators[index].startAnimating()
            } else {
                photoLoadingIndicators[index].stopAnimating()
            }
        }

        let isReady = hasAllRequiredImages && loadingSlots.isEmpty
        createButton.isEnabled = isReady
        createButton.alpha = isReady ? 1 : 0.26
        createButton.setTitleColor(.white, for: .normal)
    }

    private func updateSelectedTemplate(index: Int) {
        let clampedIndex = min(max(index, 0), variants.count - 1)
        guard clampedIndex != selectedTemplateIndex else { return }

        let previousImages = selectedImages
        selectedTemplateIndex = clampedIndex
        titleLabel.text = selectedTemplate.title
        loadingSlots = loadingSlots.filter { $0 < requiredPhotoCount }

        selectedImages = Array(previousImages.prefix(requiredPhotoCount))
        if selectedImages.count < requiredPhotoCount {
            selectedImages.append(contentsOf: Array(repeating: nil, count: requiredPhotoCount - selectedImages.count))
        }

        setupPhotoSlots()
        renderPhotoSlots()
    }

    private func pageIndex(for offsetX: CGFloat) -> Int {
        let itemWidth = carouselCollectionView.bounds.width - 72
        let pageWidth = itemWidth + 12
        guard pageWidth > 0 else { return selectedTemplateIndex }
        return min(max(Int(round(offsetX / pageWidth)), 0), variants.count - 1)
    }

    private func showDropdown(kind: DropdownKind) {
        dropdownView.subviews.forEach { $0.removeFromSuperview() }
        let options: [String]
        let selectedValue: String
        let sourceButton: UIButton
        switch kind {
        case .format:
            options = formats
            selectedValue = selectedFormat
            sourceButton = formatRowButton
        case .quality:
            options = qualities
            selectedValue = selectedQuality
            sourceButton = qualityRowButton
        }

        var previousBottomAnchor = dropdownView.topAnchor
        options.enumerated().forEach { index, option in
            let row = makeDropdownRow(title: option, isSelected: option == selectedValue, kind: kind)
            row.tag = index
            row.addTarget(self, action: kind == .format ? #selector(formatOptionTapped(_:)) : #selector(qualityOptionTapped(_:)), for: .touchUpInside)
            dropdownView.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: previousBottomAnchor),
                row.leadingAnchor.constraint(equalTo: dropdownView.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: dropdownView.trailingAnchor),
                row.heightAnchor.constraint(equalToConstant: 54)
            ])
            previousBottomAnchor = row.bottomAnchor
        }
        previousBottomAnchor.constraint(equalTo: dropdownView.bottomAnchor).isActive = true

        let sourceFrame = sourceButton.convert(sourceButton.bounds, to: view)
        let dropdownHeight = CGFloat(options.count) * 54
        let preferredTop = kind == .format ? sourceFrame.minY - 22 : sourceFrame.midY - dropdownHeight / 2
        dropdownTopConstraint?.constant = max(view.safeAreaInsets.top + 90, min(preferredTop, view.bounds.height - dropdownHeight - 90))

        view.layoutIfNeeded()
        dropdownDimView.isHidden = false
        dropdownView.isHidden = false
        dropdownView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.dropdownDimView.alpha = 1
            self.dropdownView.alpha = 1
            self.dropdownView.transform = .identity
        }
    }

    private func makeDropdownRow(title: String, isSelected: Bool, kind: DropdownKind) -> UIButton {
        let row = UIButton(type: .system)
        row.backgroundColor = .clear
        row.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = isSelected ? DesignSystem.Color.pink : .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        if kind == .format {
            let iconView = UIImageView(image: formatIcon(for: title))
            iconView.tintColor = isSelected ? DesignSystem.Color.pink : .white
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -20),
                iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 24),
                iconView.heightAnchor.constraint(equalToConstant: 24)
            ])
        }

        let separator = UIView()
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        separator.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        return row
    }

    private func formatIcon(for value: String) -> UIImage? {
        switch value {
        case "16:9": return UIImage(systemName: "rectangle")
        case "9:16": return UIImage(systemName: "rectangle.portrait")
        default: return UIImage(systemName: "square")
        }
    }

    @objc private func hideDropdown() {
        UIView.animate(withDuration: 0.14, delay: 0, options: [.curveEaseIn]) {
            self.dropdownDimView.alpha = 0
            self.dropdownView.alpha = 0
            self.dropdownView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        } completion: { _ in
            self.dropdownDimView.isHidden = true
            self.dropdownView.isHidden = true
            self.dropdownView.transform = .identity
        }
    }

    @objc private func photoSlotTapped(_ recognizer: UITapGestureRecognizer) {
        guard let slot = recognizer.view?.tag else { return }
        activePhotoSlot = slot
        openPhotoPicker()
    }

    private func openPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func removePhotoTapped(_ sender: UIButton) {
        let slot = sender.tag
        guard selectedImages.indices.contains(slot) else { return }
        loadingSlots.remove(slot)
        selectedImages[slot] = nil
        renderPhotoSlots()
    }

    @objc private func formatTapped() {
        showDropdown(kind: .format)
    }

    @objc private func qualityTapped() {
        showDropdown(kind: .quality)
    }

    @objc private func formatOptionTapped(_ sender: UIButton) {
        selectedFormat = formats[sender.tag]
        formatValueLabel.text = selectedFormat
        hideDropdown()
    }

    @objc private func qualityOptionTapped(_ sender: UIButton) {
        selectedQuality = qualities[sender.tag]
        qualityValueLabel.text = selectedQuality
        hideDropdown()
    }

    @objc private func closeTapped() {
        onClose?()
    }
}

extension VideoTemplateDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self), selectedImages.indices.contains(activePhotoSlot) else { return }
        let slot = activePhotoSlot
        loadingSlots.insert(slot)
        selectedImages[slot] = nil
        renderPhotoSlots()

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loadingSlots.remove(slot)
                self.selectedImages[slot] = object as? UIImage
                self.renderPhotoSlots()
            }
        }
    }
}

extension VideoTemplateDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        variants.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCarouselCell.reuseIdentifier, for: indexPath) as! VideoCarouselCell
        cell.configure(template: variants[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === carouselCollectionView else { return }
        updateSelectedTemplate(index: indexPath.item)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - 72, height: collectionView.bounds.height)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === carouselCollectionView else { return }
        let itemWidth = carouselCollectionView.bounds.width - 72
        let pageWidth = itemWidth + 12
        let proposedOffset = targetContentOffset.pointee.x
        var page = round(proposedOffset / pageWidth)

        if abs(velocity.x) > 0.25 {
            page = velocity.x > 0 ? floor(proposedOffset / pageWidth) + 1 : ceil(proposedOffset / pageWidth) - 1
        }

        let maxOffset = max(0, scrollView.contentSize.width - scrollView.bounds.width)
        let targetOffsetX = min(max(page * pageWidth, 0), maxOffset)
        targetContentOffset.pointee.x = targetOffsetX
        updateSelectedTemplate(index: pageIndex(for: targetOffsetX))
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === carouselCollectionView else { return }
        updateSelectedTemplate(index: pageIndex(for: scrollView.contentOffset.x))
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === carouselCollectionView else { return }
        updateSelectedTemplate(index: pageIndex(for: scrollView.contentOffset.x))
    }
}

private final class VideoCarouselCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoCarouselCell"
    private let artwork = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true

        contentView.addSubview(artwork)
        artwork.pinToSuperviewEdges()

        iconView.tintColor = .white.withAlphaComponent(0.82)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -16),
            iconView.widthAnchor.constraint(equalToConstant: 82),
            iconView.heightAnchor.constraint(equalToConstant: 82),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(template: VideoTemplate) {
        artwork.update(colors: template.gradient)
        iconView.image = UIImage(systemName: template.symbolName)
        titleLabel.text = template.title
    }
}
