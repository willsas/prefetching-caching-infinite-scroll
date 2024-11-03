//
//  PaginatedScrollCollectionView.swift
//  prefetching-caching-infinite-scroll
//

import Combine
import UIKit

final class PaginatedScrollCollectionView: UICollectionView {

    @Published var onVisibleCells: [UICollectionViewCell] = []
    @Published var onNonVisibleCells: [UICollectionViewCell] = []
    @Published var onVisibleIndexPaths: [IndexPath] = []
    var onLoadMore = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    convenience init() {
        self.init(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout.fullScreenSize()
        )

        contentInsetAdjustmentBehavior = .never
        isPagingEnabled = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        setupLoadMore()
    }

    func updateVisibleCells() {
        layoutIfNeeded()
        let visibleIndexPaths = indexPathsForVisibleItems
        let visibleCells = visibleCells

        let allItems = (0..<numberOfItems(inSection: 0)).map { IndexPath(item: $0, section: 0) }
        let nonVisibleIndexPaths = allItems.filter { !visibleIndexPaths.contains($0) }
        let nonVisibleCells = nonVisibleIndexPaths.compactMap { cellForItem(at: $0) }

        onVisibleCells = visibleCells
        onNonVisibleCells = nonVisibleCells
        self.onVisibleIndexPaths = visibleIndexPaths
    }

    private func setupLoadMore() {
        publisher(for: \.contentOffset)
            .sink { [weak self] contentOffset in
                guard let self else { return }

                let offsetY = contentOffset.y
                let contentHeight = contentSize.height
                let threshold: CGFloat = 100

                if offsetY > contentHeight - frame.size.height - threshold {
                    onLoadMore.send(())
                }
            }.store(in: &cancellables)
    }
}

private extension UICollectionViewCompositionalLayout {
    static func fullScreenSize() -> UICollectionViewCompositionalLayout {
        let section = NSCollectionLayoutSection(
            group: NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalHeight(1)
                ),
                subitems: [
                    .init(
                        layoutSize: .init(
                            widthDimension: .fractionalWidth(1),
                            heightDimension: .fractionalHeight(1)
                        )
                    )
                ]
            )
        )
        return UICollectionViewCompositionalLayout(section: section)
    }
}
