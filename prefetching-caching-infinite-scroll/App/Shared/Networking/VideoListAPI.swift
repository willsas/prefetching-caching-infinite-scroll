//
//  VideoListAPI.swift
//  prefetching-caching-infinite-scroll
//

import Foundation

struct VideoListResponse: Decodable {
    let urls: [String]
}

struct VideoListAPI {
    static func get(after url: URL? = nil, chunks: Int = 5) async throws -> [Video] {
        do {
            guard url == nil else { return [] }
            let response: VideoListResponse = try await URLSessionNetwork()
                .get(url: URL(string: NetworkingConstant.videoListEndpoint)!)
            return response.urls.map { Video(url: URL(string: $0)!) }
        } catch {
            return getLocally(after: url, chunks: chunks) // fallback to local urls if errors
        }
    }

    private static func getLocally(after url: URL? = nil, chunks: Int = 5) -> [Video] {
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
