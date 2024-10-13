//
//  CurrentScrollViewModel.swift
//  prefetching-caching-infinite-scroll
//

import UIKit
import Combine

@MainActor
final class CurrentScrollViewModel: ObservableObject {
    @Published var videos: [Video] = []
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
            videos = try await getVideos()
        } catch {}
        isLoading = false
    }
    
    func loadMore() async {
        guard !isLoadingLoadMore, let lastURL = videos.last?.url else { return }
        isLoadingLoadMore = true
        do {
            let nextVideos = try await getNextVideos(lastURL)
            videos.append(contentsOf: nextVideos)
        } catch {}
        
        isLoadingLoadMore = false
    }
}

extension CurrentScrollViewModel {
    static func make() -> CurrentScrollViewModel {
        CurrentScrollViewModel(
            getVideos: { try await VideoListAPI.get() },
            getNextVideos: { try await VideoListAPI.get(after: $0) }
        )
    }
}
