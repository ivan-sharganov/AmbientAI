import Foundation

struct AIWritingRequestModel: Equatable {
    let text: String
    let improve: Bool
    let rewrite: Bool
    let fixGrammar: Bool
    let shorten: Bool
    let translateTo: String?
    let style: String?
}

protocol AIWritingRepository {
    func process(_ request: AIWritingRequestModel) async throws -> String
}
