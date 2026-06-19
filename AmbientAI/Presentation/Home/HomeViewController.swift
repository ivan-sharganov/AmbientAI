import UIKit

final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let promptField = UITextField()

    init(viewModel: HomeViewModel) {
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
        viewModel.onStateChange = { _ in }
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background

        let background = GradientView(colors: [UIColor(red: 0.16, green: 0.10, blue: 0.21, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        let content = UIStackView(axis: .vertical, spacing: 22, alignment: .fill)
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 34),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        let settingsButton = IconButton(systemName: "gearshape", pointSize: 15)
        settingsButton.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
        view.addSubview(settingsButton)
        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])

        let paywallButton = UIButton(type: .system)
        paywallButton.setTitle("PRO", for: .normal)
        paywallButton.setTitleColor(.white, for: .normal)
        paywallButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        paywallButton.backgroundColor = DesignSystem.Color.pink
        paywallButton.layer.cornerRadius = 18
        paywallButton.addTarget(self, action: #selector(paywallTapped), for: .touchUpInside)
        paywallButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paywallButton)
        NSLayoutConstraint.activate([
            paywallButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            paywallButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            paywallButton.widthAnchor.constraint(equalToConstant: 58),
            paywallButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        let heroIcon = UIImageView(image: UIImage(systemName: "sparkles"))
        heroIcon.tintColor = DesignSystem.Color.pink
        heroIcon.contentMode = .scaleAspectFit
        heroIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heroIcon.widthAnchor.constraint(equalToConstant: 54),
            heroIcon.heightAnchor.constraint(equalToConstant: 54)
        ])

        let title = UILabel()
        title.text = "Your AI tools,\nready to go"
        title.textColor = .white
        title.font = DesignSystem.Font.title
        title.textAlignment = .center
        title.numberOfLines = 2

        let heroStack = UIStackView(axis: .vertical, spacing: 16, alignment: .center)
        heroStack.addArrangedSubview(heroIcon)
        heroStack.addArrangedSubview(title)
        content.addArrangedSubview(heroStack)

        promptField.attributedPlaceholder = NSAttributedString(string: "Ask anything...", attributes: [.foregroundColor: DesignSystem.Color.secondaryText])
        promptField.textColor = .white
        promptField.font = DesignSystem.Font.body
        promptField.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        promptField.layer.cornerRadius = 18
        promptField.layer.borderColor = DesignSystem.Color.border.cgColor
        promptField.layer.borderWidth = 1
        promptField.leftView = makePromptIcon()
        promptField.leftViewMode = .always
        promptField.returnKeyType = .send
        promptField.delegate = self
        promptField.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(promptField)
        promptField.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let promptTap = UITapGestureRecognizer(target: self, action: #selector(promptTapped))
        promptField.addGestureRecognizer(promptTap)

        let featureGrid = makeFeatureGrid()
        content.addArrangedSubview(featureGrid)
        featureGrid.heightAnchor.constraint(equalToConstant: 246).isActive = true
    }

    private func makeFeatureGrid() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let videoCard = makeLargeFeatureCard(
            title: "Turn Photo\ninto Video",
            subtitle: "Animate • Templates",
            icon: "camera.filters",
            selector: #selector(photoTapped)
        )
        let writingCard = makeSmallFeatureCard(
            title: "Fix & Improve\nWriting",
            subtitle: "Rewrite • Fix grammar",
            icon: "wand.and.stars",
            selector: #selector(writingTapped)
        )
        let summaryCard = makeSmallFeatureCard(
            title: "Understand\nFaster",
            subtitle: "Summarize • Key points",
            icon: "text.badge.checkmark",
            selector: #selector(summaryTapped)
        )

        container.addSubview(videoCard)
        container.addSubview(writingCard)
        container.addSubview(summaryCard)

        NSLayoutConstraint.activate([
            videoCard.topAnchor.constraint(equalTo: container.topAnchor),
            videoCard.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            videoCard.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            videoCard.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.49),

            writingCard.topAnchor.constraint(equalTo: container.topAnchor),
            writingCard.leadingAnchor.constraint(equalTo: videoCard.trailingAnchor, constant: 10),
            writingCard.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            writingCard.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.48),

            summaryCard.leadingAnchor.constraint(equalTo: writingCard.leadingAnchor),
            summaryCard.trailingAnchor.constraint(equalTo: writingCard.trailingAnchor),
            summaryCard.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            summaryCard.heightAnchor.constraint(equalTo: writingCard.heightAnchor)
        ])
        return container
    }

    private func makePromptIcon() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 42, height: 42))
        let imageView = UIImageView(image: UIImage(systemName: "sparkles"))
        imageView.tintColor = .white
        imageView.frame = CGRect(x: 14, y: 13, width: 16, height: 16)
        container.addSubview(imageView)
        return container
    }

    private func makeLargeFeatureCard(title: String, subtitle: String, icon: String, selector: Selector) -> UIView {
        let card = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
        card.layer.cornerRadius = 18
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(axis: .vertical, spacing: 8, alignment: .leading)
        card.addSubview(stack)
        stack.pinToSuperviewEdges(insets: UIEdgeInsets(top: 18, left: 16, bottom: 14, right: 16))

        stack.addArrangedSubview(makeCardIcon(systemName: icon))
        stack.addArrangedSubview(makeTitleLabel(title, font: DesignSystem.Font.bodySemibold))
        stack.addArrangedSubview(makeSubtitleLabel(subtitle))
        stack.addArrangedSubview(UIView())

        let pill = UILabel()
        pill.text = "Ready in seconds  ▶"
        pill.textColor = .white
        pill.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        pill.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        pill.textAlignment = .center
        pill.layer.cornerRadius = 13
        pill.layer.masksToBounds = true
        pill.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(pill)
        NSLayoutConstraint.activate([
            pill.widthAnchor.constraint(equalToConstant: 128),
            pill.heightAnchor.constraint(equalToConstant: 28)
        ])

        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))
        return card
    }

    private func makeSmallFeatureCard(title: String, subtitle: String, icon: String, selector: Selector) -> UIView {
        let card = UIView()
        card.backgroundColor = DesignSystem.Color.backgroundElevated
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false

        let iconView = makeCardIcon(systemName: icon)
        let titleLabel = makeTitleLabel(title, font: UIFont.systemFont(ofSize: 16, weight: .semibold))
        let subtitleLabel = makeSubtitleLabel(subtitle)

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 16),

            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -6),
            titleLabel.heightAnchor.constraint(equalToConstant: 40)
        ])

        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))
        return card
    }

    private func makeCardIcon(systemName: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 32),
            container.heightAnchor.constraint(equalToConstant: 32)
        ])

        let imageView = UIImageView(image: UIImage(systemName: systemName))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 18)
        ])
        return container
    }

    private func makeTitleLabel(_ text: String, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = font
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        return label
    }

    private func makeSubtitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.white.withAlphaComponent(0.62)
        label.font = DesignSystem.Font.caption
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }

    @objc private func promptTapped() {
        viewModel.startChat(prompt: promptField.text)
    }

    @objc private func photoTapped() {
        viewModel.openVideoTemplates()
    }

    @objc private func writingTapped() {
        viewModel.openWriting()
    }

    @objc private func summaryTapped() {
        viewModel.startChat(prompt: "Summarize key points")
    }

    @objc private func openHistory() {
        viewModel.openHistory()
    }

    @objc private func paywallTapped() {
        viewModel.openPaywall()
    }
}

extension HomeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.startChat(prompt: textField.text)
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        viewModel.startChat(prompt: textField.text)
        return false
    }
}
