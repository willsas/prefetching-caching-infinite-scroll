import AVFoundation
import AVKit
import Combine
import MachO
import UIKit

final class Caption1Label: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .preferredFont(forTextStyle: .caption1)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class NetworkMetricInfoView: UIView {

    private let bufferSizeLabel = Caption1Label().text("Buffer Size: ... seconds")
    private let playbackDelayLabel = Caption1Label().text("Playback Delay: 0 seconds")
    private let memoryUsageLabel = Caption1Label().text("Memory usage: 0 MB")
    private var cancellables = Set<AnyCancellable>()
    private weak var player: TrackingAVPlayer?

    init(player: TrackingAVPlayer) {
        super.init(frame: .zero)
        self.player = player
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
            playbackDelayLabel,
            memoryUsageLabel
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

    private func configureBindings(with player: TrackingAVPlayer) {
        guard let currentItem = player.currentItem else { return }

        currentItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .filter { $0 }
            .first()
            .sink { [weak self] _ in
                guard let self, let startTime = player.playbackStartTime else { return }
                let delay = Date().timeIntervalSince(startTime)
                playbackDelayLabel.text = "Playback Delay: \(String(format: "%.4f", delay)) seconds"
            }.store(in: &cancellables)

        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateBufferSize(for: currentItem)
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
    }

    private func updateBufferSize(for item: AVPlayerItem?) {
        guard let item = item else { return }

        let bufferSize = item.loadedTimeRanges.reduce(0) { result, timeRange in
            result + CMTimeGetSeconds(timeRange.timeRangeValue.duration)
        }
        bufferSizeLabel.text = "Buffer Size: \(Int(bufferSize)) seconds"
    }

    private func updateMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        memoryUsageLabel
            .text =
            "Memory usage: \(String(format: "%.0f", memoryUsage.used)) MB"
    }

    private func getMemoryUsage() -> (used: Float, total: Float) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedBytes = Float(info.resident_size)
            let totalBytes = Float(ProcessInfo.processInfo.physicalMemory)
            return (used: usedBytes / 1024 / 1024, total: totalBytes / 1024 / 1024) // Convert to MB
        } else {
            return (used: 0, total: 0) // Error handling
        }
    }
}

private extension UILabel {
    @discardableResult
    func text(_ text: String) -> Self {
        self.text = text
        return self
    }
}
