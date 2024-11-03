import AVFoundation
import AVKit
import Combine
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
    private let playbackDelayLabel = Caption1Label().text("Playback Delay: ... seconds")
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
            playbackDelayLabel
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

        currentItem.publisher(for: \.isPlaybackLikelyToKeepUp).sink { [weak self] in
            guard let self else { return }
            if $0, let startTime = player.playbackStartTime {
                let delay = Date().timeIntervalSince(startTime)
                playbackDelayLabel.text = "Playback Delay: \(String(format: "%.2f", delay)) seconds"
            }
        }.store(in: &cancellables)

        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateBufferSize(for: currentItem)
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
}

private extension UILabel {
    @discardableResult
    func text(_ text: String) -> Self {
        self.text = text
        return self
    }
}
