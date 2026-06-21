import UIKit

final class AIWritingViewController: UIViewController {
    var onClose: (() -> Void)?
    var onGenerate: ((AIWritingRequestModel) -> Void)?

    private let textView = UITextView()
    private let counterLabel = UILabel()
    private let generateButton = UIButton(type: .system)
    private let dismissKeyboardButton = UIButton(type: .system)
    private let languageValueLabel = GradientTextLabel()
    private let styleValueLabel = UILabel()
    private let languages = ["English", "Spanish", "French", "German", "Russian"]
    private let styles = ["Original", "Formal", "Cherish", "Friendly", "Academic"]
    private var optionButtons: [WritingOptionButton] = []
    private weak var selectedActionButton: WritingOptionButton?
    private var dismissKeyboardBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerKeyboardNotifications()
        updateCounter()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = WritingStyle.background
        setupBackground()
        setupHeader()
        setupContent()
        setupDismissKeyboardButton()
    }

    private func setupBackground() {
        let top = makeGlow(named: "HomeGlowTop")
        let left = makeGlow(named: "HomeGlowLeft")
        let right = makeGlow(named: "HomeGlowRight")
        view.addSubview(top)
        view.addSubview(left)
        view.addSubview(right)

        NSLayoutConstraint.activate([
            top.widthAnchor.constraint(equalToConstant: 620),
            top.heightAnchor.constraint(equalToConstant: 338),
            top.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 22),
            top.topAnchor.constraint(equalTo: view.topAnchor, constant: -126),

            left.widthAnchor.constraint(equalToConstant: 350),
            left.heightAnchor.constraint(equalToConstant: 232),
            left.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -42),
            left.topAnchor.constraint(equalTo: view.topAnchor, constant: 96),

            right.widthAnchor.constraint(equalToConstant: 315),
            right.heightAnchor.constraint(equalToConstant: 232),
            right.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 316),
            right.topAnchor.constraint(equalTo: view.topAnchor, constant: 147)
        ])
        top.transform = CGAffineTransform(rotationAngle: 18.36 * .pi / 180)
    }

    private func makeGlow(named name: String) -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: name))
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }

    private func setupHeader() {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let backButton = UIButton(type: .custom)
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(backButton)

        let backIcon = UIImageView(image: UIImage(named: "VideoBackVector"))
        backIcon.contentMode = .scaleAspectFit
        backIcon.transform = CGAffineTransform(scaleX: -1, y: 1)
        backIcon.translatesAutoresizingMaskIntoConstraints = false
        backButton.addSubview(backIcon)

        let refreshButton = UIButton(type: .custom)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(refreshButton)

        let refreshIcon = UIImageView(image: UIImage(named: "VideoRefreshIcon"))
        refreshIcon.contentMode = .scaleAspectFit
        refreshIcon.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.addSubview(refreshIcon)

        let sparkle = UIImageView(image: UIImage(systemName: "sparkles"))
        sparkle.tintColor = .white
        sparkle.contentMode = .scaleAspectFit
        sparkle.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.addSubview(sparkle)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backIcon.centerXAnchor.constraint(equalTo: backButton.centerXAnchor),
            backIcon.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            backIcon.widthAnchor.constraint(equalToConstant: 10),
            backIcon.heightAnchor.constraint(equalToConstant: 20),

            refreshButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            refreshButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 44),
            refreshButton.heightAnchor.constraint(equalToConstant: 44),
            refreshIcon.centerXAnchor.constraint(equalTo: refreshButton.centerXAnchor),
            refreshIcon.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            refreshIcon.widthAnchor.constraint(equalToConstant: 28),
            refreshIcon.heightAnchor.constraint(equalToConstant: 28),
            sparkle.centerXAnchor.constraint(equalTo: refreshButton.centerXAnchor),
            sparkle.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            sparkle.widthAnchor.constraint(equalToConstant: 12),
            sparkle.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    private func setupContent() {
        let icon = UIImageView(image: UIImage(named: "HomeWritingIcon"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = "AI Writing"
        titleLabel.textColor = .white
        titleLabel.font = WritingStyle.font(size: 30, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let inputContainer = UIView()
        inputContainer.backgroundColor = WritingStyle.card
        inputContainer.layer.cornerRadius = 24
        inputContainer.layer.borderColor = WritingStyle.fieldBorder.cgColor
        inputContainer.layer.borderWidth = 1
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)

        textView.text = "I am writing to inform you that the project deadline has been moved to next Friday. Please adjust your schedule accordingly and let me"
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = WritingStyle.pink
        textView.font = WritingStyle.font(size: 16, weight: .regular)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(textView)

        counterLabel.textColor = WritingStyle.dimText
        counterLabel.font = WritingStyle.font(size: 16, weight: .regular)
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(counterLabel)

        let optionsGrid = UIStackView(axis: .vertical, spacing: 8)
        optionsGrid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(optionsGrid)

        let row1 = UIStackView(axis: .horizontal, spacing: 8, distribution: .fillEqually)
        let improve = makeOptionButton("Improve")
        let rewrite = makeOptionButton("Rewrite")
        row1.addArrangedSubview(improve)
        row1.addArrangedSubview(rewrite)

        let row2 = UIStackView(axis: .horizontal, spacing: 8, distribution: .fillEqually)
        let fixGrammar = makeOptionButton("Fix grammar")
        let shorten = makeOptionButton("Shorten")
        row2.addArrangedSubview(fixGrammar)
        row2.addArrangedSubview(shorten)

        optionsGrid.addArrangedSubview(row1)
        optionsGrid.addArrangedSubview(row2)
        optionButtons = [improve, rewrite, fixGrammar, shorten]
        optionButtons.forEach { $0.heightAnchor.constraint(equalToConstant: 60).isActive = true }
        selectOption(fixGrammar)

        let translateRow = makePickerRow(
            title: "Translate",
            valueLabel: languageValueLabel,
            initialValue: "Spanish",
            selector: #selector(languageTapped)
        )
        let styleRow = makePickerRow(
            title: "Style",
            valueLabel: styleValueLabel,
            initialValue: "Original",
            selector: #selector(styleTapped)
        )
        view.addSubview(translateRow)
        view.addSubview(styleRow)

        generateButton.setTitle("Generate", for: .normal)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.titleLabel?.font = WritingStyle.font(size: 16, weight: .semibold)
        generateButton.layer.cornerRadius = 25
        generateButton.layer.masksToBounds = true
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(generateButton)

        let buttonGradient = GradientView(
            colors: [WritingStyle.blue, WritingStyle.pink],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        buttonGradient.isUserInteractionEnabled = false
        generateButton.insertSubview(buttonGradient, at: 0)
        buttonGradient.pinToSuperviewEdges()

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 64),
            icon.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 17),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 40),

            inputContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 13),
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            inputContainer.heightAnchor.constraint(equalToConstant: 160),

            textView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 25),
            textView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: counterLabel.topAnchor, constant: -8),

            counterLabel.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            counterLabel.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -16),

            optionsGrid.topAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: 28),
            optionsGrid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsGrid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            translateRow.topAnchor.constraint(equalTo: optionsGrid.bottomAnchor, constant: 16),
            translateRow.leadingAnchor.constraint(equalTo: optionsGrid.leadingAnchor),
            translateRow.trailingAnchor.constraint(equalTo: optionsGrid.trailingAnchor),
            translateRow.heightAnchor.constraint(equalToConstant: 60),

            styleRow.topAnchor.constraint(equalTo: translateRow.bottomAnchor, constant: 8),
            styleRow.leadingAnchor.constraint(equalTo: optionsGrid.leadingAnchor),
            styleRow.trailingAnchor.constraint(equalTo: optionsGrid.trailingAnchor),
            styleRow.heightAnchor.constraint(equalToConstant: 60),

            generateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            generateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            generateButton.topAnchor.constraint(greaterThanOrEqualTo: styleRow.bottomAnchor, constant: 18)
        ])
    }

    private func setupDismissKeyboardButton() {
        dismissKeyboardButton.setTitle("Hide keyboard", for: .normal)
        dismissKeyboardButton.setTitleColor(.white, for: .normal)
        dismissKeyboardButton.titleLabel?.font = WritingStyle.font(size: 15, weight: .semibold)
        dismissKeyboardButton.backgroundColor = WritingStyle.card.withAlphaComponent(0.98)
        dismissKeyboardButton.layer.cornerRadius = 20
        dismissKeyboardButton.layer.borderColor = WritingStyle.fieldBorder.cgColor
        dismissKeyboardButton.layer.borderWidth = 1
        dismissKeyboardButton.alpha = 0
        dismissKeyboardButton.isHidden = true
        dismissKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        dismissKeyboardButton.addTarget(self, action: #selector(hideKeyboardTapped), for: .touchUpInside)
        view.addSubview(dismissKeyboardButton)

        dismissKeyboardBottomConstraint = dismissKeyboardButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -12
        )
        NSLayoutConstraint.activate([
            dismissKeyboardButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissKeyboardButton.widthAnchor.constraint(equalToConstant: 154),
            dismissKeyboardButton.heightAnchor.constraint(equalToConstant: 42),
            dismissKeyboardBottomConstraint
        ])
    }

    private func makeOptionButton(_ title: String) -> WritingOptionButton {
        let button = WritingOptionButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WritingStyle.font(size: 16, weight: .medium)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.backgroundColor = WritingStyle.card
        button.layer.cornerRadius = 24
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makePickerRow(
        title: String,
        valueLabel: UILabel,
        initialValue: String,
        selector: Selector
    ) -> UIView {
        let row = UIView()
        row.backgroundColor = WritingStyle.card
        row.layer.cornerRadius = 24
        row.translatesAutoresizingMaskIntoConstraints = false
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = WritingStyle.secondaryText
        titleLabel.font = WritingStyle.font(size: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(titleLabel)

        valueLabel.text = initialValue
        valueLabel.textColor = .white
        valueLabel.font = WritingStyle.font(size: 16, weight: .medium)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(valueLabel)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = WritingStyle.dimText
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(chevron)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -18),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 15),
            chevron.heightAnchor.constraint(equalToConstant: 9),
            valueLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -24),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    private func presentSelection(
        title: String,
        options: [String],
        selectedValue: String?,
        onSelect: @escaping (String) -> Void
    ) {
        view.endEditing(true)
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        options.forEach { option in
            let suffix = option == selectedValue ? " ✓" : ""
            alert.addAction(UIAlertAction(title: option + suffix, style: .default) { _ in onSelect(option) })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 120, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    private func selectOption(_ button: WritingOptionButton) {
        selectedActionButton?.isSelectedStyle = false
        selectedActionButton = button
        button.isSelectedStyle = true
    }

    private func updateCounter() {
        counterLabel.text = "\(textView.text.count)/400"
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func showDismissKeyboardButton(_ isVisible: Bool) {
        if isVisible { dismissKeyboardButton.isHidden = false }
        UIView.animate(withDuration: 0.18, animations: {
            self.dismissKeyboardButton.alpha = isVisible ? 1 : 0
        }, completion: { _ in
            self.dismissKeyboardButton.isHidden = !isVisible
        })
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY - view.safeAreaInsets.bottom)
        dismissKeyboardBottomConstraint.constant = -overlap - 12
        showDismissKeyboardButton(true)
        animateKeyboardLayout(notification)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        dismissKeyboardBottomConstraint.constant = -12
        showDismissKeyboardButton(false)
        animateKeyboardLayout(notification)
    }

    private func animateKeyboardLayout(_ notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func optionTapped(_ sender: WritingOptionButton) {
        selectOption(sender)
    }

    @objc private func languageTapped() {
        presentSelection(title: "Translate", options: languages, selectedValue: languageValueLabel.text) { [weak self] value in
            self?.languageValueLabel.text = value
        }
    }

    @objc private func styleTapped() {
        presentSelection(title: "Style", options: styles, selectedValue: styleValueLabel.text) { [weak self] value in
            self?.styleValueLabel.text = value
        }
    }

    @objc private func refreshTapped() {
        textView.text = ""
        languageValueLabel.text = "Spanish"
        styleValueLabel.text = "Original"
        if let fixGrammar = optionButtons.first(where: { $0.currentTitle == "Fix grammar" }) {
            selectOption(fixGrammar)
        }
        updateCounter()
    }

    @objc private func hideKeyboardTapped() {
        view.endEditing(true)
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func generateTapped() {
        let text = textView.text ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        view.endEditing(true)
        let selectedAction = selectedActionButton?.currentTitle
        let request = AIWritingRequestModel(
            text: text,
            improve: selectedAction == "Improve",
            rewrite: selectedAction == "Rewrite",
            fixGrammar: selectedAction == "Fix grammar",
            shorten: selectedAction == "Shorten",
            translateTo: languageCode(for: languageValueLabel.text),
            style: styleValueLabel.text?.lowercased()
        )
        onGenerate?(request)
    }

    private func languageCode(for language: String?) -> String? {
        switch language {
        case "English": return "en"
        case "Spanish": return "es"
        case "French": return "fr"
        case "German": return "de"
        case "Russian": return "ru"
        default: return nil
        }
    }
}

extension AIWritingViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 400 {
            textView.text = String(textView.text.prefix(400))
        }
        updateCounter()
    }
}

private final class WritingOptionButton: UIButton {
    private let gradient = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    var isSelectedStyle = false {
        didSet {
            gradient.isHidden = !isSelectedStyle
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.colors = [WritingStyle.blue.cgColor, WritingStyle.pink.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.mask = borderMask
        gradient.isHidden = true
        layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        borderMask.frame = bounds
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        borderMask.lineWidth = 2
        borderMask.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 23).cgPath
    }
}

private final class GradientTextLabel: UILabel {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [WritingStyle.blue.cgColor, WritingStyle.pink.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        let mask = CATextLayer()
        mask.string = text
        mask.font = font
        mask.fontSize = font.pointSize
        mask.alignmentMode = .right
        mask.contentsScale = UIScreen.main.scale
        mask.frame = bounds
        gradient.mask = mask
    }
}

private enum WritingStyle {
    static let background = UIColor(red: 11 / 255, green: 7 / 255, blue: 14 / 255, alpha: 1)
    static let card = UIColor(red: 22 / 255, green: 16 / 255, blue: 24 / 255, alpha: 1)
    static let fieldBorder = UIColor(red: 76 / 255, green: 62 / 255, blue: 82 / 255, alpha: 1)
    static let secondaryText = UIColor(red: 157 / 255, green: 151 / 255, blue: 160 / 255, alpha: 1)
    static let dimText = UIColor(red: 71 / 255, green: 65 / 255, blue: 74 / 255, alpha: 1)
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
