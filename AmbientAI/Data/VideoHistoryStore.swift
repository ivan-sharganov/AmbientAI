import AVFoundation
import Foundation
import UIKit

struct LocalVideoHistoryItem: Identifiable {
    let id: UUID
    let title: String
    let createdAt: Date
    let videoURL: URL
    let thumbnailURL: URL
}

actor VideoHistoryStore {
    private struct Record: Codable {
        let id: UUID
        let title: String
        let createdAt: Date
        let videoFileName: String
        let thumbnailFileName: String
    }

    private let fileManager: FileManager
    private let session: URLSession
    private let directoryURL: URL
    private let videosDirectoryURL: URL
    private let thumbnailsDirectoryURL: URL
    private let indexURL: URL

    init(fileManager: FileManager = .default, session: URLSession = .shared) {
        self.fileManager = fileManager
        self.session = session
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directoryURL = applicationSupport
            .appendingPathComponent("AmbientAI", isDirectory: true)
            .appendingPathComponent("VideoHistory", isDirectory: true)
        videosDirectoryURL = directoryURL.appendingPathComponent("Videos", isDirectory: true)
        thumbnailsDirectoryURL = directoryURL.appendingPathComponent("Thumbnails", isDirectory: true)
        indexURL = directoryURL.appendingPathComponent("history.json")
    }

    func load() throws -> [LocalVideoHistoryItem] {
        try createDirectoriesIfNeeded()
        let records = try loadRecords()
        return records
            .filter {
                fileManager.fileExists(atPath: videosDirectoryURL.appendingPathComponent($0.videoFileName).path)
                    && fileManager.fileExists(atPath: thumbnailsDirectoryURL.appendingPathComponent($0.thumbnailFileName).path)
            }
            .sorted { $0.createdAt > $1.createdAt }
            .map(makeItem)
    }

    func save(
        videoAt sourceURL: URL,
        title: String,
        fallbackThumbnailData: Data? = nil
    ) async throws -> LocalVideoHistoryItem {
        try createDirectoriesIfNeeded()

        let id = UUID()
        let sourceExtension = sourceURL.pathExtension.lowercased()
        let videoExtension = ["mov", "mp4", "m4v"].contains(sourceExtension) ? sourceExtension : "mp4"
        let videoFileName = "\(id.uuidString).\(videoExtension)"
        let thumbnailFileName = "\(id.uuidString).jpg"
        let videoDestination = videosDirectoryURL.appendingPathComponent(videoFileName)
        let thumbnailDestination = thumbnailsDirectoryURL.appendingPathComponent(thumbnailFileName)

        do {
            try await copyVideo(from: sourceURL, to: videoDestination)
            do {
                try makeThumbnail(for: videoDestination, destination: thumbnailDestination)
            } catch {
                print("[VideoHistory] Frame extraction failed, using source photo: \(error.localizedDescription)")
                try makeFallbackThumbnail(from: fallbackThumbnailData, destination: thumbnailDestination)
            }

            var records = try loadRecords()
            let record = Record(
                id: id,
                title: title,
                createdAt: Date(),
                videoFileName: videoFileName,
                thumbnailFileName: thumbnailFileName
            )
            records.insert(record, at: 0)
            try saveRecords(records)
            return makeItem(record)
        } catch {
            try? fileManager.removeItem(at: videoDestination)
            try? fileManager.removeItem(at: thumbnailDestination)
            throw error
        }
    }

    private func createDirectoriesIfNeeded() throws {
        try fileManager.createDirectory(at: videosDirectoryURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: thumbnailsDirectoryURL, withIntermediateDirectories: true)
    }

    private func loadRecords() throws -> [Record] {
        guard fileManager.fileExists(atPath: indexURL.path) else { return [] }
        return try JSONDecoder().decode([Record].self, from: Data(contentsOf: indexURL))
    }

    private func saveRecords(_ records: [Record]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(records).write(to: indexURL, options: .atomic)
    }

    private func copyVideo(from sourceURL: URL, to destinationURL: URL) async throws {
        if sourceURL.isFileURL {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return
        }

        let (temporaryURL, response) = try await session.download(from: sourceURL)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw VideoHistoryStorageError.downloadFailed
        }
        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
    }

    private func makeThumbnail(for videoURL: URL, destination: URL) throws {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 720)
        let image = try generator.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil)
        guard let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.82) else {
            throw VideoHistoryStorageError.thumbnailCreationFailed
        }
        try data.write(to: destination, options: .atomic)
    }

    private func makeFallbackThumbnail(from data: Data?, destination: URL) throws {
        let image = data.flatMap(UIImage.init(data:)) ?? UIImage(named: "VideoTemplateFallback")
        guard let image,
              let jpegData = image.jpegData(compressionQuality: 0.82) else {
            throw VideoHistoryStorageError.thumbnailCreationFailed
        }
        try jpegData.write(to: destination, options: .atomic)
    }

    private func makeItem(_ record: Record) -> LocalVideoHistoryItem {
        LocalVideoHistoryItem(
            id: record.id,
            title: record.title,
            createdAt: record.createdAt,
            videoURL: videosDirectoryURL.appendingPathComponent(record.videoFileName),
            thumbnailURL: thumbnailsDirectoryURL.appendingPathComponent(record.thumbnailFileName)
        )
    }
}

enum VideoHistoryStorageError: LocalizedError {
    case downloadFailed
    case thumbnailCreationFailed

    var errorDescription: String? {
        switch self {
        case .downloadFailed: return "The generated video could not be downloaded."
        case .thumbnailCreationFailed: return "The video preview could not be created."
        }
    }
}
