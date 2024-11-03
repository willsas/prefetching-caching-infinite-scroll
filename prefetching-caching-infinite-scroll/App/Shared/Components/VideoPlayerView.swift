//
//  VideoPlayerView.swift
//  prefetching-caching-infinite-scroll
//

import UIKit
import AVFoundation
import Combine

final class TrackingAVPlayer: AVPlayer {
    var playbackStartTime: Date?

    override func play() {
        playbackStartTime = Date()
        super.play()
    }
    
    deinit {
        print("@@@ TrackingAVPlayer deinit")
    }
}

final class VideoPlayerView: UIView {
    
    enum MaxResolutionSelection {
        case screenSize
        case fullHD
        case hd
        case sd
        case `default`
        
        var size: CGSize {
            switch self {
            case .fullHD: return .init(width: 1920, height: 1080)
            case .screenSize:
                let screenSize = UIScreen.main.bounds.size
                return CGSize(width: screenSize.width, height: screenSize.height)
            case .hd: return .init(width: 1280, height: 720)
            case .sd: return .init(width: 640, height: 360)
            case .default: return .zero
            }
        }
    }
    
    private var player: TrackingAVPlayer = TrackingAVPlayer() {
        didSet {
            playerObserver = PlayerObserver(player: player)
            observePlayer()
            setupNetworkMetric()
        }
    }

    private var playerLayer: AVPlayerLayer!
    private let slider = VideoSlider()
    private var playerObserver: PlayerObserver!
    private var cancellables = Set<AnyCancellable>()
    private var pauseButonImage = UIImageView(
        image: .init(systemName: "pause.circle.fill")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
    )
    private let loadingView = LoadingView()
    private var networkMetric: NetworkMetricInfoView? {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func configure(
        with url: URL,
        preferredForwardBufferDuration: Double = 5,
        maxResolution: MaxResolutionSelection = .screenSize
    ) {
        let player = TrackingAVPlayer(url: url)
        player.currentItem!.preferredForwardBufferDuration = preferredForwardBufferDuration
        player.currentItem!.preferredMaximumResolution = maxResolution.size
        player.currentItem!.preferredPeakBitRate = 2_000
        player.currentItem!.preferredPeakBitRateForExpensiveNetworks = 2_000
        self.player = player
        playerLayer.player = player
    }
    
    func resetConfiguration() {
        self.player = .init()
        playerLayer.player = nil
    }

    func play() {
        reset()
        player.play()
        slider.viewModel.bufferValue = playerObserver.loadedBuffer.value
    }
    
    func replay() {
        player.seekToNormalizedTime(0) { [weak self] _ in
            self?.play()
        }
    }

    func pause() {
        player.pause()
    }
    
    private func reset() {
        pauseButonImage.isHidden = true
        loadingView.stopLoading()
        slider.viewModel.value = .zero
        slider.viewModel.bufferValue = .zero
    }

    private func observePlayer() {
        playerObserver.loadedBuffer.sink { [weak self] duration in
            self?.slider.viewModel.bufferValue = duration
        }.store(in: &cancellables)

        playerObserver.currentPosition.sink { [weak self] current in
            guard self?.slider.viewModel.interacting == false else { return }
            self?.slider.viewModel.value = current
            if current == 1 { self?.replay() }
        }.store(in: &cancellables)

        playerObserver.isBuffering.sink { [weak self] isBuffering in
            if isBuffering {
                self?.loadingView.startLoading()
            } else {
                self?.loadingView.stopLoading()
            }
        }.store(in: &cancellables)
        
        playerObserver.isPlaying.sink { [weak self] isPlaying in
            if isPlaying { self?.pauseButonImage.isHidden = true }
        }.store(in: &cancellables)
        
        playerObserver.didEnd.sink { [weak self] in
            self?.replay()
        }.store(in: &cancellables)
    }

    private func configureView() {
        setupPlayer()
        setupSlider()
        setupLongPressGesture()
        setupPauseButton()
        setupLoadingView()
    }

    private func setupPlayer() {
        playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }
    
    private func setupLoadingView() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        loadingView.isHidden = true
    }
    
    private func setupPauseButton() {
        pauseButonImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pauseButonImage)
        NSLayoutConstraint.activate([
            pauseButonImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            pauseButonImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            pauseButonImage.heightAnchor.constraint(equalToConstant: 50),
            pauseButonImage.widthAnchor.constraint(equalToConstant: 50)
        ])
        pauseButonImage.isHidden = true
    }

    private func setupSlider() {
        slider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(slider)
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor),
            slider.heightAnchor.constraint(equalToConstant: 10)
        ])

        slider.valueChangedOnEnd = { [weak self] in
            self?.player.seekToNormalizedTime(Float($0))
        }
    }
    
    private func setupNetworkMetric() {
        networkMetric = NetworkMetricInfoView(player: player)
        guard let networkMetric else { return }
        
        networkMetric.translatesAutoresizingMaskIntoConstraints = false
        addSubview(networkMetric)
        NSLayoutConstraint.activate([
            networkMetric.trailingAnchor.constraint(equalTo: trailingAnchor),
            networkMetric.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        addGestureRecognizer(longPressGesture)
    }

    @objc
    private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            pause()
            pauseButonImage.isHidden = false
            pauseButonImage.addSymbolEffect(.bounce)
        case .ended, .cancelled:
            play()
        default: break
        }
    }
}
