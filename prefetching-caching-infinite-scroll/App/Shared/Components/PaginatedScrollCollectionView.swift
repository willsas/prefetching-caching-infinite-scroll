//
//  PaginatedScrollCollectionView.swift
//  prefetching-caching-infinite-scroll
//

import UIKit
import Combine

final class PaginatedScrollCollectionView: UICollectionView {
    
    @Published var visible: [UICollectionViewCell] = []
    @Published var nonVisible: [UICollectionViewCell] = []
    @Published var visibleIndexPaths: [IndexPath] = []
    
    convenience init() {
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
        
        self.init(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout(section: section)
        )
        
        contentInsetAdjustmentBehavior = .never
        isPagingEnabled = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }
    
    func updateVisibleCells() {
        layoutIfNeeded()
        let visibleIndexPaths = indexPathsForVisibleItems
        let visibleCells = visibleCells
        
        let allItems = (0..<numberOfItems(inSection: 0)).map { IndexPath(item: $0, section: 0) }
        let nonVisibleIndexPaths = allItems.filter { !visibleIndexPaths.contains($0) }
        let nonVisibleCells = nonVisibleIndexPaths.compactMap { cellForItem(at: $0) }
        
        self.visible = visibleCells
        self.nonVisible = nonVisibleCells
        self.visibleIndexPaths = visibleIndexPaths
    }
}
