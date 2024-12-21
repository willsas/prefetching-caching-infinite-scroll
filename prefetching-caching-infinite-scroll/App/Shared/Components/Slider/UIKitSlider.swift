
import UIKit

final class UIKitSlider: UISlider, Slidable {
    var direction: Direction {
        .leadingToTrailing
    }

    func fit(_ viewModel: Slider.ViewModel) {
        maximumValue = Float(viewModel.maximumValue)
        minimumValue = Float(viewModel.minimumValue)
        value = Float(viewModel.value)
    }
}
