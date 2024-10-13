
import Foundation

public extension ThumblessSlider {
    enum Scaling {
        case onAxis(_ ratio: CGFloat)
        case againstAxis(_ ratio: CGFloat)
        case none
        case both(onAxis: CGFloat, againstAxis: CGFloat)

        var scaleRatio: ScaleRatio {
            switch self {
            case .none:
                return ScaleRatio(onAxis: 1, againstAxis: 1)
            case let .againstAxis(ratio):
                return ScaleRatio(onAxis: 1, againstAxis: ratio)
            case let .onAxis(ratio):
                return ScaleRatio(onAxis: ratio, againstAxis: 1)
            case let .both(onAxis, againstAxis):
                return ScaleRatio(onAxis: onAxis, againstAxis: againstAxis)
            }
        }
    }
}
