import UIKit

final class PaywallViewController: UIViewController {
    var onClose: (() -> Void)?
    var onUnlock: (() -> Void)?

    private let apphudService: ApphudServiceProtocol
    private let closeButton = UIButton(type: .system)
    private let unlockButton = UIButton(type: .system)
    private let yearPlan = PaywallPlanControl(
        title: "Year $1.27 / week",
        subtitle: "$ 69.99",
        badge: "SAVE 80%"
    )
    private let monthPlan = PaywallPlanControl(
        title: "Month $1.99 / week",
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
        view.backgroundColor = DesignSystem.Color.background

        let background = GradientView(
            colors: [UIColor(red: 0.22, green: 0.18, blue: 0.31, alpha: 1), DesignSystem.Color.background],
            startPoint: CGPoint(x: 0.25, y: 0),
            endPoint: CGPoint(x: 0.55, y: 0.46)
        )
        view.addSubview(background)
        background.pinToSuperviewEdges()

        configureCloseButton()

        let titleLabel = UILabel()
        titleLabel.text = "Create anything\nyou want"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        let benefits = UIStackView(axis: .vertical, spacing: 17)
        benefits.addArrangedSubview(makeBenefit(symbol: "sparkles", text: "Get results in seconds"))
        benefits.addArrangedSubview(makeBenefit(symbol: "wand.and.stars", text: "Turn any text into better writing"))
        benefits.addArrangedSubview(makeBenefit(symbol: "text.badge.checkmark", text: "Simplify complex information"))
        benefits.addArrangedSubview(makeBenefit(symbol: "photo.badge.checkmark", text: "Create content with AI templates"))

        yearPlan.addTarget(self, action: #selector(planTapped(_:)), for: .touchUpInside)
        monthPlan.addTarget(self, action: #selector(planTapped(_:)), for: .touchUpInside)
        let plans = UIStackView(axis: .vertical, spacing: 12)
        plans.addArrangedSubview(yearPlan)
        plans.addArrangedSubview(monthPlan)
        yearPlan.heightAnchor.constraint(equalToConstant: 70).isActive = true
        monthPlan.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let cancelLabel = UILabel()
        cancelLabel.text = "◷  Cancel Anytime"
        cancelLabel.textColor = DesignSystem.Color.mutedText
        cancelLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        cancelLabel.textAlignment = .center

        unlockButton.setTitle("Unlock now", for: .normal)
        unlockButton.setTitleColor(.white, for: .normal)
        unlockButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        unlockButton.layer.cornerRadius = 24
        unlockButton.clipsToBounds = true
        unlockButton.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
        unlockButton.translatesAutoresizingMaskIntoConstraints = false
        unlockButton.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let buttonGradient = GradientView(
            colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        buttonGradient.isUserInteractionEnabled = false
        unlockButton.insertSubview(buttonGradient, at: 0)
        buttonGradient.pinToSuperviewEdges()

        let legalRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .equalSpacing)
        legalRow.addArrangedSubview(makeLinkButton(title: "Privacy Policy", selector: #selector(privacyTapped)))
        legalRow.addArrangedSubview(makeLinkButton(title: "Restore Purchases", selector: #selector(restoreTapped)))
        legalRow.addArrangedSubview(makeLinkButton(title: "Terms of Use", selector: #selector(termsTapped)))

        let content = UIStackView(axis: .vertical, spacing: 0)
        content.addArrangedSubview(titleLabel)
        content.setCustomSpacing(34, after: titleLabel)
        content.addArrangedSubview(benefits)
        content.setCustomSpacing(32, after: benefits)
        content.addArrangedSubview(plans)
        content.setCustomSpacing(20, after: plans)
        content.addArrangedSubview(cancelLabel)
        content.setCustomSpacing(18, after: cancelLabel)
        content.addArrangedSubview(unlockButton)
        content.setCustomSpacing(14, after: unlockButton)
        content.addArrangedSubview(legalRow)
        view.addSubview(content)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            content.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 78),
            content.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            content.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 58),

            legalRow.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func configureCloseButton() {
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.64)
        closeButton.alpha = 0
        closeButton.isHidden = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            closeButton.widthAnchor.constraint(equalToConstant: 42),
            closeButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    private func makeBenefit(symbol: String, text: String) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = DesignSystem.Color.pink
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 23),
            icon.heightAnchor.constraint(equalToConstant: 23)
        ])

        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8

        let row = UIStackView(axis: .horizontal, spacing: 13, alignment: .center)
        row.addArrangedSubview(icon)
        row.addArrangedSubview(label)
        return row
    }

    private func makeLinkButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(DesignSystem.Color.mutedText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 9, weight: .regular)
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
            self.closeButton.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.closeButton.alpha = 1
            }
        }
        closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    private func showPlaceholderAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func planTapped(_ sender: PaywallPlanControl) {
        selectPlan(sender)
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func unlockTapped() {
        let plan: ApphudPlan = selectedPlan === yearPlan ? .year : .month
        performPurchaseOperation { [apphudService] in
            try await apphudService.purchase(plan: plan)
        }
    }

    @objc private func restoreTapped() {
        performPurchaseOperation { [apphudService] in
            try await apphudService.restorePurchases()
        }
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
                if hasAccess {
                    onUnlock?()
                }
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

    init(title: String, subtitle: String, badge: String?) {
        super.init(frame: .zero)
        setupUI(title: title, subtitle: subtitle, badge: badge)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderGradient.frame = bounds
        borderMask.frame = bounds
        borderMask.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.75, dy: 0.75), cornerRadius: 20).cgPath
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01, self.point(inside: point, with: event) else {
            return nil
        }
        return self
    }

    private func setupUI(title: String, subtitle: String, badge: String?) {
        backgroundColor = UIColor.white.withAlphaComponent(0.025)
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.24).cgColor

        borderGradient.colors = [DesignSystem.Color.lavender.cgColor, DesignSystem.Color.pink.cgColor]
        borderGradient.startPoint = CGPoint(x: 0, y: 0.5)
        borderGradient.endPoint = CGPoint(x: 1, y: 0.5)
        borderGradient.mask = borderMask
        borderGradient.isHidden = true
        layer.addSublayer(borderGradient)

        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        borderMask.lineWidth = 1.5

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = DesignSystem.Color.mutedText
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)

        let textStack = UIStackView(axis: .vertical, spacing: 5)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        if let badge {
            let badgeLabel = PaddingLabel(insets: UIEdgeInsets(top: 6, left: 13, bottom: 6, right: 13))
            badgeLabel.text = badge
            badgeLabel.textColor = .white
            badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            badgeLabel.backgroundColor = DesignSystem.Color.pink
            badgeLabel.layer.cornerRadius = 13
            badgeLabel.clipsToBounds = true
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(badgeLabel)

            NSLayoutConstraint.activate([
                badgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -17),
                badgeLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }

    private func updateAppearance() {
        borderGradient.isHidden = !isPlanSelected
        layer.borderColor = isPlanSelected ? UIColor.clear.cgColor : UIColor.white.withAlphaComponent(0.24).cgColor
    }
}

private final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}
