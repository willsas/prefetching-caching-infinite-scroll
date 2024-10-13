//
//  ImprovedScrollViewModel.swift
//  prefetching-caching-infinite-scroll
//

import UIKit
import Combine

final class VideoList: Hashable {
    let url: URL
    var videoPlayer: VideoPlayerView?
    
    init(url: URL) {
        self.url = url
    }
    
    static func == (lhs: VideoList, rhs: VideoList) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}


@MainActor
final class ImprovedScrollViewModel: ObservableObject {
    @Published var videos: [VideoList] = []
    @Published var isLoading = false
    private var isLoadingLoadMore = false
    private let getVideos: () async throws -> [Video]
    private let getNextVideos: (URL) async throws -> [Video]
    
    init(
        getVideos: @escaping () async throws -> [Video],
        getNextVideos: @escaping (_ lastURL: URL) async throws -> [Video]
    ) {
        self.getVideos = getVideos
        self.getNextVideos = getNextVideos
    }
    
    func load() async {
        isLoading = true
        do {
            var videos = try await getVideos().map { VideoList(url: $0.url) }
            let first = videos.first!
            first.videoPlayer = VideoPlayerView()
            first.videoPlayer?.configure(with: first.url)
            videos[0] = first
            self.videos = videos
            currentIndex(0)
        } catch {}
        isLoading = false
    }
    
    func loadMore() async {
        guard !isLoadingLoadMore, let lastURL = videos.last?.url else { return }
        isLoadingLoadMore = true
        do {
            let nextVideos = try await getNextVideos(lastURL)
                .map {
                    let list = VideoList(url: $0.url)
                    list.videoPlayer = VideoPlayerView()
                    list.videoPlayer?.configure(with: $0.url)
                    return list
                }
            videos.append(contentsOf: nextVideos)
        } catch {}
        
        isLoadingLoadMore = false
    }
    
    func currentIndex(_ index: Int) {
        let chunks = 3
        let startIndex = index + 1
        let endIndex = min(startIndex + chunks, videos.count)
//        let afterVideos = Array(videos[startIndex..<endIndex])
        videos[startIndex..<endIndex].forEach { videoList in
            if videoList.videoPlayer == nil {
                let videoPlayer = VideoPlayerView()
                videoList.videoPlayer = videoPlayer
                videoPlayer.configure(with: videoList.url)
            }
        }
    }
}

extension ImprovedScrollViewModel {
    static func make() -> ImprovedScrollViewModel {
        ImprovedScrollViewModel(
            getVideos: { try await VideoListAPI.get() },
            getNextVideos: { try await VideoListAPI.get(after: $0) }
        )
    }
}
