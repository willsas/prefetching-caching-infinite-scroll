//
//  VideoPlayerView.swift
//  prefetching-caching-infinite-scroll
//

import UIKit
import AVFoundation
import Combine

final class VideoPlayerView: UIView {
   
    private var player: AVPlayer! {
        didSet {
            playerObserver = PlayerObserver(player: player)
            observePlayer()
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

    func configure(with url: URL) {
        player = AVPlayer(url: url)
        playerLayer.player = player
    }

    func play() {
        reset()
        player.automaticallyWaitsToMinimizeStalling = false
        player.playImmediately(atRate: 1)
        slider.viewModel.bufferValue = playerObserver.loadedBuffer.value
    }

    func pause() {
        player.pause()
    }
    
    func reset() {
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
