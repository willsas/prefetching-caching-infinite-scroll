//

import Foundation

extension Slider {
    enum Option {
        @available(*, deprecated, renamed: "tracks", message: "")
        case trackingBehavior(TrackingBehavior = .trackMovement)
        case tracks(TrackingBehavior = .onTranslation)
    }

    struct Options {
        var trackingBehavior: TrackingBehavior

        init(trackingBehavior: TrackingBehavior = .onTranslation) {
            self.trackingBehavior = trackingBehavior
        }
    }

    enum TrackingBehavior {
        @available(
            *,
            deprecated,
            renamed: "onLocationOnceMoved",
            message: "Use onMovingLocation if respondsImmediately is false, otherwise use onLocation."
        )
        case trackTouch(respondsImmediately: Bool)
        @available(*, deprecated, renamed: "onMovement", message: "")
        case trackMovement
        case onLocation
        case onLocationOnceMoved
        case onTranslation
    }
}

extension Array where Element == Slider.Option {
    var asOptions: Slider.Options {
        var options = Slider.Options()
        for option in self {
            switch option {
            case let .trackingBehavior(behavior), let .tracks(behavior):
                options.trackingBehavior = behavior
            }
        }
        return options
    }
}
