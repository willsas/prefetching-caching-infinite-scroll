//
//  VideoCollectionViewCell.swift
//  prefetching-caching-infinite-scroll

import UIKit

final class VideoCollectionViewCell: UICollectionViewCell {

    private let playerView = VideoPlayerView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerView.reset()
    }

    func configure(with url: URL) {
        playerView.configure(with: url)
    }

    func play() {
        playerView.play()
    }

    func pause() {
        playerView.pause()
    }

    private func configureView() {
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
