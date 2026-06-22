import AVFoundation
import UIKit

final class RemoteImageLoader {
    static let shared = RemoteImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        cache.countLimit = 100
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    func image(from url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        if ["mp4", "mov", "m4v"].contains(url.pathExtension.lowercased()),
           let thumbnail = await makeVideoThumbnail(url: url) {
            cache(thumbnail, for: url)
            return thumbnail
        }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 60
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                return nil
            }

            let image: UIImage?
            if let decodedImage = UIImage(data: data) {
                image = decodedImage
            } else if response.mimeType?.hasPrefix("video/") == true || ["mp4", "mov", "m4v"].contains(url.pathExtension.lowercased()) {
                image = await makeVideoThumbnail(data: data, fileExtension: url.pathExtension)
            } else {
                image = nil
            }

            guard let image else { return nil }
            cache(image, for: url)
            return image
        } catch {
            return nil
        }
    }

    private func cache(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    private func makeVideoThumbnail(url: URL) async -> UIImage? {
        await Task.detached(priority: .utility) {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 720, height: 720)
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 600)
            do {
                let image = try generator.copyCGImage(
                    at: CMTime(seconds: 0.1, preferredTimescale: 600),
                    actualTime: nil
                )
                return UIImage(cgImage: image)
            } catch {
                return nil
            }
        }.value
    }

    private func makeVideoThumbnail(data: Data, fileExtension: String) async -> UIImage? {
        await Task.detached(priority: .utility) {
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension.isEmpty ? "mp4" : fileExtension)
            do {
                try data.write(to: temporaryURL, options: .atomic)
                defer { try? FileManager.default.removeItem(at: temporaryURL) }

                let asset = AVURLAsset(url: temporaryURL)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 720, height: 720)
                generator.requestedTimeToleranceBefore = .zero
                generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 600)
                let image = try generator.copyCGImage(
                    at: CMTime(seconds: 0.1, preferredTimescale: 600),
                    actualTime: nil
                )
                return UIImage(cgImage: image)
            } catch {
                return nil
            }
        }.value
    }
}
