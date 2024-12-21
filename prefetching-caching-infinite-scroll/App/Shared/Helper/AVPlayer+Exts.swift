//
//  AVPlayer+Exts.swift
//  prefetching-caching-infinite-scroll
//

import AVFoundation

extension AVPlayer {
    func seekToNormalizedTime(
        _ normalizedTime: Float,
        toleranceBefore: Float = 0.1,
        toleranceAfter: Float = 0.1,
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        guard let currentItem = currentItem else {
            print("No current item to seek.")
            completionHandler?(false)
            return
        }

        let clampedTime = min(max(normalizedTime, 0.0), 1.0)
        let totalDuration = CMTimeGetSeconds(currentItem.duration)
        let targetTimeInSeconds = totalDuration * Double(clampedTime)

        let targetTime = CMTime(seconds: targetTimeInSeconds, preferredTimescale: 600)
        let toleranceBeforeTime = CMTime(seconds: Double(toleranceBefore), preferredTimescale: 600)
        let toleranceAfterTime = CMTime(seconds: Double(toleranceAfter), preferredTimescale: 600)

        currentItem.seek(
            to: targetTime,
            toleranceBefore: toleranceBeforeTime,
            toleranceAfter: toleranceAfterTime
        ) { completed in
            completionHandler?(completed)
        }
    }
}
