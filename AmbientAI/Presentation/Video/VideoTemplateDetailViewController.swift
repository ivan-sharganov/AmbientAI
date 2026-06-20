import PhotosUI
import UIKit

final class VideoTemplateDetailViewController: UIViewController {
    var onClose: (() -> Void)?
    var onCreate: ((VideoGenerationRequest) -> Void)?

    private let variants: [VideoTemplate]
    private var selectedTemplateIndex: Int
    private var selectedImage: UIImage?
    private var selectedQuality = "1080p"

    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let plusImageView = UIImageView(image: UIImage(systemName: "plus"))
    private let removeButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let qualityValueLabel = UILabel()
    private let createButton = UIButton(type: .system)

    private var selectedTemplate: VideoTemplate { variants[selectedTemplateIndex] }
    private var availableQualities: [String] {
        selectedTemplate.qualities.isEmpty ? ["360p"] : selectedTemplate.qualities
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

    init(template: VideoTemplate, variants: [VideoTemplate]) {
        let uniqueVariants = variants.isEmpty ? [template] : variants
        self.variants = uniqueVariants
        self.selectedTemplateIndex = uniqueVariants.firstIndex(where: { $0.id == template.id }) ?? 0
        super.init(nibName: nil, bundle: nil)
        self.selectedQuality = preferredQuality(for: uniqueVariants[selectedTemplateIndex].qualities)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderPhoto()
        DispatchQueue.main.async { [weak self] in self?.scrollToSelectedTemplate(animated: false) }
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background
        let background = GradientView(colors: [UIColor(red: 0.15, green: 0.11, blue: 0.20, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        let header = makeHeader()
        view.addSubview(header)
        view.addSubview(carouselCollectionView)
        let upload = makeUploadView()
        view.addSubview(upload)

        let formatRow = makeSettingRow(title: "Format", value: "Template default", selector: nil)
        let qualityRow = makeSettingRow(title: "Quality", value: selectedQuality, selector: #selector(qualityTapped))
        let rows = UIStackView(axis: .vertical, spacing: 12)
        rows.addArrangedSubview(formatRow)
        rows.addArrangedSubview(qualityRow)
        view.addSubview(rows)

        configureCreateButton()
        view.addSubview(createButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            header.heightAnchor.constraint(equalToConstant: 44),
            carouselCollectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 28),
            carouselCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carouselCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carouselCollectionView.heightAnchor.constraint(equalToConstant: 255),
            upload.topAnchor.constraint(equalTo: carouselCollectionView.bottomAnchor, constant: 24),
            upload.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            upload.widthAnchor.constraint(equalToConstant: 92),
            upload.heightAnchor.constraint(equalToConstant: 92),
            rows.topAnchor.constraint(equalTo: upload.bottomAnchor, constant: 22),
            rows.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            rows.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createButton.leadingAnchor.constraint(equalTo: rows.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: rows.trailingAnchor),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            createButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func makeHeader() -> UIView {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        let back = IconButton(systemName: "chevron.left", pointSize: 18)
        back.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        titleLabel.text = selectedTemplate.title
        titleLabel.textColor = .white
        titleLabel.font = DesignSystem.Font.navTitle
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(back)
        header.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor), back.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor), titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: back.trailingAnchor, constant: 8)
        ])
        return header
    }

    private func makeUploadView() -> UIView {
        let container = UIView()
        container.backgroundColor = DesignSystem.Color.backgroundElevated
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = DesignSystem.Color.pink.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPhotoPicker)))

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        imageView.pinToSuperviewEdges()

        plusImageView.tintColor = .white
        plusImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(plusImageView)
        loadingIndicator.color = DesignSystem.Color.lavender
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(loadingIndicator)

        removeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        removeButton.tintColor = DesignSystem.Color.pink
        removeButton.backgroundColor = .white
        removeButton.layer.cornerRadius = 12
        removeButton.addTarget(self, action: #selector(removePhoto), for: .touchUpInside)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(removeButton)

        NSLayoutConstraint.activate([
            plusImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor), plusImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor), plusImageView.widthAnchor.constraint(equalToConstant: 28), plusImageView.heightAnchor.constraint(equalToConstant: 28),
            loadingIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor), loadingIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            removeButton.centerXAnchor.constraint(equalTo: container.trailingAnchor, constant: -2), removeButton.centerYAnchor.constraint(equalTo: container.topAnchor, constant: 2), removeButton.widthAnchor.constraint(equalToConstant: 24), removeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        return container
    }

    private func makeSettingRow(title: String, value: String, selector: Selector?) -> UIView {
        let button = UIButton(type: .system)
        button.backgroundColor = DesignSystem.Color.card
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true
        if let selector { button.addTarget(self, action: selector, for: .touchUpInside) }

        let label = UILabel()
        label.text = title
        label.textColor = DesignSystem.Color.secondaryText
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        let valueLabel = title == "Quality" ? qualityValueLabel : UILabel()
        valueLabel.text = value
        valueLabel.textColor = .white
        valueLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(label)
        button.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20), label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20), valueLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        return button
    }

    private func configureCreateButton() {
        createButton.setTitle("Create", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        createButton.layer.cornerRadius = 27
        createButton.clipsToBounds = true
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        let gradient = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
        gradient.isUserInteractionEnabled = false
        createButton.insertSubview(gradient, at: 0)
        gradient.pinToSuperviewEdges()
    }

    private func renderPhoto() {
        imageView.image = selectedImage
        imageView.isHidden = selectedImage == nil
        plusImageView.isHidden = selectedImage != nil
        removeButton.isHidden = selectedImage == nil
        createButton.isEnabled = selectedImage != nil
        createButton.alpha = selectedImage == nil ? 0.28 : 1
    }

    private func updateSelectedTemplate(index: Int) {
        guard variants.indices.contains(index), index != selectedTemplateIndex else { return }
        selectedTemplateIndex = index
        titleLabel.text = selectedTemplate.title
        selectedQuality = preferredQuality(for: availableQualities)
        qualityValueLabel.text = selectedQuality
    }

    private func scrollToSelectedTemplate(animated: Bool) {
        carouselCollectionView.scrollToItem(at: IndexPath(item: selectedTemplateIndex, section: 0), at: .centeredHorizontally, animated: animated)
    }

    @objc private func qualityTapped() {
        let alert = UIAlertController(title: "Quality", message: nil, preferredStyle: .actionSheet)
        availableQualities.forEach { quality in
            alert.addAction(UIAlertAction(title: quality + (quality == selectedQuality ? " ✓" : ""), style: .default) { [weak self] _ in
                self?.selectedQuality = quality
                self?.qualityValueLabel.text = quality
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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
        onCreate?(VideoGenerationRequest(template: selectedTemplate, imageData: imageData, quality: selectedQuality))
    }

    @objc private func closeTapped() { onClose?() }
}

private func preferredQuality(for values: [String]) -> String {
    for quality in ["1080p", "720p", "540p", "360p"] where values.contains(quality) { return quality }
    return values.last ?? "360p"
}

extension VideoTemplateDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        loadingIndicator.startAnimating()
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.selectedImage = object as? UIImage
                self?.renderPhoto()
            }
        }
    }
}

extension VideoTemplateDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { variants.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCarouselCell.reuseIdentifier, for: indexPath) as! VideoCarouselCell
        cell.configure(template: variants[indexPath.item])
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateSelectedTemplate(index: indexPath.item)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - 72, height: collectionView.bounds.height)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let center = CGPoint(x: scrollView.contentOffset.x + scrollView.bounds.midX, y: scrollView.bounds.midY)
        if let index = carouselCollectionView.indexPathForItem(at: center)?.item { updateSelectedTemplate(index: index) }
    }
}

private final class VideoCarouselCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoCarouselCell"
    private let artwork = UIImageView(image: UIImage(named: "VideoTemplateFallback"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        artwork.contentMode = .scaleAspectFill
        artwork.clipsToBounds = true
        artwork.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(artwork)
        artwork.pinToSuperviewEdges()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(template: VideoTemplate) {
        artwork.image = UIImage(named: "VideoTemplateFallback")
    }
}
