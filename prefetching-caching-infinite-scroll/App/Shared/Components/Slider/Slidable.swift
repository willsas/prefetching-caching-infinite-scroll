import UIKit

protocol Slidable: AnyObject where Self: UIView {
    var direction: Direction { get }

    func fit(_ viewModel: Slider.ViewModel)
}

extension Slidable {
    var layoutDirection: UIUserInterfaceLayoutDirection {
        UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
    }

    func scalar(of vector: CGVector, on direction: Direction) -> CGFloat {
        switch direction {
        case .leadingToTrailing:
            switch layoutDirection {
            case .leftToRight:
                return vector.dx
            case .rightToLeft:
                return -vector.dx
            @unknown default:
                return vector.dx
            }
        case .trailingToLeading:
            switch layoutDirection {
            case .leftToRight:
                return -vector.dx
            case .rightToLeft:
                return vector.dx
            @unknown default:
                return -vector.dx
            }
        case .leftToRight:
            return vector.dx
        case .rightToLeft:
            return -vector.dx
        case .bottomToTop:
            return -vector.dy
        case .topToBottom:
            return vector.dy
        }
    }

    func value(of point: CGPoint, on axis: Direction.Axis) -> CGFloat {
        switch axis {
        case .xAxis:
            return point.x
        case .yAxis:
            return point.y
        }
    }

    func projection(of size: CGSize, on axis: Direction.Axis) -> CGFloat {
        switch axis {
        case .yAxis:
            return size.height
        case .xAxis:
            return size.width
        }
    }

    var sliderValuePositivelyCorrelativeToCoordinateSystem: Bool {
        switch direction {
        case .topToBottom, .leftToRight:
            return true
        case .bottomToTop, .rightToLeft:
            return false
        case .leadingToTrailing:
            switch layoutDirection {
            case .leftToRight:
                return true
            case .rightToLeft:
                return false
            @unknown default:
                return true
            }
        case .trailingToLeading:
            switch layoutDirection {
            case .leftToRight:
                return false
            case .rightToLeft:
                return true
            @unknown default:
                return false
            }
        }
    }
}

extension CGPoint {
    var toVector: CGVector {
        CGVector(dx: x, dy: y)
    }
}

public enum Direction {
    case leadingToTrailing
    case leftToRight
    case trailingToLeading
    case rightToLeft
    case bottomToTop
    case topToBottom

    var axis: Axis {
        switch self {
        case .topToBottom, .bottomToTop:
            return .yAxis
        case .leadingToTrailing, .trailingToLeading, .leftToRight, .rightToLeft:
            return .xAxis
        }
    }

    public enum Axis {
        case xAxis
        case yAxis

        var counterpart: Axis {
            switch self {
            case .xAxis:
                return .yAxis
            case .yAxis:
                return .xAxis
            }
        }
    }
}
