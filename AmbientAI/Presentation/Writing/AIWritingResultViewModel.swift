import Foundation

final class AIWritingResultViewModel {
    var onStateChange: ((AIWritingResultState) -> Void)?

    let request: AIWritingRequestModel
    private let repository: AIWritingRepository
    private var task: Task<Void, Never>?

    init(request: AIWritingRequestModel, repository: AIWritingRepository) {
        self.request = request
        self.repository = repository
    }

    deinit {
        task?.cancel()
    }

    func viewDidLoad() {
        generate()
    }

    func generate() {
        task?.cancel()
        onStateChange?(.loading)
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await repository.process(request)
                guard !Task.isCancelled else { return }
                onStateChange?(.loaded(result))
            } catch {
                guard !Task.isCancelled else { return }
                onStateChange?(.error(error.localizedDescription))
            }
        }
    }
}

enum AIWritingResultState: Equatable {
    case loading
    case loaded(String)
    case error(String)
}
