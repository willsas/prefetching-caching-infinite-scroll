//
//  VideoListAPI.swift
//  prefetching-caching-infinite-scroll
//

import Foundation

struct VideoListAPI {
    static func get(after url: URL? = nil, chunks: Int = 5) async throws -> [Video] {
        try await Task.sleep(nanoseconds: .random(in: 1_000_000...3_000_000_000))
        let videoList = NetworkingConstant.videoURLs.map { Video(url: URL(string: $0)!) }
        if let url = url, let startIndex = videoList.firstIndex(where: { $0.url == url }) {
            let endIndex = startIndex + chunks
            let range = (startIndex + 1)..<min(endIndex, videoList.count)
            return Array(videoList[range])
        } else {
            return Array(videoList.prefix(chunks))
        }
    }
}
