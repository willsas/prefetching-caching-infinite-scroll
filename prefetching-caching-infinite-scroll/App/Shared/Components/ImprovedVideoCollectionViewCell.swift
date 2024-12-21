//
//  ImprovedVideoCollectionViewCell.swift
//  prefetching-caching-infinite-scroll
//

import UIKit
import Combine

final class ImprovedVideoCollectionViewCell: UICollectionViewCell {
    
    var setScrollingEnabled: ((Bool) -> Void)?

    private var playerView: VideoPlayerView? {
        didSet {
            oldValue?.removeFromSuperview()
            configurePlayerView()

            indexContainer.removeFromSuperview()
            indexLabel.removeFromSuperview()
            configureIndexLabel()
        }
    }

    private let indexContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let indexLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var scrubbingCancelable: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scrubbingCancelable = nil
    }

    func configure(with player: VideoPlayerView, index: Int) {
        playerView = player
        indexLabel.text = "index: \(index)"
    }

    func play() {
        playerView?.play()
    }

    func pause() {
        playerView?.pause()
    }

    private func configurePlayerView() {
        guard let playerView else { return }
        playerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playerView.topAnchor.constraint(equalTo: topAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setupPlayerScrubbingObserver(playerView)
    }
    
    private func setupPlayerScrubbingObserver(_ playerView: VideoPlayerView) {
        scrubbingCancelable = playerView.$isScrubbing.sink { [weak self] in
            self?.setScrollingEnabled?(!$0)
        }
    }

    private func configureIndexLabel() {
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        indexContainer.translatesAutoresizingMaskIntoConstraints = false

        indexContainer.addSubview(indexLabel)
        addSubview(indexContainer)

        NSLayoutConstraint.activate([
            indexContainer.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 10
            ),
            indexContainer.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: 10
            ),
            indexLabel.leadingAnchor.constraint(equalTo: indexContainer.leadingAnchor),
            indexLabel.trailingAnchor.constraint(equalTo: indexContainer.trailingAnchor),
            indexLabel.topAnchor.constraint(equalTo: indexContainer.topAnchor),
            indexLabel.bottomAnchor.constraint(equalTo: indexContainer.bottomAnchor)
        ])
    }
}
