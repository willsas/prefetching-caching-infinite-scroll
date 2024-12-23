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

        collectionView.$onVisibleCells.sink { cells in
            cells
                .compactMap { $0 as? VideoCollectionViewCell }
                .forEach { $0.play() }
        }.store(in: &cancellables)

        collectionView.$onNonVisibleCells.sink { cells in
            cells
                .compactMap { $0 as? VideoCollectionViewCell }
                .forEach { $0.pause() }
        }.store(in: &cancellables)
        
        collectionView.onLoadMore
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                Task { await self?.viewModel.loadMore() }
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
            cell.configure(with: data.url, index: indexPath.row)
            cell.setScrollingEnabled = { [weak self] in
                self?.collectionView.isScrollEnabled = $0
            }
            self?.playFirstCellIfNeeded(cell, indexPath: indexPath)
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
    
    private func playFirstCellIfNeeded(
        _ cell: VideoCollectionViewCell,
        indexPath: IndexPath
    ) {
        if indexPath.row == 0 && firstDequeue == true {
            cell.play()
            firstDequeue = false
        }
    }
}

extension CurrentScrollViewController: UICollectionViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        (scrollView as? PaginatedScrollCollectionView)?.updateVisibleCells()
        scrollView.isScrollEnabled = true
    }
}
