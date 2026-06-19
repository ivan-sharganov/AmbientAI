import UIKit

struct VideoTemplateCategory: Equatable {
    let title: String
    let templates: [VideoTemplate]
}

struct VideoTemplate: Equatable, Identifiable {
    let id: Int
    let templateID: Int64
    let title: String
    let prompt: String
    let category: String
    let qualities: [String]
    let duration: Int
    let previewURL: URL?

    var subtitle: String { prompt }
    var symbolName: String { "sparkles.rectangle.stack" }

    var gradient: [UIColor] {
        let palettes: [[UIColor]] = [
            [UIColor(red: 0.95, green: 0.55, blue: 0.45, alpha: 1), UIColor(red: 0.30, green: 0.12, blue: 0.28, alpha: 1)],
            [UIColor(red: 0.42, green: 0.62, blue: 0.96, alpha: 1), UIColor(red: 0.75, green: 0.25, blue: 0.58, alpha: 1)],
            [UIColor(red: 0.96, green: 0.72, blue: 0.32, alpha: 1), UIColor(red: 0.27, green: 0.13, blue: 0.20, alpha: 1)],
            [UIColor(red: 0.50, green: 0.78, blue: 0.68, alpha: 1), UIColor(red: 0.28, green: 0.18, blue: 0.48, alpha: 1)]
        ]
        return palettes[abs(id) % palettes.count]
    }
}

struct VideoGenerationRequest {
    let template: VideoTemplate
    let imageData: Data
    let quality: String
}
