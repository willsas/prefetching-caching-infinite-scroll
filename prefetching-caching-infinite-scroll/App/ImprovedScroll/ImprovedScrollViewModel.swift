//
//  ImprovedScrollViewModel.swift
//  prefetching-caching-infinite-scroll
//

import UIKit
import Combine

final class VideoList: Hashable {
    let url: URL
    var videoPlayer: VideoPlayerView?
    
    init(url: URL, videoPlayerView: VideoPlayerView? = nil) {
        self.url = url
        self.videoPlayer = videoPlayerView
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
            videos = try await loadVideos()
            prefetch(at: 0)
        } catch {}
        isLoading = false
    }
    
    func loadMore() async {
        guard !isLoadingLoadMore, let lastURL = videos.last?.url else { return }
        let lastIndexBefore = videos.count - 1
        isLoadingLoadMore = true
        do {
            videos.append(contentsOf: try await loadNextVideos(lastURL: lastURL))
            prefetch(at: lastIndexBefore)
        } catch {}
        
        isLoadingLoadMore = false
    }
    
    func prefetch(at currentIndex: Int, toNext next: Int = 3) {
        let adjustedUpperBound = min(currentIndex + next, videos.count)
        (currentIndex..<adjustedUpperBound).forEach { index in
            if videos[index].videoPlayer == nil {
                videos[index].videoPlayer = .make(url: videos[index].url)
            }
        }
        discardPrefetchedData(currentIndex: currentIndex)
        printCurrentVideos()
    }
    
    private func discardPrefetchedData(currentIndex: Int) {
        let adjustedLowerBound = max(0, currentIndex - 1)
        (0..<adjustedLowerBound).forEach { index in
            videos[index].videoPlayer = nil
        }
    }
    
    private func loadVideos() async throws -> [VideoList] {
        let videoLists = try await getVideos().map { VideoList(url: $0.url) }
        if let firstVideo = videoLists.first {
            firstVideo.videoPlayer = .make(url: firstVideo.url)
        }
        return videoLists
    }
    
    private func loadNextVideos(lastURL: URL) async throws -> [VideoList] {
        let videoLists = try await getNextVideos(lastURL).map { VideoList(url: $0.url) }
        if let firstVideo = videoLists.first {
            firstVideo.videoPlayer = .make(url: firstVideo.url)
        }
        return videoLists
    }
    
    private func printCurrentVideos() {
        videos.enumerated().forEach { (index, item) in
            print("@@@ videoplayer: \(item.videoPlayer == nil ? "NIL" : "Exist"),  index: \(index)")
        }
    }
}

extension VideoPlayerView {
    static func make(url: URL) -> VideoPlayerView {
        let videoPlayer = VideoPlayerView()
        videoPlayer.configure(
            with: url,
            preferredForwardBufferDuration: 5,
            maxResolution: .screenSize
        )
        return videoPlayer
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
