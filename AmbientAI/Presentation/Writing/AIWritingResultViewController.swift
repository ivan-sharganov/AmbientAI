import UIKit

final class AIWritingResultViewController: UIViewController {
    var onClose: (() -> Void)?

    private let viewModel: AIWritingResultViewModel
    private let resultTextView = UITextView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let copyButton = UIButton(type: .system)
    private let retryButton = UIButton(type: .system)
    private var resultText: String?

    init(viewModel: AIWritingResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        viewModel.viewDidLoad()
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background
        let background = GradientView(
            colors: [UIColor(red: 0.16, green: 0.10, blue: 0.19, alpha: 1), DesignSystem.Color.background],
            startPoint: CGPoint(x: 0.7, y: 0),
            endPoint: CGPoint(x: 0.2, y: 1)
        )
        view.addSubview(background)
        background.pinToSuperviewEdges()

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "AI Writing Result"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let sourceCard = makeTextCard(title: "Original", text: viewModel.request.text, isScrollable: true)
        let resultCard = makeResultCard()
        view.addSubview(sourceCard)
        view.addSubview(resultCard)

        configureActionButton(copyButton, title: "Copy", symbol: "doc.on.doc")
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        copyButton.isEnabled = false
        copyButton.alpha = 0.45

        configureActionButton(retryButton, title: "Try again", symbol: "arrow.clockwise")
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        let actions = UIStackView(axis: .horizontal, spacing: 12, distribution: .fillEqually)
        actions.addArrangedSubview(copyButton)
        actions.addArrangedSubview(retryButton)
        view.addSubview(actions)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            backButton.widthAnchor.constraint(equalToConstant: 42),
            backButton.heightAnchor.constraint(equalToConstant: 42),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            sourceCard.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 28),
            sourceCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sourceCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            sourceCard.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.27),

            resultCard.topAnchor.constraint(equalTo: sourceCard.bottomAnchor, constant: 18),
            resultCard.leadingAnchor.constraint(equalTo: sourceCard.leadingAnchor),
            resultCard.trailingAnchor.constraint(equalTo: sourceCard.trailingAnchor),
            resultCard.bottomAnchor.constraint(equalTo: actions.topAnchor, constant: -20),

            actions.leadingAnchor.constraint(equalTo: sourceCard.leadingAnchor),
            actions.trailingAnchor.constraint(equalTo: sourceCard.trailingAnchor),
            actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            actions.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func makeTextCard(title: String, text: String, isScrollable: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = DesignSystem.Color.backgroundElevated.withAlphaComponent(0.9)
        card.layer.cornerRadius = 22
        card.layer.borderWidth = 1
        card.layer.borderColor = DesignSystem.Color.border.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.textColor = DesignSystem.Color.lavender
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)

        let textView = UITextView()
        textView.text = text
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = isScrollable
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textView)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
        return card
    }

    private func makeResultCard() -> UIView {
        let card = UIView()
        card.backgroundColor = DesignSystem.Color.backgroundElevated.withAlphaComponent(0.9)
        card.layer.cornerRadius = 22
        card.layer.borderWidth = 1
        card.layer.borderColor = DesignSystem.Color.pink.withAlphaComponent(0.55).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Result"
        label.textColor = DesignSystem.Color.pink
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)

        resultTextView.textColor = .white
        resultTextView.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        resultTextView.backgroundColor = .clear
        resultTextView.isEditable = false
        resultTextView.isSelectable = true
        resultTextView.textContainerInset = .zero
        resultTextView.textContainer.lineFragmentPadding = 0
        resultTextView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(resultTextView)

        loadingIndicator.color = DesignSystem.Color.lavender
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(loadingIndicator)

        errorLabel.textColor = DesignSystem.Color.pink
        errorLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),

            resultTextView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            resultTextView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            resultTextView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            resultTextView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),

            loadingIndicator.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            errorLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24)
        ])
        return card
    }

    private func configureActionButton(_ button: UIButton, title: String, symbol: String) {
        button.setTitle("  \(title)", for: .normal)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = DesignSystem.Color.card
        button.layer.cornerRadius = 20
    }

    private func render(_ state: AIWritingResultState) {
        switch state {
        case .loading:
            resultText = nil
            resultTextView.text = nil
            resultTextView.isHidden = true
            errorLabel.isHidden = true
            loadingIndicator.startAnimating()
            copyButton.isEnabled = false
            copyButton.alpha = 0.45
            retryButton.isEnabled = false
            retryButton.alpha = 0.45

        case let .loaded(text):
            resultText = text
            resultTextView.text = text
            resultTextView.isHidden = false
            errorLabel.isHidden = true
            loadingIndicator.stopAnimating()
            copyButton.isEnabled = true
            copyButton.alpha = 1
            retryButton.isEnabled = true
            retryButton.alpha = 1

        case let .error(message):
            resultText = nil
            resultTextView.isHidden = true
            errorLabel.text = message
            errorLabel.isHidden = false
            loadingIndicator.stopAnimating()
            copyButton.isEnabled = false
            copyButton.alpha = 0.45
            retryButton.isEnabled = true
            retryButton.alpha = 1
        }
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func copyTapped() {
        guard let resultText else { return }
        UIPasteboard.general.string = resultText
        copyButton.setTitle("  Copied", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.copyButton.setTitle("  Copy", for: .normal)
        }
    }

    @objc private func retryTapped() {
        viewModel.generate()
    }
}
