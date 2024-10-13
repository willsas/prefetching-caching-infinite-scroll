//
//  ImprovedVideoCollectionViewCell.swift
//  prefetching-caching-infinite-scroll
//

import UIKit

final class ImprovedVideoCollectionViewCell: UICollectionViewCell {

    private var playerView = VideoPlayerView() {
        didSet {
            oldValue.removeFromSuperview()
            configurePlayerView()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configurePlayerView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerView.reset()
    }

//    func configure(with url: URL) {
//        playerView.configure(with: url)
//    }
    
    func configure(with player: VideoPlayerView) {
        playerView = player
    }

    func play() {
        playerView.play()
    }

    func pause() {
        playerView.pause()
    }

    private func configurePlayerView() {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playerView.topAnchor.constraint(equalTo: topAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
