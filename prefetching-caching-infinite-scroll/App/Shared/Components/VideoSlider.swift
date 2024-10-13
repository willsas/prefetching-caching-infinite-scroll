//
//  VideoSlider.swift
//  prefetching-caching-infinite-scroll
//

import UIKit

final class VideoSlider: Slider {
    
    convenience init() {
        self.init(
            slider: ThumblessSlider(
                scaling: .both(onAxis: 1, againstAxis: 2),
                cornerRadius: .fixed(0),
                visualEffect: UIVisualEffect(),
                customTintColor: .red
            ),
            bufferSlider: ThumblessSlider(
                scaling: .both(onAxis: 1, againstAxis: 2),
                cornerRadius: .fixed(0),
                visualEffect: UIBlurEffect(style: .regular),
                customTintColor: .gray
            ),
            options: [.tracks(.onLocation)]
        )
        tintColor = .red
    }
}
