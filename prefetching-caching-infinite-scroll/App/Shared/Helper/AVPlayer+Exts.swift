//
//  AVPlayer+Exts.swift
//  prefetching-caching-infinite-scroll
//

import AVFoundation

extension AVPlayer {
    /// Seeks to a specific time in the current item based on a normalized range (0 to 1).
    /// - Parameters:
    ///   - normalizedTime: A value between 0.0 and 1.0 representing the desired position in the
    /// video.
    ///   - toleranceBefore: The tolerance before the target time.
    ///   - toleranceAfter: The tolerance after the target time.
    ///   - completionHandler: A closure that gets called when the seek operation completes.
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

        // Ensure normalizedTime is within bounds [0, 1]
        let clampedTime = min(max(normalizedTime, 0.0), 1.0)

        // Calculate target time based on normalized value
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
            if completed {
                print("Successfully sought to normalized time \(normalizedTime).")
            } else {
                print("Failed to seek to normalized time \(normalizedTime).")
            }
            completionHandler?(completed)
        }
    }
}
