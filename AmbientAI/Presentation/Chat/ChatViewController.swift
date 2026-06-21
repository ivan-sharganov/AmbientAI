import UIKit

final class ChatViewController: UIViewController {
    let viewModel: ChatViewModel
    private var messages: [ChatMessage] = []
    private var isLoadingResponse = false

    private let headerView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateStack = UIStackView(axis: .vertical, spacing: 8, alignment: .center)
    private let messagesLoadingIndicator = UIActivityIndicatorView(style: .medium)
    private let inputBackgroundView = UIView()
    private let inputContainer = UIView()
    private let inputTextView = UITextView()
    private let placeholderLabel = UILabel()
    private let sendButton = UIButton(type: .custom)
    private let utilityButtons = UIStackView(axis: .horizontal, spacing: 8)
    private var inputBottomConstraint: NSLayoutConstraint!
    private var inputHeightConstraint: NSLayoutConstraint!
    private var textTrailingToSend: NSLayoutConstraint!
    private var textTrailingToUtilities: NSLayoutConstraint!
    private var displayedSendButtonState: Bool?

    init(viewModel: ChatViewModel) {
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
        registerKeyboardNotifications()
        viewModel.viewDidLoad()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func setupUI() {
        view.backgroundColor = ChatStyle.background
        setupHeader()
        setupInputBar()
        setupTableView()
        setupEmptyState()
        setupMessagesLoadingIndicator()
    }

    private func setupHeader() {
        headerView.backgroundColor = ChatStyle.header
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let backButton = UIButton(type: .custom)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backButton)

        let backIcon = UIImageView(image: UIImage(named: "VideoBackVector"))
        backIcon.contentMode = .scaleAspectFit
        backIcon.transform = CGAffineTransform(scaleX: -1, y: 1)
        backIcon.translatesAutoresizingMaskIntoConstraints = false
        backButton.addSubview(backIcon)

        let avatar = GradientView(
            colors: [ChatStyle.blue, ChatStyle.pink],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        avatar.layer.cornerRadius = 16
        avatar.layer.cornerCurve = .continuous
        avatar.layer.masksToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(avatar)

        let avatarIcon = UIImageView(image: UIImage(named: "HomePromptIcon"))
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(avatarIcon)

        let titleLabel = UILabel()
        titleLabel.text = "AI Chat"
        titleLabel.textColor = .white
        titleLabel.font = ChatStyle.font(size: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        let dateLabel = UILabel()
        dateLabel.text = DateFormatting.shortDateFormatter.string(from: Date())
        dateLabel.textColor = ChatStyle.dimText
        dateLabel.font = ChatStyle.font(size: 11, weight: .regular)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dateLabel)

        let historyButton = UIButton(type: .custom)
        historyButton.setImage(UIImage(named: "VideoHistoryIcon"), for: .normal)
        historyButton.imageView?.contentMode = .scaleAspectFit
        historyButton.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(historyButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            backButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            backIcon.centerXAnchor.constraint(equalTo: backButton.centerXAnchor),
            backIcon.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            backIcon.widthAnchor.constraint(equalToConstant: 9),
            backIcon.heightAnchor.constraint(equalToConstant: 18),

            avatar.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            avatar.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 32),
            avatar.heightAnchor.constraint(equalToConstant: 32),
            avatarIcon.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 20),
            avatarIcon.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: avatar.topAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),

            historyButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            historyButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            historyButton.widthAnchor.constraint(equalToConstant: 40),
            historyButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor)
        ])
    }

    private func setupEmptyState() {
        let title = UILabel()
        title.text = "Your AI assistant for anything"
        title.textColor = .white
        title.font = ChatStyle.font(size: 16, weight: .semibold)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Ask questions, get answers, and explore ideas\nin seconds"
        subtitle.textColor = ChatStyle.secondaryText
        subtitle.font = ChatStyle.font(size: 13, weight: .regular)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 2

        emptyStateStack.addArrangedSubview(title)
        emptyStateStack.addArrangedSubview(subtitle)
        view.addSubview(emptyStateStack)
        NSLayoutConstraint.activate([
            emptyStateStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupInputBar() {
        inputBackgroundView.backgroundColor = ChatStyle.input
        inputBackgroundView.layer.cornerRadius = 20
        inputBackgroundView.layer.cornerCurve = .continuous
        inputBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        inputBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBackgroundView)

        inputContainer.backgroundColor = .clear
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)

        inputTextView.backgroundColor = .clear
        inputTextView.textColor = .white
        inputTextView.tintColor = ChatStyle.pink
        inputTextView.font = ChatStyle.font(size: 15, weight: .regular)
        inputTextView.textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 10, right: 0)
        inputTextView.textContainer.lineFragmentPadding = 0
        inputTextView.delegate = self
        inputTextView.isScrollEnabled = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(inputTextView)

        placeholderLabel.text = "Ask anything..."
        placeholderLabel.textColor = ChatStyle.placeholder
        placeholderLabel.font = ChatStyle.font(size: 15, weight: .regular)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(placeholderLabel)

        configureCircleButton(sendButton, systemName: "paperplane.fill")
        sendButton.layer.borderWidth = 0
        let sendGradient = GradientView(
            colors: [ChatStyle.blue, ChatStyle.pink],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        sendGradient.isUserInteractionEnabled = false
        sendButton.insertSubview(sendGradient, at: 0)
        sendGradient.pinToSuperviewEdges()
        if let imageView = sendButton.imageView {
            sendButton.bringSubviewToFront(imageView)
        }
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(sendButton)

        let dismissButton = UIButton(type: .custom)
        configureCircleButton(dismissButton, systemName: "arrow.down.to.line.compact")
        dismissButton.addTarget(self, action: #selector(dismissKeyboardTapped), for: .touchUpInside)

        let micButton = UIButton(type: .custom)
        configureCircleButton(micButton, systemName: "mic")

        utilityButtons.addArrangedSubview(dismissButton)
        utilityButtons.addArrangedSubview(micButton)
        utilityButtons.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(utilityButtons)

        inputBottomConstraint = inputContainer.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -8
        )
        inputHeightConstraint = inputContainer.heightAnchor.constraint(equalToConstant: 68)
        textTrailingToSend = inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12)
        textTrailingToUtilities = inputTextView.trailingAnchor.constraint(equalTo: utilityButtons.leadingAnchor, constant: -12)
        textTrailingToSend.isActive = false

        NSLayoutConstraint.activate([
            inputBackgroundView.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            inputBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint,
            inputHeightConstraint,

            inputTextView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 10),
            inputTextView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -10),
            textTrailingToUtilities,

            placeholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 12),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40),

            utilityButtons.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            utilityButtons.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 40),
            dismissButton.heightAnchor.constraint(equalToConstant: 40),
            micButton.widthAnchor.constraint(equalToConstant: 40),
            micButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        updateSendButton(animated: false)
    }

    private func configureCircleButton(_ button: UIButton, systemName: String) {
        button.backgroundColor = UIColor.white.withAlphaComponent(0.015)
        button.layer.cornerRadius = 20
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = ChatStyle.buttonBorder.cgColor
        button.clipsToBounds = true
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        button.setImage(UIImage(systemName: systemName, withConfiguration: configuration), for: .normal)
        button.tintColor = .white
    }

    private func setupMessagesLoadingIndicator() {
        messagesLoadingIndicator.color = ChatStyle.blue
        messagesLoadingIndicator.hidesWhenStopped = true
        messagesLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messagesLoadingIndicator)
        NSLayoutConstraint.activate([
            messagesLoadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messagesLoadingIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }

    private func render(_ state: ChatViewState) {
        switch state {
        case .loadingMessages:
            messages = []
            isLoadingResponse = false
            tableView.reloadData()
            emptyStateStack.isHidden = true
            messagesLoadingIndicator.startAnimating()
            inputContainer.isUserInteractionEnabled = false
            inputContainer.alpha = 0.55

        case let .loaded(messages, isLoadingResponse):
            messagesLoadingIndicator.stopAnimating()
            inputContainer.isUserInteractionEnabled = true
            inputContainer.alpha = 1
            self.messages = messages
            self.isLoadingResponse = isLoadingResponse
            emptyStateStack.isHidden = !messages.isEmpty || isLoadingResponse
            placeholderLabel.text = messages.isEmpty ? "Ask anything..." : "How can I help you?"
            tableView.reloadData()
            scrollToBottom()

        case let .error(message):
            messagesLoadingIndicator.stopAnimating()
            inputContainer.isUserInteractionEnabled = true
            inputContainer.alpha = 1
            showError(message)
        }
    }

    private func scrollToBottom(animated: Bool = true) {
        tableView.layoutIfNeeded()
        let bottomOffsetY = max(
            -tableView.adjustedContentInset.top,
            tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom
        )
        tableView.setContentOffset(CGPoint(x: 0, y: bottomOffsetY), animated: animated)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateSendButton(animated: Bool = true) {
        let hasText = !inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel.isHidden = hasText
        guard displayedSendButtonState != hasText else { return }
        displayedSendButtonState = hasText

        textTrailingToUtilities.isActive = !hasText
        textTrailingToSend.isActive = hasText
        utilityButtons.isHidden = hasText

        guard animated else {
            sendButton.isHidden = !hasText
            sendButton.alpha = hasText ? 1 : 0
            sendButton.transform = hasText ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
            return
        }
        if hasText {
            sendButton.alpha = 0
            sendButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            sendButton.isHidden = false
        }
        UIView.animate(withDuration: 0.18, animations: {
            self.sendButton.alpha = hasText ? 1 : 0
            self.sendButton.transform = hasText ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.sendButton.isHidden = !hasText
        })
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

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY - view.safeAreaInsets.bottom)
        inputBottomConstraint.constant = -overlap
        animateKeyboard(notification) { [weak self] in
            guard let self, !messages.isEmpty || isLoadingResponse else { return }
            scrollToBottom(animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        inputBottomConstraint.constant = -8
        animateKeyboard(notification)
    }

    private func animateKeyboard(_ notification: Notification, completion: (() -> Void)? = nil) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let rawCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: rawCurve << 16),
            animations: { self.view.layoutIfNeeded() },
            completion: { _ in completion?() }
        )
    }

    @objc private func sendTapped() {
        let text = inputTextView.text ?? ""
        inputTextView.text = ""
        inputTextView.isScrollEnabled = false
        inputHeightConstraint.constant = 68
        updateSendButton()
        viewModel.send(text)
    }

    @objc private func dismissKeyboardTapped() {
        view.endEditing(true)
    }

    @objc private func historyTapped() {
        viewModel.openHistory()
    }

    @objc private func backTapped() {
        viewModel.close()
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count + (isLoadingResponse ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoadingResponse && indexPath.row == messages.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            let dots = LoadingDotsView()
            dots.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(dots)
            NSLayoutConstraint.activate([
                dots.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                dots.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                dots.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
            dots.startAnimating()
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: MessageCell.reuseIdentifier,
            for: indexPath
        ) as! MessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSendButton()
        let fittingWidth = max(1, textView.bounds.width)
        let fittingSize = CGSize(width: fittingWidth, height: .greatestFiniteMagnitude)
        let requiredHeight = textView.sizeThatFits(fittingSize).height + 20
        let maximumHeight: CGFloat = 132
        inputHeightConstraint.constant = min(maximumHeight, max(68, requiredHeight))
        textView.isScrollEnabled = requiredHeight > maximumHeight
        if textView.isScrollEnabled {
            textView.scrollRangeToVisible(NSRange(location: textView.text.utf16.count, length: 0))
        }
        view.layoutIfNeeded()
    }
}

private enum ChatStyle {
    static let background = UIColor(red: 11 / 255, green: 7 / 255, blue: 14 / 255, alpha: 1)
    static let header = UIColor(red: 18 / 255, green: 13 / 255, blue: 20 / 255, alpha: 1)
    static let input = UIColor(red: 28 / 255, green: 21 / 255, blue: 29 / 255, alpha: 1)
    static let secondaryText = UIColor(red: 115 / 255, green: 108 / 255, blue: 117 / 255, alpha: 1)
    static let dimText = UIColor(red: 65 / 255, green: 59 / 255, blue: 68 / 255, alpha: 1)
    static let placeholder = UIColor(red: 92 / 255, green: 84 / 255, blue: 94 / 255, alpha: 1)
    static let buttonBorder = UIColor(red: 61 / 255, green: 51 / 255, blue: 63 / 255, alpha: 1)
    static let blue = UIColor(red: 152 / 255, green: 198 / 255, blue: 247 / 255, alpha: 1)
    static let pink = UIColor(red: 235 / 255, green: 91 / 255, blue: 146 / 255, alpha: 1)

    static func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let name: String
        switch weight {
        case .semibold: name = "Inter-SemiBold"
        case .medium: name = "Inter-Medium"
        default: name = "Inter-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}
