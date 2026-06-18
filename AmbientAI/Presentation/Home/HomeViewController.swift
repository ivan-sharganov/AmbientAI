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

        let tap = UITapGestureRecognizer(target: self, action: #selector(promptTapped))
        promptField.addGestureRecognizer(tap)

        let cards = UIStackView(axis: .horizontal, spacing: 12, alignment: .fill, distribution: .fillEqually)
        cards.addArrangedSubview(makeFeatureCard(title: "Turn Photo\ninto Video", subtitle: "Animate • Templates", icon: "camera.filters"))
        cards.addArrangedSubview(makeFeatureCard(title: "Pix & Improve\nWriting", subtitle: "Rewrite • Fix grammar", icon: "wand.and.stars"))
        content.addArrangedSubview(cards)
        cards.heightAnchor.constraint(equalToConstant: 190).isActive = true
    }

    private func makePromptIcon() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 42, height: 42))
        let imageView = UIImageView(image: UIImage(systemName: "sparkles"))
        imageView.tintColor = .white
        imageView.frame = CGRect(x: 14, y: 13, width: 16, height: 16)
        container.addSubview(imageView)
        return container
    }

    private func makeFeatureCard(title: String, subtitle: String, icon: String) -> UIView {
        let card = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1))
        card.layer.cornerRadius = 18
        card.layer.masksToBounds = true

        let stack = UIStackView(axis: .vertical, spacing: 8, alignment: .leading)
        card.addSubview(stack)
        stack.pinToSuperviewEdges(insets: UIEdgeInsets(top: 18, left: 16, bottom: 14, right: 16))

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])
        stack.addArrangedSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = DesignSystem.Font.bodySemibold
        titleLabel.numberOfLines = 2
        stack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.74)
        subtitleLabel.font = DesignSystem.Font.caption
        stack.addArrangedSubview(subtitleLabel)

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

        let tap = UITapGestureRecognizer(target: self, action: #selector(promptTapped))
        card.addGestureRecognizer(tap)
        return card
    }

    @objc private func promptTapped() {
        viewModel.startChat(prompt: promptField.text)
    }

    @objc private func openHistory() {
        viewModel.openHistory()
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
