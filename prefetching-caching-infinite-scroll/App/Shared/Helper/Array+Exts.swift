//
//  Array+Exts.swift
//  prefetching-caching-infinite-scroll
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

    subscript(safe range: Range<Int>) -> [Element]? {
        guard range.lowerBound >= 0 else {
            return nil
        }

        let adjustedUpperBound = Swift.min(range.upperBound, count)
        guard adjustedUpperBound > range.lowerBound else {
            return nil
        }

        return Array(self[range.lowerBound..<adjustedUpperBound])
    }
}
