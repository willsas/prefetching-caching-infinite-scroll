

import AVFoundation
import Combine

final class PlayerObserver {
    private var player: AVPlayer
    private var timeObserverToken: Any?
    private var loadedTimeRangesObserver: NSKeyValueObservation?
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    private var playbackBufferFullObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?

    let loadedBuffer = CurrentValueSubject<Double, Never>(0)
    let currentPosition = CurrentValueSubject<Double, Never>(0)
    let isBuffering = CurrentValueSubject<Bool, Never>(false)
    let isPlaying = CurrentValueSubject<Bool, Never>(false)
    let isLoading = CurrentValueSubject<Bool, Never>(false)
    let didEnd = PassthroughSubject<Void, Never>()

    init(player: AVPlayer) {
        self.player = player
        setupObservers()
    }

    private func setupObservers() {
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrentPosition()
        }

        loadedTimeRangesObserver = player.currentItem?
            .observe(
                \.loadedTimeRanges,
                options: [.new]
            ) { [weak self] _, _ in
                self?.updateLoadedBuffer()
            }

        playbackBufferEmptyObserver = player.currentItem?.observe(
            \.isPlaybackBufferEmpty,
            options: [.new]
        ) { [weak self] _, _ in
            self?.isBuffering.send(true)
        }
        playbackLikelyToKeepUpObserver = player.currentItem?.observe(
            \.isPlaybackLikelyToKeepUp,
            options: [.new]
        ) { [weak self] _, _ in
            self?.isBuffering.send(false)
        }
        playbackBufferFullObserver = player.currentItem?.observe(
            \.isPlaybackBufferFull,
            options: [.new]
        ) { [weak self] _, _ in
            self?.isBuffering.send(false)
        }

        timeControlStatusObserver = player.observe(
            \.timeControlStatus,
            options: [.new, .old],
            changeHandler: { [weak self] playerItem, _ in
                switch playerItem.timeControlStatus {
                case .paused: self?.isPlaying.send(false)
                case .playing: self?.isPlaying.send(true)
                default: break
                }
            }
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidEnd),
            name: AVPlayerItem.didPlayToEndTimeNotification,
            object: player.currentItem
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoStalled),
            name: AVPlayerItem.playbackStalledNotification,
            object: player.currentItem
        )
    }

    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
        loadedTimeRangesObserver?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        playbackBufferFullObserver?.invalidate()
        timeControlStatusObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func updateCurrentPosition() {
        let currentTime = player.currentTime()
        let duration = player.currentItem?.duration.seconds ?? 1.0
        let position = duration > 0 ? currentTime.seconds / duration : 0.0
        currentPosition.send(position)
    }

    private func updateLoadedBuffer() {
        guard let loadedTimeRanges = player.currentItem?.loadedTimeRanges.first?.timeRangeValue
        else { return }

        let bufferedDuration = CMTimeGetSeconds(loadedTimeRanges.start + loadedTimeRanges.duration)
        let totalDuration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)

        let bufferProgress = totalDuration > 0 ? bufferedDuration / totalDuration : 0.0
        loadedBuffer.send(bufferProgress)
    }

    @objc
    private func videoDidEnd(notification: Notification) {
        didEnd.send(())
    }

    @objc
    private func videoStalled(notification: Notification) {
        isBuffering.send(true)
    }
}
