import UIKit

class Slider: UIView {
    private(set) var slider: Slidable
    private(set) var bufferSlider: Slidable
    private(set) var options: Options

    var valueChangeHandler: ((Double) -> Void)?
    var valueChangedOnEnd: ((Double) -> Void)?
    var valueChangedOnBegin: ((Double) -> Void)?

    func onValueChange(_ closure: ((Double) -> Void)?) -> Self {
        valueChangeHandler = closure
        return self
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        slider.tintColor = tintColor
        bufferSlider.tintColor = tintColor
    }

    class func DefaultSlider() -> Slidable {
        ThumblessSlider()
    }

    override var semanticContentAttribute: UISemanticContentAttribute {
        get {
            super.semanticContentAttribute
        }
        set {
            super.semanticContentAttribute = newValue
            slider.semanticContentAttribute = newValue
            bufferSlider.semanticContentAttribute = newValue
        }
    }

    public init(
        slider: Slidable = DefaultSlider(),
        bufferSlider: Slidable = DefaultSlider(),
        options: [Option] = []
    ) {
        self.options = options.asOptions
        self.slider = slider
        self.bufferSlider = bufferSlider
        super.init(frame: .zero)
        buildView()
        fit(viewModel)
    }

    private var valueWhenTouchBegan: Double?
    private var touchPointWhenBagan: CGPoint?

    override public init(frame: CGRect) {
        slider = Self.DefaultSlider()
        options = Options()
        bufferSlider = Self.DefaultSlider()
        super.init(frame: frame)
        buildView()
        fit(viewModel)
    }

    public required init?(coder: NSCoder) {
        slider = Self.DefaultSlider()
        options = Options()
        bufferSlider = Self.DefaultSlider()
        super.init(coder: coder)
        buildView()
        fit(viewModel)
    }

    var viewModel = ViewModel() {
        didSet {
            fit(viewModel)
            let value = viewModel.value
            if value != oldValue.value {
                valueChangeHandler?(value)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: self)
        viewModel.interacting = true
        valueWhenTouchBegan = viewModel.value
        touchPointWhenBagan = location
        handleTouchDown(on: location)

        valueChangedOnBegin?(viewModel.value)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        guard
            let valueWhenTouchBegan,
            let touchPointWhenBagan
        else {
            return
        }
        let location = touch.location(in: self)
        switch options.trackingBehavior {
        case .trackMovement, .onTranslation:
            let translation = CGVector(
                dx: location.x - touchPointWhenBagan.x,
                dy: location.y - touchPointWhenBagan.y
            )
            viewModel = updateViewModel(
                viewModel, by: translation, from: valueWhenTouchBegan
            )
        case .trackTouch, .onLocationOnceMoved, .onLocation:
            viewModel = updateViewModel(viewModel, to: location)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        viewModel.interacting = false
        valueWhenTouchBegan = nil
        touchPointWhenBagan = nil

        valueChangedOnEnd?(viewModel.value)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        viewModel.interacting = false
        valueWhenTouchBegan = nil
        touchPointWhenBagan = nil
    }
}

private extension Slider {
    func handleTouchDown(on point: CGPoint) {
        switch options.trackingBehavior {
        case .trackMovement, .onTranslation, .onLocationOnceMoved:
            break
        case .onLocation:
            viewModel = updateViewModel(viewModel, to: point)
        case let .trackTouch(respondsImmediately):
            guard respondsImmediately else {
                return
            }
            viewModel = updateViewModel(viewModel, to: point)
        }
    }

    func updateViewModel(
        _ viewModel: ViewModel,
        by translation: CGVector,
        from valueWhenTouchBegan: Double
    ) -> ViewModel {
        let ratio = slider.scalar(of: translation, on: slider.direction) /
            slider.projection(of: slider.bounds.size, on: slider.direction.axis)
        let valueChange = ratio * (viewModel.maximumValue - viewModel.minimumValue)
        let value = valueWhenTouchBegan + valueChange
        var viewModel = viewModel
        viewModel.value = clampValue(value, ofViewModel: viewModel)
        return viewModel
    }

    func updateViewModel(_ viewModel: ViewModel, to point: CGPoint) -> ViewModel {
        let point = convert(point, to: slider)
        let pointValue = slider.value(of: point, on: slider.direction.axis)
        var ratio = pointValue / slider.projection(
            of: slider.bounds.size,
            on: slider.direction.axis
        )
        if !slider.sliderValuePositivelyCorrelativeToCoordinateSystem {
            ratio = 1 - ratio
        }
        let value = (viewModel.maximumValue + viewModel.minimumValue) * ratio
        var viewModel = viewModel
        viewModel.value = clampValue(value, ofViewModel: viewModel)
        return viewModel
    }

    func clampValue(_ value: Double, ofViewModel viewModel: ViewModel) -> Double {
        if value > viewModel.maximumValue {
            return viewModel.maximumValue
        }
        if value < viewModel.minimumValue {
            return viewModel.minimumValue
        }
        return value
    }
}

private extension Slider {
    func fit(_ viewModel: ViewModel) {
        slider.fit(viewModel)

        var bufferViewModel = viewModel
        bufferViewModel.value = viewModel.bufferValue
        bufferSlider.fit(bufferViewModel)
    }

    func buildView() {
        directionalLayoutMargins = .init(
            top: 20, leading: 20, bottom: 20, trailing: 20
        )

        isMultipleTouchEnabled = false
        addSubview(bufferSlider)
        addSubview(slider)

        slider.tintColor = tintColor
        bufferSlider.tintColor = tintColor

        slider.translatesAutoresizingMaskIntoConstraints = false
        bufferSlider.translatesAutoresizingMaskIntoConstraints = false

        slider.leadingAnchor.constraint(equalTo: leadingAnchor)
            .isActive = true
        slider.trailingAnchor.constraint(equalTo: trailingAnchor)
            .isActive = true
        slider.topAnchor.constraint(equalTo: topAnchor)
            .isActive = true
        slider.bottomAnchor.constraint(equalTo: bottomAnchor)
            .isActive = true

        bufferSlider.leadingAnchor.constraint(equalTo: leadingAnchor)
            .isActive = true
        bufferSlider.trailingAnchor.constraint(equalTo: trailingAnchor)
            .isActive = true
        bufferSlider.topAnchor.constraint(equalTo: topAnchor)
            .isActive = true
        bufferSlider.bottomAnchor.constraint(equalTo: bottomAnchor)
            .isActive = true

        slider.isUserInteractionEnabled = false
        bufferSlider.isUserInteractionEnabled = false
    }
}
