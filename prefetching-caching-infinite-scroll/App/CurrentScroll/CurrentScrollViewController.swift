//
//  CurrentScrollViewController.swift
//  prefetching-caching-infinite-scroll

import Combine
import UIKit

final class CurrentScrollViewController: UIViewController {

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Video>
    enum Section: Hashable { case main }

    private var collectionView = PaginatedScrollCollectionView()
    private lazy var dataSource = makeDataSource()
    private var firstDequeue = true
    private var cancellables = Set<AnyCancellable>()
    private let viewModel = CurrentScrollViewModel.make()
    private let loadingView = LoadingView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBinding()
        setupCollectionView()
        setupLoadingView()
        Task { [weak self] in await self?.viewModel.load() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        collectionView.visibleCells
            .compactMap { $0 as? VideoCollectionViewCell }
            .forEach { $0.pause() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.visibleCells
            .compactMap { $0 as? VideoCollectionViewCell }
            .forEach { $0.play() }
    }

    private func setupBinding() {
        viewModel.$videos.sink { [weak self] in self?.populate($0) }.store(in: &cancellables)
        viewModel.$isLoading.sink { [weak self] isLoading in
            if isLoading {
                self?.loadingView.startLoading()
            } else {
                self?.loadingView.stopLoading()
            }
        }.store(in: &cancellables)
    }
    
    private func setupLoadingView() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        loadingView.isHidden = true
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        collectionView.$visible.sink { cells in
            cells
                .compactMap { $0 as? VideoCollectionViewCell }
                .forEach { $0.play() }
        }.store(in: &cancellables)

        collectionView.$nonVisible.sink { cells in
            cells
                .compactMap { $0 as? VideoCollectionViewCell }
                .forEach { $0.pause() }
        }.store(in: &cancellables)
    }

    private func populate(_ videos: [Video]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Video>()
        snapshot.appendSections([.main])
        snapshot.appendItems(videos, toSection: .main)
        dataSource.apply(snapshot)
    }

    private func makeDataSource() -> DataSource {
        let cellRegistration = UICollectionView.CellRegistration<
            VideoCollectionViewCell,
            Video
        > { [weak self] cell, indexPath, data in
            cell.configure(with: data.url)

            if indexPath.row == 0 && self?.firstDequeue == true {
                cell.play()
                self?.firstDequeue = false
            }
        }

        let dataSource = DataSource(
            collectionView: collectionView
        ) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: itemIdentifier
            )
        }

        return dataSource
    }
}

extension CurrentScrollViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        (scrollView as? PaginatedScrollCollectionView)?.updateVisibleCells()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let threshold: CGFloat = 100

        if offsetY > contentHeight - scrollView.frame.size.height - threshold {
            Task { await viewModel.loadMore() }
        }
    }
}
