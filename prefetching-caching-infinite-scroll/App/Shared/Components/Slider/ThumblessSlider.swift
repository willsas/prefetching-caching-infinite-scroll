
import UIKit

open class ThumblessSlider: UIView, Slidable {
    public enum CornerRadius {
        case full
        case fixed(CGFloat)
    }

    public struct ScaleRatio {
        @available(*, deprecated, renamed: "onAxis", message: "") public var ratioOnAxis: CGFloat {
            onAxis
        }

        @available(
            *,
            deprecated,
            renamed: "againstAxis",
            message: ""
        ) public var ratioAgainstAxis: CGFloat {
            againstAxis
        }

        @available(*, deprecated, renamed: "init(onAxis:againstAxis:)", message: "")
        public init(ratioOnAxis: CGFloat, ratioAgainstAxis: CGFloat) {
            onAxis = ratioOnAxis
            againstAxis = ratioAgainstAxis
        }

        public var onAxis: CGFloat
        public var againstAxis: CGFloat
        public init(onAxis: CGFloat, againstAxis: CGFloat) {
            self.onAxis = onAxis
            self.againstAxis = againstAxis
        }
    }

    public let direction: Direction

    public let scaleRatio: ScaleRatio

    public let cornerRadius: CornerRadius
    open var visualEffect: UIVisualEffect? {
        didSet {
            visualEffectView.effect = visualEffect
        }
    }

    public var customTintColor: UIColor?

    open class var defaultScaleRatio: ScaleRatio {
        ScaleRatio(onAxis: 1, againstAxis: 1)
    }

    open class var defaultDirection: Direction {
        .leadingToTrailing
    }

    open class var defaultCornerRadius: CornerRadius {
        .full
    }

    open class var defaultVisualEffect: UIVisualEffect {
        UIBlurEffect(style: .systemUltraThinMaterial)
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        fillingView?.backgroundColor = customTintColor ?? tintColor
    }

    struct VisualEffectViewConstraints {
        var width: NSLayoutConstraint!
        var height: NSLayoutConstraint!

        var scaledWidth: NSLayoutConstraint!
        var scaledHeight: NSLayoutConstraint!

        var scaled: Bool {
            get {
                width.isActive == false && scaledWidth.isActive
            }
            set {
                let scaled = newValue
                if scaled {
                    width.isActive = false
                    height.isActive = false
                    scaledWidth.isActive = true
                    scaledHeight.isActive = true
                } else {
                    scaledWidth.isActive = false
                    scaledHeight.isActive = false
                    width.isActive = true
                    height.isActive = true
                }
            }
        }
    }

    var visualEffectViewConstraints = VisualEffectViewConstraints()

    public init(
        direction: Direction = defaultDirection,
        scaleRatio: ScaleRatio = defaultScaleRatio,
        cornerRadius: CornerRadius = defaultCornerRadius,
        visualEffect: UIVisualEffect = defaultVisualEffect,
        customTintColor: UIColor? = nil
    ) {
        self.direction = direction
        self.scaleRatio = scaleRatio
        self.cornerRadius = cornerRadius
        self.visualEffect = visualEffect
        self.customTintColor = customTintColor
        super.init(frame: .zero)
        buildView()
    }

    public convenience init(
        direction: Direction = defaultDirection,
        scaling: Scaling,
        cornerRadius: CornerRadius = defaultCornerRadius,
        visualEffect: UIVisualEffect = defaultVisualEffect,
        customTintColor: UIColor? = nil
    ) {
        self.init(
            direction: direction,
            scaleRatio: scaling.scaleRatio,
            cornerRadius: cornerRadius,
            visualEffect: visualEffect,
            customTintColor: customTintColor
        )
    }

    public required init?(coder: NSCoder) {
        direction = Self.defaultDirection
        scaleRatio = Self.defaultScaleRatio
        cornerRadius = Self.defaultCornerRadius
        visualEffect = Self.defaultVisualEffect
        super.init(coder: coder)
        buildView()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        fitValueRatio(valueRatio, when: isInteracting)
    }

    override open func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        updateCornerRadius(getCornerRadius())
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else {
            return
        }
        resetVariableAndFixedConstraint()
    }

    override open var semanticContentAttribute: UISemanticContentAttribute {
        get {
            super.semanticContentAttribute
        }
        set {
            super.semanticContentAttribute = newValue
            visualEffectView.semanticContentAttribute = newValue
            visualEffectView.contentView.semanticContentAttribute = newValue
            fillingView.semanticContentAttribute = newValue
        }
    }

    private weak var fillingView: UIView!
    private weak var variableConstraint: NSLayoutConstraint?
    private weak var fixedConstraint: NSLayoutConstraint?
    private weak var visualEffectView: UIVisualEffectView!

    private var isInteracting: Bool = false

    public var valueRatio: CGFloat = 0 {
        didSet {
            fitValueRatio(valueRatio, when: isInteracting)
        }
    }

    private func getCornerRadius() -> CGFloat {
        switch cornerRadius {
        case let .fixed(fixedValue):
            return fixedValue
        case .full:
            return projection(
                of: visualEffectView.frame.size,
                on: direction.axis.counterpart
            ) / 2
        }
    }

    private func updateCornerRadius(_ cornerRadius: CGFloat) {
        if layer.cornerRadius != cornerRadius {
            layer.cornerRadius = cornerRadius
            visualEffectView.layer.cornerRadius = cornerRadius
        }
    }

    public func fit(_ viewModel: Slider.ViewModel) {
        let valueRatio = viewModel.value / (viewModel.maximumValue + viewModel.minimumValue)
        if self.valueRatio != valueRatio {
            self.valueRatio = valueRatio
        }

        isInteracting = viewModel.interacting
        let shouldScale = viewModel.interacting
        if visualEffectViewConstraints.scaled != shouldScale {
            visualEffectViewConstraints.scaled = shouldScale
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: {
                    if shouldScale {
                        return 0.8
                    } else {
                        return 0.55
                    }
                }(),
                initialSpringVelocity: {
                    if shouldScale {
                        return 20
                    } else {
                        return 0
                    }
                }()
            ) { [weak self] in
                self?.layoutIfNeeded()
            }
        }
    }
}

private extension ThumblessSlider {
    func getFillingViewLength(
        byRatio ratio: CGFloat,
        when interacting: Bool
    ) -> CGFloat {
        let size = bounds.size
        if interacting {
            return ratio * scaleRatio.onAxis * projection(of: size, on: direction.axis)
        } else {
            return ratio * projection(of: size, on: direction.axis)
        }
    }

    func fitValueRatio(_ valueRatio: CGFloat, when isInteracting: Bool) {
        let fillingLength = getFillingViewLength(
            byRatio: valueRatio,
            when: isInteracting
        )
        if variableConstraint?.constant != fillingLength {
            variableConstraint?.constant = fillingLength
        }
    }
}

private extension ThumblessSlider {
    func buildView() {
        layer.masksToBounds = false

        let visualEffectView = UIVisualEffectView(effect: visualEffect)
        self.visualEffectView = visualEffectView
        visualEffectView.layer.cornerCurve = .continuous
        visualEffectView.clipsToBounds = true
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView)
        visualEffectView.centerYAnchor.constraint(equalTo: centerYAnchor)
            .isActive = true
        visualEffectView.centerXAnchor.constraint(equalTo: centerXAnchor)
            .isActive = true

        visualEffectViewConstraints.width = visualEffectView.widthAnchor
            .constraint(equalTo: widthAnchor)
        visualEffectViewConstraints.height = visualEffectView.heightAnchor
            .constraint(equalTo: heightAnchor)
        visualEffectViewConstraints.scaledWidth = visualEffectView.widthAnchor.constraint(
            equalTo: widthAnchor,
            multiplier: {
                switch direction.axis {
                case .xAxis:
                    return scaleRatio.onAxis
                case .yAxis:
                    return scaleRatio.againstAxis
                }
            }()
        )
        visualEffectViewConstraints.scaledHeight = visualEffectView.heightAnchor.constraint(
            equalTo: heightAnchor,
            multiplier: {
                switch direction.axis {
                case .xAxis:
                    return scaleRatio.againstAxis
                case .yAxis:
                    return scaleRatio.onAxis
                }
            }()
        )
        visualEffectViewConstraints.scaled = false

        let fillingView = UIView()
        self.fillingView = fillingView
        fillingView.backgroundColor = customTintColor ?? tintColor
        visualEffectView.contentView.addSubview(fillingView)
        fillingView.translatesAutoresizingMaskIntoConstraints = false

        switch direction.axis {
        case .xAxis:
            fillingView.topAnchor.constraint(equalTo: visualEffectView.contentView.topAnchor)
                .isActive = true
            fillingView.bottomAnchor.constraint(equalTo: visualEffectView.contentView.bottomAnchor)
                .isActive = true
        case .yAxis:
            fillingView.leadingAnchor
                .constraint(equalTo: visualEffectView.contentView.leadingAnchor)
                .isActive = true
            fillingView.trailingAnchor
                .constraint(equalTo: visualEffectView.contentView.trailingAnchor)
                .isActive = true
        }
    }

    func resetVariableAndFixedConstraint() {
        let variableConstraint: NSLayoutConstraint = {
            switch direction.axis {
            case .xAxis:
                return fillingView.widthAnchor.constraint(equalToConstant: 0)
            case .yAxis:
                return fillingView.heightAnchor.constraint(equalToConstant: 0)
            }
        }()

        self.variableConstraint?.isActive = false
        variableConstraint.isActive = true
        self.variableConstraint = variableConstraint

        let fixedConstraint: NSLayoutConstraint = {
            switch direction {
            case .leadingToTrailing:
                return fillingView.leadingAnchor
                    .constraint(equalTo: visualEffectView.contentView.leadingAnchor)
            case .trailingToLeading:
                return fillingView.trailingAnchor
                    .constraint(equalTo: visualEffectView.contentView.trailingAnchor)
            case .leftToRight:
                return fillingView.leftAnchor
                    .constraint(equalTo: visualEffectView.contentView.leftAnchor)
            case .rightToLeft:
                return fillingView.rightAnchor
                    .constraint(equalTo: visualEffectView.contentView.rightAnchor)
            case .topToBottom:
                return fillingView.topAnchor
                    .constraint(equalTo: visualEffectView.contentView.topAnchor)
            case .bottomToTop:
                return fillingView.bottomAnchor
                    .constraint(equalTo: visualEffectView.contentView.bottomAnchor)
            }
        }()
        self.fixedConstraint?.isActive = false
        fixedConstraint.isActive = true
        self.fixedConstraint = fixedConstraint
    }
}
