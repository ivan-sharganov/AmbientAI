import UIKit
import AVKit
import Photos

final class VideoResultViewController: UIViewController {
    var onClose: (() -> Void)?
    var onReplace: (() -> Void)?

    private let videoURL: URL
    private let videoView = LoopingVideoView()
    private let dimView = UIControl()
    private let toastView = UIView()
    private let downloadButton = UIButton(type: .system)

    private var playbackURL: URL {
        if videoURL.host == "example.com",
           let fallbackURL = Bundle.main.url(forResource: "fallback_video", withExtension: "mov") {
            return fallbackURL
        }
        return videoURL
    }

    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToast()
        videoView.configure(url: playbackURL)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoView.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoView.pause()
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Color.background
        let background = GradientView(colors: [UIColor(red: 0.05, green: 0.03, blue: 0.07, alpha: 1), DesignSystem.Color.background], startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        view.addSubview(background)
        background.pinToSuperviewEdges()

        let backButton = UIButton(type: .system)
        let backConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: backConfig), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "Result"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let previewContainer = UIView()
        previewContainer.backgroundColor = DesignSystem.Color.card
        previewContainer.layer.cornerRadius = 22
        previewContainer.layer.masksToBounds = true
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewContainer)

        videoView.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(videoView)
        videoView.pinToSuperviewEdges()

        let replaceButton = UIButton(type: .system)
        replaceButton.backgroundColor = UIColor.white.withAlphaComponent(0.52)
        replaceButton.layer.cornerRadius = 23
        replaceButton.tintColor = .white
        replaceButton.setTitle("  Replace", for: .normal)
        replaceButton.setTitleColor(.white, for: .normal)
        replaceButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let replaceConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)
        replaceButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: replaceConfig), for: .normal)
        replaceButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 16)
        replaceButton.addTarget(self, action: #selector(replaceTapped), for: .touchUpInside)
        replaceButton.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(replaceButton)

        let shareButton = makePlainActionButton(title: "Share")
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        configureGradientActionButton(downloadButton, title: "Download")
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)

        let buttonStack = UIStackView(axis: .horizontal, spacing: 16, distribution: .fillEqually)
        buttonStack.addArrangedSubview(shareButton)
        buttonStack.addArrangedSubview(downloadButton)
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            previewContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 22),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            previewContainer.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -18),

            replaceButton.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 18),
            replaceButton.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -16),
            replaceButton.heightAnchor.constraint(equalToConstant: 46),

            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -26),
            buttonStack.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func setupToast() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.62)
        dimView.alpha = 0
        dimView.isHidden = true
        dimView.addTarget(self, action: #selector(hideToast), for: .touchUpInside)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        dimView.pinToSuperviewEdges()

        toastView.backgroundColor = UIColor(red: 0.20, green: 0.15, blue: 0.18, alpha: 0.98)
        toastView.layer.cornerRadius = 20
        toastView.alpha = 0
        toastView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        toastView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toastView)

        let check = UIImageView(image: UIImage(systemName: "checkmark"))
        check.tintColor = DesignSystem.Color.lavender
        check.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Video has been saved\nto your gallery"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        toastView.addSubview(check)
        toastView.addSubview(label)

        NSLayoutConstraint.activate([
            toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 18),
            toastView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62),
            toastView.heightAnchor.constraint(equalToConstant: 144),

            check.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 28),
            check.centerXAnchor.constraint(equalTo: toastView.centerXAnchor),
            check.widthAnchor.constraint(equalToConstant: 34),
            check.heightAnchor.constraint(equalToConstant: 28),

            label.topAnchor.constraint(equalTo: check.bottomAnchor, constant: 18),
            label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -20)
        ])
    }

    private func makePlainActionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = DesignSystem.Color.card
        button.layer.cornerRadius = 21
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        return button
    }

    private func makeGradientActionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        configureGradientActionButton(button, title: title)
        return button
    }

    private func configureGradientActionButton(_ button: UIButton, title: String) {
        button.layer.cornerRadius = 21
        button.clipsToBounds = true
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)

        let gradient = GradientView(colors: [DesignSystem.Color.lavender, DesignSystem.Color.pink], startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
        gradient.isUserInteractionEnabled = false
        button.insertSubview(gradient, at: 0)
        gradient.pinToSuperviewEdges()
    }

    private func showSavedToast() {
        dimView.isHidden = false
        view.bringSubviewToFront(dimView)
        view.bringSubviewToFront(toastView)

        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
            self.dimView.alpha = 1
            self.toastView.alpha = 1
            self.toastView.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            self?.hideToast()
        }
    }

    @objc private func hideToast() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn]) {
            self.dimView.alpha = 0
            self.toastView.alpha = 0
            self.toastView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            self.dimView.isHidden = true
        }
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func replaceTapped() {
        onReplace?()
    }

    @objc private func shareTapped() {
        let controller = UIActivityViewController(activityItems: [playbackURL], applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 80, width: 1, height: 1)
        }
        present(controller, animated: true)
    }

    @objc private func downloadTapped() {
        downloadButton.isEnabled = false
        downloadButton.alpha = 0.55

        Task { [weak self] in
            guard let self else { return }
            do {
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    throw VideoSaveError.photoAccessDenied
                }

                let (localURL, shouldDelete) = try await localVideoURLForSaving()
                defer {
                    if shouldDelete { try? FileManager.default.removeItem(at: localURL) }
                }
                try await saveVideoToPhotoLibrary(at: localURL)
                showSavedToast()
            } catch {
                showSaveError(error)
            }
            downloadButton.isEnabled = true
            downloadButton.alpha = 1
        }
    }

    private func localVideoURLForSaving() async throws -> (URL, Bool) {
        guard !playbackURL.isFileURL else { return (playbackURL, false) }

        let (downloadedURL, response) = try await URLSession.shared.download(from: playbackURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw VideoSaveError.downloadFailed
        }
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(playbackURL.pathExtension.isEmpty ? "mp4" : playbackURL.pathExtension)
        try FileManager.default.moveItem(at: downloadedURL, to: destination)
        return (destination, true)
    }

    private func saveVideoToPhotoLibrary(at url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: VideoSaveError.saveFailed)
                }
            }
        }
    }

    private func showSaveError(_ error: Error) {
        let alert = UIAlertController(title: "Couldn’t save video", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private enum VideoSaveError: LocalizedError {
    case photoAccessDenied
    case downloadFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .photoAccessDenied: return "Allow access to Photos in Settings to save videos."
        case .downloadFailed: return "The video could not be downloaded."
        case .saveFailed: return "The video could not be added to your photo library."
        }
    }
}

private final class LoopingVideoView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(url: URL) {
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        self.player = player
        looper = AVPlayerLooper(player: player, templateItem: item)
        playerLayer.player = player
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }
}

private enum VideoResultPlaceholderFactory {
    static func makeImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cgContext = context.cgContext

            let backgroundColors = [
                UIColor(red: 0.92, green: 0.95, blue: 0.98, alpha: 1).cgColor,
                UIColor(red: 0.75, green: 0.80, blue: 0.88, alpha: 1).cgColor
            ] as CFArray
            let backgroundGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: backgroundColors, locations: [0, 1])!
            cgContext.drawLinearGradient(backgroundGradient, start: CGPoint(x: size.width * 0.2, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])

            drawCurtain(in: cgContext, size: size)
            drawHair(in: cgContext, size: size)
            drawFace(in: cgContext, size: size)
            drawBody(in: cgContext, size: size)
        }
    }

    private static func drawCurtain(in context: CGContext, size: CGSize) {
        context.setFillColor(UIColor.white.withAlphaComponent(0.34).cgColor)
        context.fill(CGRect(x: size.width * 0.70, y: 0, width: size.width * 0.20, height: size.height))
        context.setFillColor(UIColor.white.withAlphaComponent(0.22).cgColor)
        context.fill(CGRect(x: size.width * 0.82, y: 0, width: size.width * 0.06, height: size.height))
    }

    private static func drawHair(in context: CGContext, size: CGSize) {
        let hairRect = CGRect(x: size.width * 0.18, y: size.height * 0.08, width: size.width * 0.62, height: size.height * 0.62)
        context.setFillColor(UIColor(red: 0.80, green: 0.24, blue: 0.05, alpha: 1).cgColor)
        context.fillEllipse(in: hairRect)

        context.setStrokeColor(UIColor(red: 0.55, green: 0.12, blue: 0.03, alpha: 0.55).cgColor)
        context.setLineWidth(8)
        for index in 0..<9 {
            let x = size.width * (0.22 + CGFloat(index) * 0.055)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: size.height * 0.13))
            path.addCurve(to: CGPoint(x: x + 28, y: size.height * 0.72), controlPoint1: CGPoint(x: x - 24, y: size.height * 0.30), controlPoint2: CGPoint(x: x + 52, y: size.height * 0.48))
            context.addPath(path.cgPath)
            context.strokePath()
        }
    }

    private static func drawFace(in context: CGContext, size: CGSize) {
        let faceRect = CGRect(x: size.width * 0.32, y: size.height * 0.16, width: size.width * 0.36, height: size.height * 0.31)
        context.setFillColor(UIColor(red: 1.00, green: 0.72, blue: 0.61, alpha: 1).cgColor)
        context.fillEllipse(in: faceRect)

        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: size.width * 0.40, y: size.height * 0.28, width: 54, height: 34))
        context.fillEllipse(in: CGRect(x: size.width * 0.56, y: size.height * 0.28, width: 54, height: 34))
        context.setFillColor(UIColor(red: 0.11, green: 0.28, blue: 0.42, alpha: 1).cgColor)
        context.fillEllipse(in: CGRect(x: size.width * 0.42, y: size.height * 0.285, width: 28, height: 28))
        context.fillEllipse(in: CGRect(x: size.width * 0.58, y: size.height * 0.285, width: 28, height: 28))

        context.setStrokeColor(UIColor(red: 0.86, green: 0.28, blue: 0.38, alpha: 1).cgColor)
        context.setLineWidth(5)
        let smile = UIBezierPath()
        smile.move(to: CGPoint(x: size.width * 0.45, y: size.height * 0.39))
        smile.addCurve(to: CGPoint(x: size.width * 0.58, y: size.height * 0.39), controlPoint1: CGPoint(x: size.width * 0.49, y: size.height * 0.43), controlPoint2: CGPoint(x: size.width * 0.55, y: size.height * 0.43))
        context.addPath(smile.cgPath)
        context.strokePath()
    }

    private static func drawBody(in context: CGContext, size: CGSize) {
        let jacket = UIBezierPath()
        jacket.move(to: CGPoint(x: size.width * 0.21, y: size.height * 0.50))
        jacket.addLine(to: CGPoint(x: size.width * 0.80, y: size.height * 0.50))
        jacket.addLine(to: CGPoint(x: size.width * 0.90, y: size.height))
        jacket.addLine(to: CGPoint(x: size.width * 0.12, y: size.height))
        jacket.close()
        context.setFillColor(UIColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1).cgColor)
        context.addPath(jacket.cgPath)
        context.fillPath()

        let shirt = UIBezierPath()
        shirt.move(to: CGPoint(x: size.width * 0.40, y: size.height * 0.52))
        shirt.addLine(to: CGPoint(x: size.width * 0.62, y: size.height * 0.52))
        shirt.addLine(to: CGPoint(x: size.width * 0.69, y: size.height))
        shirt.addLine(to: CGPoint(x: size.width * 0.33, y: size.height))
        shirt.close()
        context.setFillColor(UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1).cgColor)
        context.addPath(shirt.cgPath)
        context.fillPath()

        context.setFillColor(UIColor(red: 0.28, green: 0.52, blue: 0.78, alpha: 1).cgColor)
        context.fill(CGRect(x: size.width * 0.30, y: size.height * 0.78, width: size.width * 0.43, height: size.height * 0.22))
    }
}
