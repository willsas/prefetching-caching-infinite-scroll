//
//  VideoCollectionViewCell.swift
//  prefetching-caching-infinite-scroll

import Combine
import UIKit

final class VideoCollectionViewCell: UICollectionViewCell {

    var setScrollingEnabled: ((Bool) -> Void)?

    private let playerView = VideoPlayerView()
    private var url: URL?

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
        configureView()
        configureIndexLabel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        playerView.resetConfiguration()
    }

    func configure(with url: URL, index: Int) {
        self.url = url
        indexLabel.text = "index: \(index)"
    }

    func play() {
        guard let url else { return }
        playerView.configure(with: url)
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
