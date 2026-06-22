import CryptoKit
import Foundation

actor VideoPreviewCache {
    static let shared = VideoPreviewCache()

    private let fileManager: FileManager
    private let session: URLSession
    private let directoryURL: URL
    private var downloads: [URL: Task<URL, Error>] = [:]

    init(fileManager: FileManager = .default, session: URLSession = .shared) {
        self.fileManager = fileManager
        self.session = session
        directoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AmbientAI", isDirectory: true)
            .appendingPathComponent("TemplatePreviews", isDirectory: true)
    }

    func localURL(for remoteURL: URL) async throws -> URL {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let destinationURL = cachedURL(for: remoteURL)
        if fileManager.fileExists(atPath: destinationURL.path) {
            return destinationURL
        }
        if let existingDownload = downloads[remoteURL] {
            return try await existingDownload.value
        }

        let session = session
        let fileManager = fileManager
        let task = Task<URL, Error> {
            var request = URLRequest(url: remoteURL)
            request.cachePolicy = .reloadRevalidatingCacheData
            request.timeoutInterval = 120
            let (temporaryURL, response) = try await session.download(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw VideoPreviewCacheError.downloadFailed
            }

            if fileManager.fileExists(atPath: destinationURL.path) {
                try? fileManager.removeItem(at: temporaryURL)
                return destinationURL
            }
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)
            return destinationURL
        }
        downloads[remoteURL] = task

        do {
            let localURL = try await task.value
            downloads[remoteURL] = nil
            return localURL
        } catch {
            downloads[remoteURL] = nil
            throw error
        }
    }

    private func cachedURL(for remoteURL: URL) -> URL {
        let digest = SHA256.hash(data: Data(remoteURL.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let fileExtension = remoteURL.pathExtension.isEmpty ? "mp4" : remoteURL.pathExtension.lowercased()
        return directoryURL.appendingPathComponent(digest).appendingPathExtension(fileExtension)
    }
}

enum VideoPreviewCacheError: LocalizedError {
    case downloadFailed

    var errorDescription: String? {
        "Template preview could not be downloaded."
    }
}
