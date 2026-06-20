import UIKit

final class ChatViewController: UIViewController {
    let viewModel: ChatViewModel
    private var messages: [ChatMessage] = []
    private var isLoadingResponse = false

    private let headerView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateStack = UIStackView(axis: .vertical, spacing: 8, alignment: .center)
    private let messagesLoadingIndicator = UIActivityIndicatorView(style: .large)
    private let inputContainer = UIView()
    private let inputTextView = UITextView()
    private let sendButton = IconButton(systemName: "paperplane.fill", pointSize: 15)
    private var inputBottomConstraint: NSLayoutConstraint!
    private var inputHeightConstraint: NSLayoutConstraint!

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextView.becomeFirstResponder()
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
        view.backgroundColor = DesignSystem.Color.background

        let background = GradientView(colors: [UIColor(red: 0.08, green: 0.05, blue: 0.10, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        setupHeader()
        setupInputBar()
        setupTableView()
        setupEmptyState()
        setupMessagesLoadingIndicator()
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backButton)

        let avatar = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink])
        avatar.layer.cornerRadius = 16
        avatar.layer.masksToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(avatar)

        let sparkle = UIImageView(image: UIImage(systemName: "sparkles"))
        sparkle.tintColor = .white
        sparkle.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(sparkle)
        NSLayoutConstraint.activate([
            sparkle.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            sparkle.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            sparkle.widthAnchor.constraint(equalToConstant: 15),
            sparkle.heightAnchor.constraint(equalToConstant: 15)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "AI Chat"
        titleLabel.textColor = .white
        titleLabel.font = DesignSystem.Font.navTitle
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        let dateLabel = UILabel()
        dateLabel.text = DateFormatting.shortDateFormatter.string(from: Date())
        dateLabel.textColor = DesignSystem.Color.secondaryText
        dateLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dateLabel)

        let historyButton = UIButton(type: .system)
        historyButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        historyButton.tintColor = .white
        historyButton.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(historyButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            avatar.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 10),
            avatar.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 32),
            avatar.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: avatar.topAnchor, constant: -1),

            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),

            historyButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            historyButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            historyButton.widthAnchor.constraint(equalToConstant: 36),
            historyButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
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
        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = DesignSystem.Color.pink
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 42),
            icon.heightAnchor.constraint(equalToConstant: 42)
        ])

        let title = UILabel()
        title.text = "Your AI assistant for anything"
        title.textColor = .white
        title.font = DesignSystem.Font.bodySemibold
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Ask questions, get answers, and explore ideas\nin seconds"
        subtitle.textColor = DesignSystem.Color.secondaryText
        subtitle.font = DesignSystem.Font.caption
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 2

        emptyStateStack.addArrangedSubview(icon)
        emptyStateStack.addArrangedSubview(title)
        emptyStateStack.addArrangedSubview(subtitle)
        view.addSubview(emptyStateStack)
        NSLayoutConstraint.activate([
            emptyStateStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -72),
            emptyStateStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupInputBar() {
        inputContainer.backgroundColor = DesignSystem.Color.backgroundElevated
        inputContainer.layer.cornerRadius = 22
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)

        inputTextView.backgroundColor = .clear
        inputTextView.textColor = .white
        inputTextView.tintColor = DesignSystem.Color.pink
        inputTextView.font = DesignSystem.Font.body
        inputTextView.textContainerInset = UIEdgeInsets(top: 11, left: 8, bottom: 9, right: 8)
        inputTextView.delegate = self
        inputTextView.isScrollEnabled = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(inputTextView)

        let placeholder = UILabel()
        placeholder.text = "How can I help you?"
        placeholder.textColor = DesignSystem.Color.mutedText
        placeholder.font = DesignSystem.Font.body
        placeholder.tag = 99
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.addSubview(placeholder)

        sendButton.alpha = 0
        sendButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        inputContainer.addSubview(sendButton)

        let micButton = IconButton(systemName: "mic", pointSize: 14)
        inputContainer.addSubview(micButton)

        inputBottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        inputHeightConstraint = inputContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)

        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            inputBottomConstraint,
            inputHeightConstraint,

            inputTextView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 4),
            inputTextView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 8),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -4),

            placeholder.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 12),
            placeholder.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 12),

            micButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -10),
            micButton.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),

            sendButton.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8)
        ])
    }

    private func setupMessagesLoadingIndicator() {
        messagesLoadingIndicator.color = DesignSystem.Color.lavender
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
        let bottomOffsetY = max(-tableView.adjustedContentInset.top, tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom)
        tableView.setContentOffset(CGPoint(x: 0, y: bottomOffsetY), animated: animated)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateSendButton() {
        let hasText = !inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        inputTextView.viewWithTag(99)?.isHidden = hasText
        UIView.animate(withDuration: 0.18) {
            self.sendButton.alpha = hasText ? 1 : 0
            self.sendButton.transform = hasText ? .identity : CGAffineTransform(scaleX: 0.75, y: 0.75)
        }
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY - view.safeAreaInsets.bottom)
        inputBottomConstraint.constant = -overlap - 10
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let optionsRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: optionsRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            guard !self.messages.isEmpty || self.isLoadingResponse else { return }
            self.scrollToBottom(animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        inputBottomConstraint.constant = -10
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func sendTapped() {
        let text = inputTextView.text ?? ""
        inputTextView.text = ""
        updateSendButton()
        viewModel.send(text)
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
            cell.contentView.addSubview(dots)
            NSLayoutConstraint.activate([
                dots.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                dots.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                dots.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
            dots.startAnimating()
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.reuseIdentifier, for: indexPath) as! MessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSendButton()
        let size = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let height = min(118, max(52, textView.sizeThatFits(size).height + 8))
        inputHeightConstraint.constant = height
        view.layoutIfNeeded()
    }
}
