import UIKit

final class PaywallViewController: UIViewController {
    var onClose: (() -> Void)?
    var onUnlock: (() -> Void)?

    private let apphudService: ApphudServiceProtocol
    private let closeButton = UIButton(type: .system)
    private let unlockButton = UIButton(type: .system)
    private let yearPlan = PaywallPlanControl(
        title: "Year $1.27",
        suffix: "/ week",
        subtitle: "$ 69.99",
        badge: "SAVE 80%"
    )
    private let monthPlan = PaywallPlanControl(
        title: "Month $1.99",
        suffix: "/ week",
        subtitle: "$ 7.99",
        badge: nil
    )
    private var selectedPlan: PaywallPlanControl?
    private var closeWorkItem: DispatchWorkItem?

    init(apphudService: ApphudServiceProtocol) {
        self.apphudService = apphudService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        selectPlan(yearPlan)
        scheduleCloseButtonAppearance()
    }

    deinit {
        closeWorkItem?.cancel()
    }

    private func setupUI() {
        view.backgroundColor = PaywallStyle.background
        setupBackgroundGlows()
        configureCloseButton()

        let titleLabel = UILabel()
        titleLabel.text = "Create anything\nyou want"
        titleLabel.textColor = .white
        titleLabel.font = .paywallInter(size: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let benefits = UIStackView(axis: .vertical, spacing: 8)
        benefits.addArrangedSubview(makeBenefit(imageName: "PaywallBenefitSpeed", text: "Get results in seconds"))
        benefits.addArrangedSubview(makeBenefit(imageName: "PaywallBenefitWriting", text: "Turn any text into better writing"))
        benefits.addArrangedSubview(makeBenefit(imageName: "PaywallBenefitSimplify", text: "Simplify complex information"))
        benefits.addArrangedSubview(makeBenefit(imageName: "PaywallBenefitTemplate", text: "Create content with AI templates"))

        yearPlan.addTarget(self, action: #selector(planTapped(_:)), for: .touchUpInside)
        monthPlan.addTarget(self, action: #selector(planTapped(_:)), for: .touchUpInside)
        let plans = UIStackView(axis: .vertical, spacing: 12)
        plans.addArrangedSubview(yearPlan)
        plans.addArrangedSubview(monthPlan)

        let mainContent = UIStackView(axis: .vertical, spacing: 0, alignment: .center)
        mainContent.addArrangedSubview(titleLabel)
        mainContent.setCustomSpacing(32, after: titleLabel)
        mainContent.addArrangedSubview(benefits)
        mainContent.setCustomSpacing(32, after: benefits)
        mainContent.addArrangedSubview(plans)
        view.addSubview(mainContent)

        let cancelRow = makeCancelRow()
        configureUnlockButton()
        let legalRow = makeLegalRow()
        let bottomBar = UIStackView(axis: .vertical, spacing: 0)
        bottomBar.addArrangedSubview(cancelRow)
        bottomBar.addArrangedSubview(unlockButton)
        bottomBar.addArrangedSubview(legalRow)
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            cancelRow.heightAnchor.constraint(equalToConstant: 40),
            unlockButton.heightAnchor.constraint(equalToConstant: 50),
            legalRow.heightAnchor.constraint(equalToConstant: 39),

            mainContent.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainContent.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mainContent.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -18),

            titleLabel.heightAnchor.constraint(equalToConstant: 82),
            benefits.widthAnchor.constraint(equalToConstant: 282),
            plans.widthAnchor.constraint(equalTo: mainContent.widthAnchor),
            yearPlan.heightAnchor.constraint(equalToConstant: 72),
            monthPlan.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    private func setupBackgroundGlows() {
        addGlow(
            named: "PaywallGlowTop",
            nodeSize: CGSize(width: 619.208, height: 246.408),
            center: CGPoint(x: 254.65, y: 83.43),
            rotation: 18.36,
            imageFrame: CGRect(x: -100, y: -100, width: 819.208, height: 446.408)
        )
        addGlow(
            named: "PaywallGlowLeft",
            nodeSize: CGSize(width: 232.289, height: 380.115),
            center: CGPoint(x: 172.87, y: 215.15),
            rotation: 89.27,
            imageFrame: CGRect(x: -108.1, y: -108.1, width: 448.489, height: 596.315)
        )
        addGlow(
            named: "PaywallGlowRight",
            nodeSize: CGSize(width: 232.289, height: 312.319),
            center: CGPoint(x: 473.62, y: 265.12),
            rotation: 89.27,
            imageFrame: CGRect(x: -108.1, y: -108.1, width: 448.489, height: 528.519)
        )
    }

    private func addGlow(named name: String, nodeSize: CGSize, center: CGPoint, rotation: CGFloat, imageFrame: CGRect) {
        let node = UIView(frame: CGRect(origin: .zero, size: nodeSize))
        node.center = center
        node.transform = CGAffineTransform(rotationAngle: rotation * .pi / 180)
        node.isUserInteractionEnabled = false

        let glow = UIImageView(image: UIImage(named: name))
        glow.contentMode = .scaleToFill
        glow.frame = imageFrame
        glow.isUserInteractionEnabled = false
        node.addSubview(glow)
        view.addSubview(node)
    }

    private func configureCloseButton() {
        let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.7)
        closeButton.alpha = 0
        closeButton.isHidden = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 21),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeBenefit(imageName: String, text: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let icon = UIImageView(image: UIImage(named: imageName))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .paywallInter(size: 16, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.9
        label.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(icon)
        row.addSubview(label)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    private func makeCancelRow() -> UIView {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        let iconName = "clock.arrow.trianglehead.counterclockwise.rotate.90"
        let image = UIImage(systemName: iconName, withConfiguration: symbolConfiguration)
            ?? UIImage(systemName: "clock.arrow.circlepath", withConfiguration: symbolConfiguration)
        let icon = UIImageView(image: image)
        icon.tintColor = PaywallStyle.secondaryText
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: 24).isActive = true
        iconContainer.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor)
        ])

        let label = UILabel()
        label.text = "Cancel Anytime"
        label.textColor = PaywallStyle.secondaryText
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)

        let row = UIStackView(axis: .horizontal, spacing: 0, alignment: .center)
        row.addArrangedSubview(iconContainer)
        row.addArrangedSubview(label)
        let container = UIView()
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            row.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func configureUnlockButton() {
        unlockButton.setTitle("Unlock now", for: .normal)
        unlockButton.setTitleColor(.white, for: .normal)
        unlockButton.titleLabel?.font = .paywallInter(size: 16, weight: .semiBold)
        unlockButton.layer.cornerRadius = 24
        unlockButton.clipsToBounds = true
        unlockButton.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
        unlockButton.translatesAutoresizingMaskIntoConstraints = false

        let gradient = GradientView(
            colors: [PaywallStyle.blue, PaywallStyle.pink],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        gradient.isUserInteractionEnabled = false
        unlockButton.insertSubview(gradient, at: 0)
        gradient.pinToSuperviewEdges()
    }

    private func makeLegalRow() -> UIView {
        let row = UIStackView(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fillEqually)
        row.addArrangedSubview(makeLinkButton(title: "Privacy Policy", alignment: .left, selector: #selector(privacyTapped)))
        row.addArrangedSubview(makeLinkButton(title: "Restore Purchases", alignment: .center, selector: #selector(restoreTapped)))
        row.addArrangedSubview(makeLinkButton(title: "Terms of Use", alignment: .right, selector: #selector(termsTapped)))
        return row
    }

    private func makeLinkButton(title: String, alignment: UIControl.ContentHorizontalAlignment, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(PaywallStyle.secondaryText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        button.contentHorizontalAlignment = alignment
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    private func selectPlan(_ plan: PaywallPlanControl) {
        selectedPlan?.isPlanSelected = false
        selectedPlan = plan
        plan.isPlanSelected = true
    }

    private func scheduleCloseButtonAppearance() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            closeButton.isHidden = false
            UIView.animate(withDuration: 0.3) { self.closeButton.alpha = 1 }
        }
        closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    private func showPlaceholderAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func planTapped(_ sender: PaywallPlanControl) { selectPlan(sender) }
    @objc private func closeTapped() { onClose?() }

    @objc private func unlockTapped() {
        let plan: ApphudPlan = selectedPlan === yearPlan ? .year : .month
        performPurchaseOperation { [apphudService] in try await apphudService.purchase(plan: plan) }
    }

    @objc private func restoreTapped() {
        performPurchaseOperation { [apphudService] in try await apphudService.restorePurchases() }
    }

    @objc private func privacyTapped() {
        showPlaceholderAlert(title: "Privacy Policy", message: "Privacy Policy URL is not configured yet.")
    }

    @objc private func termsTapped() {
        showPlaceholderAlert(title: "Terms of Use", message: "Terms of Use URL is not configured yet.")
    }

    private func performPurchaseOperation(_ operation: @escaping () async throws -> Bool) {
        setPurchasing(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let hasAccess = try await operation()
                setPurchasing(false)
                if hasAccess { onUnlock?() }
            } catch {
                setPurchasing(false)
                showPlaceholderAlert(title: "Purchase unavailable", message: error.localizedDescription)
            }
        }
    }

    private func setPurchasing(_ isPurchasing: Bool) {
        unlockButton.isEnabled = !isPurchasing
        yearPlan.isEnabled = !isPurchasing
        monthPlan.isEnabled = !isPurchasing
        unlockButton.setTitle(isPurchasing ? "Please wait..." : "Unlock now", for: .normal)
        unlockButton.alpha = isPurchasing ? 0.65 : 1
    }
}

private final class PaywallPlanControl: UIControl {
    private let borderGradient = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    var isPlanSelected = false {
        didSet { updateAppearance() }
    }

    init(title: String, suffix: String, subtitle: String, badge: String?) {
        super.init(frame: .zero)
        setupUI(title: title, suffix: suffix, subtitle: subtitle, badge: badge)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderGradient.frame = bounds
        borderMask.frame = bounds
        borderMask.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 22).cgPath
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01, self.point(inside: point, with: event) else { return nil }
        return self
    }

    private func setupUI(title: String, suffix: String, subtitle: String, badge: String?) {
        backgroundColor = .clear
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous

        let normalBorder = UIColor.white.withAlphaComponent(0.3).cgColor
        borderGradient.colors = [normalBorder, normalBorder]
        borderGradient.startPoint = CGPoint(x: 0, y: 0.5)
        borderGradient.endPoint = CGPoint(x: 1, y: 0.5)
        borderGradient.mask = borderMask
        layer.addSublayer(borderGradient)

        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        borderMask.lineWidth = 1

        let titleLabel = UILabel()
        let text = NSMutableAttributedString(
            string: title,
            attributes: [.font: UIFont.paywallInter(size: 16, weight: .medium), .foregroundColor: UIColor.white]
        )
        text.append(NSAttributedString(
            string: " \(suffix)",
            attributes: [.font: UIFont.paywallInter(size: 16, weight: .regular), .foregroundColor: UIColor.white]
        ))
        titleLabel.attributedText = text

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = PaywallStyle.secondaryText
        subtitleLabel.font = .paywallInter(size: 14, weight: .regular)

        let textStack = UIStackView(axis: .vertical, spacing: 4, alignment: .leading)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        if let badge {
            let badgeView = PaywallBadgeView(text: badge)
            addSubview(badgeView)
            NSLayoutConstraint.activate([
                badgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                badgeView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
                badgeView.heightAnchor.constraint(equalToConstant: 25)
            ])
        }
    }

    private func updateAppearance() {
        let normalBorder = UIColor.white.withAlphaComponent(0.3).cgColor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        borderGradient.colors = isPlanSelected
            ? [PaywallStyle.blue.cgColor, PaywallStyle.pink.cgColor]
            : [normalBorder, normalBorder]
        CATransaction.commit()
    }
}

private final class PaywallBadgeView: UIView {
    init(text: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 13
        layer.masksToBounds = true

        let gradient = GradientView(
            colors: [PaywallStyle.blue, PaywallStyle.pink],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        gradient.isUserInteractionEnabled = false
        addSubview(gradient)
        gradient.pinToSuperviewEdges()

        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .paywallInter(size: 14, weight: .medium)
        label.textAlignment = .center
        addSubview(label)
        label.pinToSuperviewEdges(insets: UIEdgeInsets(top: 5, left: 16, bottom: 5, right: 16))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum PaywallStyle {
    static let background = UIColor(red: 11 / 255, green: 7 / 255, blue: 14 / 255, alpha: 1)
    static let secondaryText = UIColor(red: 96 / 255, green: 96 / 255, blue: 96 / 255, alpha: 1)
    static let blue = UIColor(red: 152 / 255, green: 198 / 255, blue: 247 / 255, alpha: 1)
    static let pink = UIColor(red: 235 / 255, green: 91 / 255, blue: 146 / 255, alpha: 1)
}

private extension UIFont {
    enum PaywallWeight {
        case regular
        case medium
        case semiBold
        case bold

        var postScriptName: String {
            switch self {
            case .regular: return "Inter-Regular"
            case .medium: return "Inter-Medium"
            case .semiBold: return "Inter-SemiBold"
            case .bold: return "Inter-Bold"
            }
        }

        var fallback: UIFont.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semiBold: return .semibold
            case .bold: return .bold
            }
        }
    }

    static func paywallInter(size: CGFloat, weight: PaywallWeight) -> UIFont {
        UIFont(name: weight.postScriptName, size: size) ?? .systemFont(ofSize: size, weight: weight.fallback)
    }
}
