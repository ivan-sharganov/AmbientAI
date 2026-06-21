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
        viewModel.onApphudLogout = { [weak self] userID, isPremium in
            let alert = UIAlertController(
                title: "Apphud user changed",
                message: "New user_id: \(userID)\nPremium: \(isPremium)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func setupUI() {
        view.backgroundColor = HomeStyle.background
        addBackgroundGlows()

        let hero = makeHero()
        let featureGrid = makeFeatureGrid()
        let content = UIStackView(axis: .vertical, spacing: 40, alignment: .fill)
        content.addArrangedSubview(hero)
        content.addArrangedSubview(featureGrid)
        view.addSubview(content)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            content.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            featureGrid.heightAnchor.constraint(equalToConstant: 313)
        ])

        let settingsButton = UIButton(type: .custom)
        settingsButton.backgroundColor = HomeStyle.card.withAlphaComponent(0.4)
        settingsButton.layer.cornerRadius = 20
        settingsButton.layer.cornerCurve = .continuous
        settingsButton.setImage(UIImage(named: "HomeSettingsIcon"), for: .normal)
        settingsButton.imageView?.contentMode = .scaleAspectFit
        settingsButton.imageView?.alpha = 0.3
        settingsButton.isUserInteractionEnabled = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)
        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40)
        ])

#if DEBUG
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("logout apphud", for: .normal)
        logoutButton.setTitleColor(UIColor.white.withAlphaComponent(0.18), for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular)
        logoutButton.addTarget(self, action: #selector(logoutApphudTapped), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            logoutButton.widthAnchor.constraint(equalToConstant: 90),
            logoutButton.heightAnchor.constraint(equalToConstant: 32)
        ])
#endif
    }

    private func addBackgroundGlows() {
        let top = makeGlow(named: "HomeGlowTop", alpha: 1)
        let left = makeGlow(named: "HomeGlowLeft", alpha: 1)
        let right = makeGlow(named: "HomeGlowRight", alpha: 1)
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

    private func makeGlow(named name: String, alpha: CGFloat) -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: name))
        imageView.alpha = alpha
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }

    private func makeHero() -> UIView {
        let heroIcon = UIImageView(image: UIImage(named: "HomeHeroIcon"))
        heroIcon.contentMode = .scaleAspectFit
        heroIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heroIcon.widthAnchor.constraint(equalToConstant: 60),
            heroIcon.heightAnchor.constraint(equalToConstant: 60)
        ])

        let title = UILabel()
        title.text = "Your AI tools,\nready to go"
        title.textColor = .white
        title.font = HomeStyle.font(size: 28, weight: .bold)
        title.textAlignment = .center
        title.numberOfLines = 2
        title.setContentHuggingPriority(.required, for: .vertical)

        let prompt = HomePromptView(textField: promptField)
        promptField.attributedPlaceholder = NSAttributedString(
            string: "Ask anything...",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.5),
                .font: HomeStyle.font(size: 16, weight: .regular)
            ]
        )
        promptField.textColor = .white
        promptField.font = HomeStyle.font(size: 16, weight: .regular)
        promptField.returnKeyType = .send
        promptField.delegate = self
        promptField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(promptTapped)))

        let hero = UIStackView(axis: .vertical, spacing: 24, alignment: .center)
        hero.addArrangedSubview(heroIcon)
        hero.addArrangedSubview(title)
        hero.addArrangedSubview(prompt)
        NSLayoutConstraint.activate([
            prompt.leadingAnchor.constraint(equalTo: hero.leadingAnchor),
            prompt.trailingAnchor.constraint(equalTo: hero.trailingAnchor),
            prompt.heightAnchor.constraint(equalToConstant: 56)
        ])
        return hero
    }

    private func makeFeatureGrid() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let videoCard = makeVideoCard()
        let writingCard = makeSmallFeatureCard(
            title: "Fix & Improve\nWriting",
            subtitle: "Rewrite  •  Fix grammar",
            icon: "HomeWritingIcon",
            selector: #selector(writingTapped)
        )
        let summaryCard = makeSmallFeatureCard(
            title: "Understand\nFaster",
            subtitle: "Summarize  •  Key points",
            icon: "HomeSummaryIcon",
            selector: #selector(summaryTapped)
        )

        container.addSubview(videoCard)
        container.addSubview(writingCard)
        container.addSubview(summaryCard)
        NSLayoutConstraint.activate([
            videoCard.topAnchor.constraint(equalTo: container.topAnchor),
            videoCard.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            videoCard.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            videoCard.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 172 / 358),

            writingCard.topAnchor.constraint(equalTo: container.topAnchor),
            writingCard.leadingAnchor.constraint(equalTo: videoCard.trailingAnchor, constant: 8),
            writingCard.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            writingCard.heightAnchor.constraint(equalToConstant: 152.5),

            summaryCard.leadingAnchor.constraint(equalTo: writingCard.leadingAnchor),
            summaryCard.trailingAnchor.constraint(equalTo: writingCard.trailingAnchor),
            summaryCard.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            summaryCard.heightAnchor.constraint(equalToConstant: 152.5)
        ])
        return container
    }

    private func makeVideoCard() -> UIView {
        let card = GradientView(
            colors: [HomeStyle.blue.withAlphaComponent(0.8), HomeStyle.pink.withAlphaComponent(0.8)],
            startPoint: CGPoint(x: 0.06, y: 0),
            endPoint: CGPoint(x: 0.94, y: 1)
        )
        card.layer.cornerRadius = 24
        card.layer.cornerCurve = .continuous
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let texture = UIImageView(image: UIImage(named: "HomeVideoTexture"))
        texture.contentMode = .scaleAspectFill
        texture.alpha = 0.5
        texture.transform = CGAffineTransform(translationX: 0, y: 42)
        texture.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(texture)
        NSLayoutConstraint.activate([
            texture.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            texture.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            texture.topAnchor.constraint(equalTo: card.topAnchor),
            texture.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        let icon = makeIconBadge(named: "HomeVideoIcon", backgroundAlpha: 0.15)
        let title = makeLabel("Turn Photo\ninto Video", size: 20, weight: .medium, alpha: 1)
        let subtitle = makeLabel("Animate  •  Templates", size: 14, weight: .regular, alpha: 0.7)
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.8

        let header = UIStackView(axis: .vertical, spacing: 12, alignment: .leading)
        header.addArrangedSubview(icon)
        header.addArrangedSubview(title)
        header.addArrangedSubview(subtitle)
        card.addSubview(header)

        let ready = HomeReadyPill()
        card.addSubview(ready)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),

            ready.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            ready.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -11),
            ready.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            ready.heightAnchor.constraint(equalToConstant: 32)
        ])

        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(photoTapped)))
        return card
    }

    private func makeSmallFeatureCard(
        title: String,
        subtitle: String,
        icon: String,
        selector: Selector
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = HomeStyle.card.withAlphaComponent(0.7)
        card.layer.cornerRadius = 24
        card.layer.cornerCurve = .continuous
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let iconView = makeIconBadge(named: icon, backgroundAlpha: 0.05)
        let titleLabel = makeLabel(title, size: 16, weight: .medium, alpha: 1)
        let subtitleLabel = makeLabel(subtitle, size: 12, weight: .medium, alpha: 0.5)
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.76

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))
        return card
    }

    private func makeIconBadge(named name: String, backgroundAlpha: CGFloat) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(backgroundAlpha)
        container.layer.cornerRadius = 18
        container.layer.cornerCurve = .continuous
        container.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(named: name))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 36),
            container.heightAnchor.constraint(equalToConstant: 36),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        return container
    }

    private func makeLabel(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight,
        alpha: CGFloat
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.white.withAlphaComponent(alpha)
        label.font = HomeStyle.font(size: size, weight: weight)
        label.numberOfLines = text.contains("\n") ? 2 : 1
        label.translatesAutoresizingMaskIntoConstraints = false
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

#if DEBUG
    @objc private func logoutApphudTapped() {
        viewModel.logoutApphudUser()
    }
#endif
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

private final class HomePromptView: UIView {
    private let border = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    init(textField: UITextField) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = HomeStyle.card.withAlphaComponent(0.7)
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        border.colors = [HomeStyle.blue.cgColor, HomeStyle.pink.withAlphaComponent(0.35).cgColor]
        border.startPoint = CGPoint(x: 0, y: 0.5)
        border.endPoint = CGPoint(x: 1, y: 0.5)
        border.mask = borderMask
        layer.addSublayer(border)
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        borderMask.lineWidth = 1

        let icon = UIImageView(image: UIImage(named: "HomePromptIcon"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(icon)
        addSubview(textField)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            textField.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.frame = bounds
        borderMask.frame = bounds
        borderMask.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: 23.5
        ).cgPath
    }
}

private final class HomeReadyPill: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white.withAlphaComponent(0.3)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous

        let label = UILabel()
        label.text = "Ready in seconds"
        label.textColor = .white
        label.font = HomeStyle.font(size: 12, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false

        let play = UIImageView(image: UIImage(systemName: "play.fill"))
        play.tintColor = .white
        play.contentMode = .scaleAspectFit
        play.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        addSubview(play)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            play.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            play.centerYAnchor.constraint(equalTo: centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 12),
            play.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum HomeStyle {
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
