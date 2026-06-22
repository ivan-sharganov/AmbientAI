import Foundation

protocol PixverseServiceProtocol {
    func loadTemplateCategories() async throws -> [VideoTemplateCategory]
    func generateVideo(request: VideoGenerationRequest) async throws -> Int
    func waitForVideo(videoID: Int) async throws -> URL
}

final class PixverseService: PixverseServiceProtocol {
    private let baseURL: URL
    private let appID: String
    private let bearerToken: String
    private let userIDProvider: () -> String
    private let session: URLSession

    init(
        baseURL: URL = URL(string: "https://nebulaapps.site")!,
        appID: String,
        bearerToken: String,
        userIDProvider: @escaping () -> String,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.appID = appID
        self.bearerToken = bearerToken
        self.userIDProvider = userIDProvider
        self.session = session
    }

    func loadTemplateCategories() async throws -> [VideoTemplateCategory] {
        let url = baseURL
            .appendingPathComponent("pixverse")
            .appendingPathComponent("api/v1/get_templates")
            .appendingPathComponent(appID)
        let data = try await perform(request: authorizedRequest(url: url))
        let response = try JSONDecoder().decode(PixverseCatalogResponse.self, from: data)
        let activeTemplates = response.templates.filter(\.isActive).map(\.model)
        let grouped = Dictionary(grouping: activeTemplates, by: \.category)
        return grouped.keys.sorted().map { category in
            VideoTemplateCategory(title: category, templates: grouped[category] ?? [])
        }
    }

    func generateVideo(request generation: VideoGenerationRequest) async throws -> Int {
        let url = try makeAPIURL(path: "template2video")
        let boundary = "Boundary-\(UUID().uuidString)"
        let quality = try validatedQuality(generation.quality)
        var request = authorizedRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartFormData(boundary: boundary)
            .addingField(name: "template_id", value: String(generation.template.templateID))
            .addingField(name: "duration", value: String(generation.template.duration))
            .addingField(name: "quality", value: quality)
            .addingFile(name: "image", fileName: "photo.jpg", mimeType: "image/jpeg", data: generation.imageData)
            .data

        print("[Pixverse] template2video template_id=\(generation.template.templateID), quality=\(quality), duration=\(generation.template.duration)")
        let data = try await perform(request: request, expectedStatus: 201)
        let response = try JSONDecoder().decode(PixverseGenerationResponse.self, from: data)
        print("[Pixverse] Generation started video_id=\(response.videoID)")
        return response.videoID
    }

    func waitForVideo(videoID: Int) async throws -> URL {
        for _ in 0..<90 {
            try Task.checkCancellation()
            let url = try makeAPIURL(path: "status", extraItems: [URLQueryItem(name: "id", value: String(videoID))])
            let data = try await perform(request: authorizedRequest(url: url))
            let response = try JSONDecoder().decode(PixverseStatusResponse.self, from: data)

            if let value = response.videoURL,
               let url = resolvedVideoURL(from: value) {
                print("PixVerse generated video URL: \(url.absoluteString)")
                return url
            }
            let status = response.status.lowercased()
            if status.contains("fail") || status.contains("error") {
                throw PixverseError.generationFailed(status)
            }
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
        throw PixverseError.generationTimedOut
    }

    private func validatedQuality(_ quality: String) throws -> String {
        let normalized = quality.lowercased()
        let supported = ["360p", "540p", "720p", "1080p"]
        guard supported.contains(normalized) else {
            throw PixverseError.unsupportedQuality(quality)
        }
        return normalized
    }

    private func resolvedVideoURL(from value: String) -> URL? {
        guard let url = URL(string: value) else { return nil }
        return url.scheme == nil ? URL(string: value, relativeTo: baseURL)?.absoluteURL : url
    }

    private func makeAPIURL(path: String, extraItems: [URLQueryItem] = []) throws -> URL {
        let endpoint = baseURL.appendingPathComponent("pixverse").appendingPathComponent("api/v1").appendingPathComponent(path)
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw PixverseError.invalidURL
        }
        components.queryItems = extraItems + [
            URLQueryItem(name: "user_id", value: userIDProvider()),
            URLQueryItem(name: "app_id", value: appID)
        ]
        guard let url = components.url else { throw PixverseError.invalidURL }
        return url
    }

    private func authorizedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func perform(request: URLRequest, expectedStatus: Int? = nil) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PixverseError.invalidResponse }
        let isSuccessful = expectedStatus.map { http.statusCode == $0 } ?? (200..<300).contains(http.statusCode)
        guard isSuccessful else {
            let message = PixverseErrorResponse.message(from: data)
            throw PixverseError.httpError(http.statusCode, message)
        }
        return data
    }
}

private struct PixverseCatalogResponse: Decodable {
    let templates: [PixverseTemplateDTO]
}

private struct PixverseTemplateDTO: Decodable {
    let id: Int
    let templateID: Int64
    let prompt: String
    let name: String
    let category: String
    let qualities: [String]
    let duration: Int
    let previewSmall: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, prompt, name, category, qualities, duration
        case templateID = "template_id"
        case previewSmall = "preview_small"
        case isActive = "is_active"
    }

    var model: VideoTemplate {
        VideoTemplate(
            id: id,
            templateID: templateID,
            title: name,
            prompt: prompt,
            category: category,
            qualities: qualities,
            duration: duration,
            previewURL: previewSmall.flatMap(URL.init(string:))
        )
    }
}

private struct PixverseGenerationResponse: Decodable {
    let videoID: Int
    enum CodingKeys: String, CodingKey { case videoID = "video_id" }
}

private struct PixverseStatusResponse: Decodable {
    let status: String
    let videoURL: String?
    enum CodingKeys: String, CodingKey {
        case status
        case videoURL = "video_url"
    }
}

private enum PixverseErrorResponse {
    static func message(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let detail = object["detail"] else { return nil }
        if let message = detail as? String { return message }
        guard JSONSerialization.isValidJSONObject(detail),
              let detailData = try? JSONSerialization.data(withJSONObject: detail) else { return nil }
        return String(data: detailData, encoding: .utf8)
    }
}

private struct MultipartFormData {
    let boundary: String
    private(set) var data = Data()

    func addingField(name: String, value: String) -> MultipartFormData {
        var copy = self
        copy.data.append("--\(boundary)\r\n")
        copy.data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        copy.data.append("\(value)\r\n")
        return copy
    }

    func addingFile(name: String, fileName: String, mimeType: String, data fileData: Data) -> MultipartFormData {
        var copy = self
        copy.data.append("--\(boundary)\r\n")
        copy.data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        copy.data.append("Content-Type: \(mimeType)\r\n\r\n")
        copy.data.append(fileData)
        copy.data.append("\r\n--\(boundary)--\r\n")
        return copy
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(string.data(using: .utf8)!)
    }
}

enum PixverseError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String?)
    case unsupportedQuality(String)
    case generationFailed(String)
    case generationTimedOut

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid PixVerse URL."
        case .invalidResponse: return "PixVerse returned an invalid response."
        case let .httpError(code, message):
            return message ?? "PixVerse request failed with status \(code)."
        case let .unsupportedQuality(quality):
            return "PixVerse does not support quality \(quality)."
        case let .generationFailed(status): return "Video generation failed: \(status)."
        case .generationTimedOut: return "Video generation timed out."
        }
    }
}
