import UIKit

final class ChatHistoryViewController: UIViewController {
    private let viewModel: ChatHistoryViewModel
    private let headerView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateView = UIStackView(axis: .vertical, spacing: 10, alignment: .center)

    init(viewModel: ChatHistoryViewModel) {
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
        let background = GradientView(colors: [UIColor(red: 0.08, green: 0.05, blue: 0.10, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        setupHeader()
        setupTable()
        setupEmptyState()
    }

    private func setupHeader() {
        let header = headerView
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(backButton)

        let title = UILabel()
        title.text = "AI Chat History"
        title.textColor = .white
        title.font = DesignSystem.Font.navTitle
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(title)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 58),

            backButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            title.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyState() {
        let icon = UIImageView(image: UIImage(systemName: "wand.and.stars"))
        icon.tintColor = DesignSystem.Color.pink
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48)
        ])

        let title = UILabel()
        title.text = "No chats yet"
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 24, weight: .bold)

        let subtitle = UILabel()
        subtitle.text = "Start a conversation to see\nyour history here"
        subtitle.textColor = DesignSystem.Color.secondaryText
        subtitle.textAlignment = .center
        subtitle.font = DesignSystem.Font.body
        subtitle.numberOfLines = 2

        emptyStateView.addArrangedSubview(icon)
        emptyStateView.addArrangedSubview(title)
        emptyStateView.addArrangedSubview(subtitle)
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func render(_ state: ChatHistoryState) {
        switch state {
        case .loaded:
            emptyStateView.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        case .empty:
            tableView.isHidden = true
            emptyStateView.isHidden = false
        }
    }

    @objc private func backTapped() {
        viewModel.close()
    }
}

extension ChatHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].sessions.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[section].title
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .white
        header.textLabel?.font = DesignSystem.Font.bodySemibold
        header.contentView.backgroundColor = .clear
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCell.reuseIdentifier, for: indexPath) as! HistoryCell
        cell.configure(with: viewModel.sections[indexPath.section].sessions[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.select(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.viewModel.delete(indexPath: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = DesignSystem.Color.pink
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
