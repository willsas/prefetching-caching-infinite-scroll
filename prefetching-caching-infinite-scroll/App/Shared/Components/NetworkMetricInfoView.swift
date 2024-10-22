import AVKit
import Combine
import UIKit

final class Caption1label: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .preferredFont(forTextStyle: .caption1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class NetworkMetricInfoView: UIView {

    private let bufferSizeLabel = Caption1label()
    private let bitrateLabel = Caption1label()
    private let playingStatusLabel = Caption1label()
    private let resolutionLabel = Caption1label()
    private let downloadSpeedLabel = Caption1label()

    private var cancellables = Set<AnyCancellable>()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        setupView()
        configureBindings(with: player)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.cornerRadius = 10
        layer.masksToBounds = true

        let stackView = UIStackView(arrangedSubviews: [
            bufferSizeLabel,
//            bitrateLabel,
//            playingStatusLabel,
//            resolutionLabel,
//            downloadSpeedLabel
        ])

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    private func configureBindings(with player: AVPlayer) {
        // Monitor current item status
        let currentItem = player.currentItem

        // Observe the status of the current item
        currentItem?.publisher(for: \.status)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    Task { [weak self] in
                        await self?.updateMetrics(for: currentItem)
                    }
                }
            }
            .store(in: &cancellables)

        // Update buffer size continuously
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateBufferSize(for: currentItem)
            }
            .store(in: &cancellables)

        // Observe download speed
        NetworkMonitor.shared.$downloadSpeed
            .sink { [weak self] speed in
                self?.downloadSpeedLabel.text = "Download Speed: \(speed)"
            }
            .store(in: &cancellables)
    }

    private func updateMetrics(for item: AVPlayerItem?) async {
        guard let item = item else { return }

        // Update bitrate
        do {
            if let bitrate = try await item.asset.loadTracks(withMediaType: .video).first?.load(.estimatedDataRate) {
                bitrateLabel.text = "Bitrate: \(bitrate / 1000) kbps" // Convert to kbps
            }
            
        } catch {
            bitrateLabel.text = "Bitrate: N/A"
        }

        // Update resolution
        do {
            let tracks = try await item.asset.loadTracks(withMediaType: .video)
            if let videoTrack = tracks.first {
                let size = try await videoTrack.load(.naturalSize)
                resolutionLabel.text = "Resolution: \(size.width)x\(size.height)"
            } else {
                resolutionLabel.text = "Resolution: N/A"
            }
        } catch {
            resolutionLabel.text = "Resolution: N/A"
        }

        // Update playing status
//        playingStatusLabel.text = item.rate != 0 ? "Playing Status: Playing" : "Playing Status: Paused/Stopped"
    }

    private func updateBufferSize(for item: AVPlayerItem?) {
        guard let item = item else { return }

        let bufferSize = item.loadedTimeRanges.reduce(0) { result, timeRange in
            result + CMTimeGetSeconds(timeRange.timeRangeValue.duration)
        }
        bufferSizeLabel.text = "Buffer Size: \(Int(bufferSize)) seconds"
    }
}

class NetworkMonitor {
    static let shared = NetworkMonitor()

    // Publisher for download speed
    @Published var downloadSpeed: String = "0.0 Mbps"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        // Here you would typically start monitoring your network traffic.
        
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .map { [weak self] _ in
                self?.simulateDownloadSpeed() ?? "0.0 Mbps"
            }
            .assign(to: &$downloadSpeed)
    }

    private func simulateDownloadSpeed() -> String {
        // This function simulates varying download speeds.
        let speed = Double.random(in: 0.5...5.0) // Random speed between 0.5 and 5.0 Mbps
        return String(format: "%.1f Mbps", speed)
    }
}
