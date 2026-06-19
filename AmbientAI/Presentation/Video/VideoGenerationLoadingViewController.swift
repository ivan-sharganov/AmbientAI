import UIKit

final class VideoGenerationLoadingViewController: UIViewController {
    var onClose: (() -> Void)?

    private let orbView = GeneratingOrbView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        orbView.startAnimating()
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background
        let background = GradientView(colors: [UIColor(red: 0.05, green: 0.03, blue: 0.07, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        let backButton = IconButton(systemName: "chevron.left", pointSize: 18)
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(backButton)

        let artContainer = UIView()
        artContainer.backgroundColor = .clear
        artContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(artContainer)

        orbView.translatesAutoresizingMaskIntoConstraints = false
        artContainer.addSubview(orbView)

        let title = UILabel()
        title.text = "Generating..."
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "We’re creating the best result for you"
        subtitle.textColor = DesignSystem.Color.secondaryText
        subtitle.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitle.textAlignment = .center

        let textStack = UIStackView(axis: .vertical, spacing: 10, alignment: .center)
        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(subtitle)
        view.addSubview(textStack)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),

            artContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -76),
            artContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.72),
            artContainer.heightAnchor.constraint(equalTo: artContainer.widthAnchor),

            orbView.centerXAnchor.constraint(equalTo: artContainer.centerXAnchor),
            orbView.centerYAnchor.constraint(equalTo: artContainer.centerYAnchor),
            orbView.widthAnchor.constraint(equalTo: artContainer.widthAnchor, multiplier: 0.74),
            orbView.heightAnchor.constraint(equalTo: orbView.widthAnchor),

            textStack.topAnchor.constraint(equalTo: artContainer.bottomAnchor, constant: 42),
            textStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            textStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28)
        ])
    }

    @objc private func closeTapped() {
        onClose?()
    }
}

private final class GeneratingOrbView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
    private let highlightLayer = CAGradientLayer()
    private let rimLayer = CAShapeLayer()
    private var didConfigure = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        configureLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        gradientLayer.cornerRadius = bounds.width / 2
        highlightLayer.frame = bounds.insetBy(dx: bounds.width * 0.12, dy: bounds.height * 0.10)
        highlightLayer.cornerRadius = highlightLayer.bounds.width / 2

        rimLayer.frame = bounds
        let rimPath = UIBezierPath(ovalIn: bounds.insetBy(dx: 8, dy: 8))
        rimLayer.path = rimPath.cgPath
        rimLayer.lineWidth = 12
    }

    private func configureLayers() {
        guard !didConfigure else { return }
        didConfigure = true

        gradientLayer.type = .radial
        gradientLayer.colors = [
            UIColor(red: 0.96, green: 0.84, blue: 0.97, alpha: 1).cgColor,
            UIColor(red: 0.73, green: 0.66, blue: 0.92, alpha: 1).cgColor,
            UIColor(red: 0.93, green: 0.58, blue: 0.74, alpha: 1).cgColor,
            UIColor(red: 0.36, green: 0.32, blue: 0.44, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 0.42, 0.72, 1]
        gradientLayer.startPoint = CGPoint(x: 0.34, y: 0.26)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.shadowColor = DesignSystem.Color.pink.cgColor
        gradientLayer.shadowOpacity = 0.42
        gradientLayer.shadowRadius = 32
        gradientLayer.shadowOffset = .zero

        highlightLayer.type = .radial
        highlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.68).cgColor,
            UIColor.white.withAlphaComponent(0.16).cgColor,
            UIColor.clear.cgColor
        ]
        highlightLayer.locations = [0, 0.34, 1]
        highlightLayer.startPoint = CGPoint(x: 0.28, y: 0.18)
        highlightLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(highlightLayer)

        rimLayer.fillColor = UIColor.clear.cgColor
        rimLayer.strokeColor = UIColor.white.withAlphaComponent(0.34).cgColor
        rimLayer.lineCap = .round
        layer.addSublayer(rimLayer)
    }

    func startAnimating() {
        guard layer.animation(forKey: "orbRotation") == nil else { return }

        let colorAnimation = CAKeyframeAnimation(keyPath: "colors")
        colorAnimation.values = [
            gradientLayer.colors as Any,
            [
                UIColor(red: 0.75, green: 0.70, blue: 0.98, alpha: 1).cgColor,
                UIColor(red: 0.98, green: 0.76, blue: 0.91, alpha: 1).cgColor,
                UIColor(red: 0.54, green: 0.50, blue: 0.71, alpha: 1).cgColor,
                UIColor(red: 0.92, green: 0.44, blue: 0.70, alpha: 1).cgColor
            ],
            gradientLayer.colors as Any
        ]
        colorAnimation.duration = 3.2
        colorAnimation.repeatCount = .infinity
        colorAnimation.autoreverses = true
        colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(colorAnimation, forKey: "orbColors")

        let pointAnimation = CAKeyframeAnimation(keyPath: "startPoint")
        pointAnimation.values = [CGPoint(x: 0.28, y: 0.22), CGPoint(x: 0.74, y: 0.28), CGPoint(x: 0.42, y: 0.76), CGPoint(x: 0.28, y: 0.22)]
        pointAnimation.duration = 4.4
        pointAnimation.repeatCount = .infinity
        pointAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(pointAnimation, forKey: "orbFlow")

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 8
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(rotation, forKey: "orbRotation")

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.96
        pulse.toValue = 1.04
        pulse.duration = 1.8
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(pulse, forKey: "orbPulse")

        let rimPulse = CABasicAnimation(keyPath: "opacity")
        rimPulse.fromValue = 0.34
        rimPulse.toValue = 0.82
        rimPulse.duration = 1.4
        rimPulse.autoreverses = true
        rimPulse.repeatCount = .infinity
        rimPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        rimLayer.add(rimPulse, forKey: "rimPulse")
    }
}
