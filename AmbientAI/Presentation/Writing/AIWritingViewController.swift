import UIKit

final class AIWritingViewController: UIViewController {
    var onClose: (() -> Void)?
    var onGenerate: ((AIWritingRequestModel) -> Void)?

    private let textView = UITextView()
    private let counterLabel = UILabel()
    private let generateButton = UIButton(type: .system)
    private let dismissKeyboardButton = UIButton(type: .system)
    private let languageValueLabel = UILabel()
    private let styleValueLabel = UILabel()
    private let languages = ["English", "Spanish", "French", "German", "Russian"]
    private let styles = ["Formal", "Cherish", "Friendly", "Academic", "Sales"]
    private var selectedActionButton: UIButton?
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
        view.backgroundColor = DesignSystem.Color.background

        let background = GradientView(colors: [UIColor(red: 0.16, green: 0.10, blue: 0.19, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.7, y: 0), endPoint: CGPoint(x: 0.2, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        setupHeader()
        setupContent()
        setupDismissKeyboardButton()
    }

    private func setupHeader() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)

        let refreshButton = UIButton(type: .system)
        refreshButton.setImage(UIImage(systemName: "sparkles.square.filled.on.square"), for: .normal)
        refreshButton.tintColor = .white
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(refreshButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            backButton.widthAnchor.constraint(equalToConstant: 42),
            backButton.heightAnchor.constraint(equalToConstant: 42),

            refreshButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            refreshButton.widthAnchor.constraint(equalToConstant: 42),
            refreshButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    private func setupContent() {
        let icon = UIImageView(image: UIImage(systemName: "wand.and.stars.inverse"))
        icon.tintColor = DesignSystem.Color.pink
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = "AI Writing"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let inputContainer = UIView()
        inputContainer.backgroundColor = DesignSystem.Color.backgroundElevated.withAlphaComponent(0.82)
        inputContainer.layer.cornerRadius = 24
        inputContainer.layer.borderColor = DesignSystem.Color.border.cgColor
        inputContainer.layer.borderWidth = 1
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)

        textView.text = "I am writing to inform you that the project deadline has been moved to next Friday. Please adjust your schedule accordingly and let me"
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = DesignSystem.Color.pink
        textView.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(textView)

        counterLabel.textColor = DesignSystem.Color.mutedText
        counterLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(counterLabel)

        let optionsGrid = UIStackView(axis: .vertical, spacing: 12)
        view.addSubview(optionsGrid)

        let row1 = UIStackView(axis: .horizontal, spacing: 12, distribution: .fillEqually)
        let improve = makeOptionButton("Improve")
        let rewrite = makeOptionButton("Rewrite")
        row1.addArrangedSubview(improve)
        row1.addArrangedSubview(rewrite)

        let row2 = UIStackView(axis: .horizontal, spacing: 12, distribution: .fillEqually)
        let fixGrammar = makeOptionButton("Fix grammar")
        let shorten = makeOptionButton("Shorten")
        row2.addArrangedSubview(fixGrammar)
        row2.addArrangedSubview(shorten)

        optionsGrid.addArrangedSubview(row1)
        optionsGrid.addArrangedSubview(row2)
        [improve, rewrite, fixGrammar, shorten].forEach { $0.heightAnchor.constraint(equalToConstant: 62).isActive = true }
        selectOption(fixGrammar)

        let translateRow = makePickerRow(title: "Translate", valueLabel: languageValueLabel, initialValue: "Spanish", selector: #selector(languageTapped))
        let styleRow = makePickerRow(title: "Style", valueLabel: styleValueLabel, initialValue: "Formal", selector: #selector(styleTapped))
        view.addSubview(translateRow)
        view.addSubview(styleRow)

        generateButton.setTitle("Generate", for: .normal)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        generateButton.layer.cornerRadius = 28
        generateButton.layer.masksToBounds = true
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(generateButton)

        let buttonGradient = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink])
        buttonGradient.isUserInteractionEnabled = false
        generateButton.insertSubview(buttonGradient, at: 0)
        buttonGradient.pinToSuperviewEdges()

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 72),
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 70),
            icon.heightAnchor.constraint(equalToConstant: 70),

            titleLabel.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 18),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            inputContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            inputContainer.heightAnchor.constraint(equalToConstant: 184),

            textView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 18),
            textView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -18),
            textView.bottomAnchor.constraint(equalTo: counterLabel.topAnchor, constant: -6),

            counterLabel.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -22),
            counterLabel.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -16),

            optionsGrid.topAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: 24),
            optionsGrid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            optionsGrid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            translateRow.topAnchor.constraint(equalTo: optionsGrid.bottomAnchor, constant: 18),
            translateRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            translateRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            translateRow.heightAnchor.constraint(equalToConstant: 62),

            styleRow.topAnchor.constraint(equalTo: translateRow.bottomAnchor, constant: 12),
            styleRow.leadingAnchor.constraint(equalTo: translateRow.leadingAnchor),
            styleRow.trailingAnchor.constraint(equalTo: translateRow.trailingAnchor),
            styleRow.heightAnchor.constraint(equalToConstant: 62),

            generateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            generateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            generateButton.topAnchor.constraint(equalTo: styleRow.bottomAnchor, constant: 28),
            generateButton.heightAnchor.constraint(equalToConstant: 58),
            generateButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22)
        ])
    }

    private func setupDismissKeyboardButton() {
        dismissKeyboardButton.setTitle("Hide keyboard", for: .normal)
        dismissKeyboardButton.setTitleColor(.white, for: .normal)
        dismissKeyboardButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        dismissKeyboardButton.backgroundColor = DesignSystem.Color.backgroundElevated.withAlphaComponent(0.96)
        dismissKeyboardButton.layer.cornerRadius = 20
        dismissKeyboardButton.layer.borderColor = DesignSystem.Color.border.cgColor
        dismissKeyboardButton.layer.borderWidth = 1
        dismissKeyboardButton.alpha = 0
        dismissKeyboardButton.isHidden = true
        dismissKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        dismissKeyboardButton.addTarget(self, action: #selector(hideKeyboardTapped), for: .touchUpInside)
        view.addSubview(dismissKeyboardButton)

        dismissKeyboardBottomConstraint = dismissKeyboardButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)

        NSLayoutConstraint.activate([
            dismissKeyboardButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissKeyboardButton.widthAnchor.constraint(equalToConstant: 154),
            dismissKeyboardButton.heightAnchor.constraint(equalToConstant: 42),
            dismissKeyboardBottomConstraint
        ])
    }

    private func makeOptionButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
        button.backgroundColor = DesignSystem.Color.backgroundElevated
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.clear.cgColor
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makePickerRow(title: String, valueLabel: UILabel, initialValue: String, selector: Selector) -> UIView {
        let row = UIView()
        row.backgroundColor = DesignSystem.Color.backgroundElevated
        row.layer.cornerRadius = 22
        row.translatesAutoresizingMaskIntoConstraints = false
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = DesignSystem.Color.secondaryText
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(titleLabel)

        valueLabel.text = initialValue
        valueLabel.textColor = DesignSystem.Color.lavender
        valueLabel.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(valueLabel)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = DesignSystem.Color.secondaryText
        chevron.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(chevron)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 22),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -22),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -18),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }


    private func presentSelection(title: String, options: [String], selectedValue: String?, onSelect: @escaping (String) -> Void) {
        view.endEditing(true)
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        options.forEach { option in
            let suffix = option == selectedValue ? " ✓" : ""
            alert.addAction(UIAlertAction(title: option + suffix, style: .default) { _ in
                onSelect(option)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 120, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func selectOption(_ button: UIButton) {
        selectedActionButton?.layer.borderColor = UIColor.clear.cgColor
        selectedActionButton?.backgroundColor = DesignSystem.Color.backgroundElevated
        selectedActionButton = button
        button.backgroundColor = UIColor.white.withAlphaComponent(0.03)
        button.layer.borderColor = DesignSystem.Color.pink.cgColor
    }

    private func updateCounter() {
        counterLabel.text = "\(textView.text.count)/400"
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func showDismissKeyboardButton(_ isVisible: Bool) {
        if isVisible {
            dismissKeyboardButton.isHidden = false
        }
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

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        dismissKeyboardBottomConstraint.constant = -12
        showDismissKeyboardButton(false)

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func optionTapped(_ sender: UIButton) {
        selectOption(sender)
    }

    @objc private func languageTapped() {
        presentSelection(title: "Translate", options: languages, selectedValue: languageValueLabel.text) { [weak self] language in
            self?.languageValueLabel.text = language
        }
    }

    @objc private func styleTapped() {
        presentSelection(title: "Style", options: styles, selectedValue: styleValueLabel.text) { [weak self] style in
            self?.styleValueLabel.text = style
        }
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
