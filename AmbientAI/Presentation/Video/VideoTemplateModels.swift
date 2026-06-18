import UIKit

struct VideoTemplateCategory: Equatable {
    let title: String
    let templates: [VideoTemplate]
}

struct VideoTemplate: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let gradient: [UIColor]
}

enum VideoTemplateCatalog {
    static let categories: [VideoTemplateCategory] = [
        VideoTemplateCategory(title: "Popular", templates: [
            VideoTemplate(id: "clay-fool", title: "Clay Fool", subtitle: "Soft cinematic portrait", symbolName: "person.crop.square", gradient: [UIColor(red: 0.95, green: 0.67, blue: 0.49, alpha: 1), UIColor(red: 0.35, green: 0.18, blue: 0.34, alpha: 1)]),
            VideoTemplate(id: "neon-dream", title: "Neon Dream", subtitle: "Light trails", symbolName: "sparkles", gradient: [UIColor(red: 0.24, green: 0.32, blue: 0.86, alpha: 1), UIColor(red: 0.95, green: 0.29, blue: 0.57, alpha: 1)]),
            VideoTemplate(id: "golden-room", title: "Golden Room", subtitle: "Warm glow", symbolName: "sun.max", gradient: [UIColor(red: 0.99, green: 0.76, blue: 0.33, alpha: 1), UIColor(red: 0.28, green: 0.12, blue: 0.15, alpha: 1)]),
            VideoTemplate(id: "future-girl", title: "Future Girl", subtitle: "Sci-fi avatar", symbolName: "wand.and.stars", gradient: [UIColor(red: 0.56, green: 0.72, blue: 0.95, alpha: 1), UIColor(red: 0.49, green: 0.21, blue: 0.54, alpha: 1)])
        ]),
        VideoTemplateCategory(title: "Funny", templates: [
            VideoTemplate(id: "tiny-chef", title: "Tiny Chef", subtitle: "Cute kitchen", symbolName: "birthday.cake", gradient: [UIColor(red: 0.92, green: 0.56, blue: 0.45, alpha: 1), UIColor(red: 0.34, green: 0.12, blue: 0.19, alpha: 1)]),
            VideoTemplate(id: "dance-pop", title: "Dance Pop", subtitle: "Fast motion", symbolName: "music.note", gradient: [UIColor(red: 0.33, green: 0.77, blue: 0.88, alpha: 1), UIColor(red: 0.88, green: 0.36, blue: 0.67, alpha: 1)])
        ]),
        VideoTemplateCategory(title: "Sad", templates: [
            VideoTemplate(id: "rain-window", title: "Rain Window", subtitle: "Moody scene", symbolName: "cloud.rain", gradient: [UIColor(red: 0.21, green: 0.28, blue: 0.38, alpha: 1), UIColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 1)]),
            VideoTemplate(id: "slow-memory", title: "Slow Memory", subtitle: "Soft blur", symbolName: "moon.stars", gradient: [UIColor(red: 0.42, green: 0.45, blue: 0.65, alpha: 1), UIColor(red: 0.14, green: 0.10, blue: 0.18, alpha: 1)])
        ]),
        VideoTemplateCategory(title: "Trends", templates: [
            VideoTemplate(id: "viral-zoom", title: "Viral Zoom", subtitle: "Social hook", symbolName: "bolt", gradient: [UIColor(red: 0.93, green: 0.27, blue: 0.34, alpha: 1), UIColor(red: 0.22, green: 0.11, blue: 0.37, alpha: 1)]),
            VideoTemplate(id: "anime-cut", title: "Anime Cut", subtitle: "Stylized motion", symbolName: "star", gradient: [UIColor(red: 0.69, green: 0.48, blue: 0.96, alpha: 1), UIColor(red: 0.16, green: 0.16, blue: 0.45, alpha: 1)])
        ]),
        VideoTemplateCategory(title: "Dreamy", templates: [
            VideoTemplate(id: "pastel-air", title: "Pastel Air", subtitle: "Soft clouds", symbolName: "cloud", gradient: [UIColor(red: 0.70, green: 0.82, blue: 0.99, alpha: 1), UIColor(red: 0.91, green: 0.49, blue: 0.70, alpha: 1)]),
            VideoTemplate(id: "flower-loop", title: "Flower Loop", subtitle: "Nature touch", symbolName: "camera.macro", gradient: [UIColor(red: 0.49, green: 0.78, blue: 0.53, alpha: 1), UIColor(red: 0.90, green: 0.47, blue: 0.66, alpha: 1)])
        ])
    ]
}
