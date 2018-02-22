//
//  Protractor.swift
//  Protractor
//
//  Created by Gonzo Fialho on 14/02/18.
//  Copyright © 2018 Gonzo Fialho. All rights reserved.
//

import UIKit

extension BinaryInteger {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension UIImage {
    static func plusOrMinusButton(color: UIColor, isPlus: Bool, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let lineWidth: CGFloat = 1.5
        let rect = UIBezierPath(
            roundedRect: CGRect(
                origin: CGPoint(x: lineWidth/2, y: lineWidth/2),
                size: CGSize(width: size.width - lineWidth, height: size.height - lineWidth)),
            cornerRadius: 6)
        rect.lineWidth = lineWidth
        color.set()
        rect.stroke()

        let minus = UIBezierPath(rect: CGRect(x: size.width/2 - size.width/4,
                                              y: size.height/2 - lineWidth*1.5/2,
                                              width: size.width * 0.5,
                                              height: lineWidth * 1.5))
        minus.fill()
        if isPlus {
            let plus = UIBezierPath(rect: CGRect(x: size.width/2 - lineWidth*1.5/2,
                                                 y: size.height/2 - size.height/4,
                                                 width: lineWidth * 1.5,
                                                 height: size.height * 0.5))
            plus.fill()
        }

        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
}

@IBDesignable
public class Protractor: UIControl {

    public var angleRange = Double(0)...Double(180) {
        didSet {
            assert(angleRange.lowerBound >= 0, "angleRange.lowerBound must be >= 0")
            assert(angleRange.upperBound <= 180, "angleRange.upperBound must be <= 180")

            calculatePossibleValues()
            setNeedsDisplay()
        }
    }

    private var possibleValues: StrideThrough<Double>!

    private var radAngleRange: ClosedRange<CGFloat> {
        let lowerBound = angleRange.lowerBound - 180
        let upperBound = angleRange.upperBound - 180
        return CGFloat(lowerBound.degreesToRadians)...CGFloat(upperBound.degreesToRadians)
    }

    public var stepValue = Double(1) {
        didSet {
            calculatePossibleValues()
        }
    }
    public var value: Double {
        get {
            var angle = Double(needleAngle.radiansToDegrees + 180)
            angle = max(angleRange.lowerBound, min(angleRange.upperBound, angle))
            let value = possibleValues.min { abs($0 - angle) < abs($1 - angle) }!
            return value
        }
        set {
            var value = max(angleRange.lowerBound, min(angleRange.upperBound, newValue))
            value = possibleValues.min { abs($0 - value) < abs($1 - value) }!
            needleAngle = CGFloat(value - 180).degreesToRadians
        }
    }

    public override var tintColor: UIColor! {
        didSet {
            updatePlusMinusImages()
        }
    }

    lazy private var plusButton: UIButton = {
        return createButton(isPlus: true)
    }()

    lazy private var minusButton: UIButton = {
        return createButton(isPlus: false)
    }()

    private var isTouching: Bool = false {
        didSet {
            setNeedsDisplay()
            if isTouching != oldValue {
                if isTouching {
                    sendActions(for: .editingDidBegin)
                } else {
                    sendActions(for: .editingDidEnd)
                }
            }
        }
    }

    private var needleAngle = CGFloat(0) {
        didSet {
            updatePlusMinusButtons()
            setNeedsDisplay()
        }
    }

    private var arcCenter: CGPoint {
        return CGPoint(x: bounds.width/2, y: bounds.height * 0.9)
    }

    private var radius: CGFloat {
        return min(bounds.width / 2, bounds.height) * 0.9
    }

    public var shouldDrawSeparatorLine: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    public var shouldDrawValueLabel: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    public var linesStep = CGFloat(10.degreesToRadians) {
        didSet {
            setNeedsDisplay()
        }
    }

    public var font: UIFont = UIFont.systemFont(ofSize: 17) {
        didSet {
            setNeedsDisplay()
        }
    }

    private var valueTimer: Timer?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        calculatePossibleValues()
        backgroundColor = UIColor(red: 207/255, green: 211/255, blue: 216/255, alpha: 1)

        addGestureRecognizers()

        updatePlusMinusButtons()
        updatePlusMinusImages()
    }

    public convenience init() {
        self.init(frame: CGRect.zero)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    private func createButton(isPlus: Bool) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = isPlus ? 1 : -1
        let size = CGSize(width: 44, height: 44)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        var constraints = [NSLayoutConstraint]()

        let format = isPlus ? "[button(width@1000)]-|" : "|-[button(width@1000)]"
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: format,
                                                                      options: [],
                                                                      metrics: ["width": size.width],
                                                                      views: ["button": button]))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[button(height@1000)]",
                                                                      options: [],
                                                                      metrics: ["height": size.height],
                                                                      views: ["button": button]))

        NSLayoutConstraint.activate(constraints)

        return button
    }

    private func addGestureRecognizers() {
        let buttons = [plusButton, minusButton]
        for button in buttons {
            button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Protractor.buttonTapped(_:))))
            button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(Protractor.buttonLongPressed(_:))))
        }
    }

    fileprivate func calculatePossibleValues() {
        possibleValues = stride(from: angleRange.lowerBound, through: angleRange.upperBound, by: stepValue)
    }

    private func updatePlusMinusButtons() {
        minusButton.isEnabled = value != possibleValues?.min()
        plusButton.isEnabled = value != possibleValues?.max()
    }

    // MARK: - Draw

    private func updatePlusMinusImages() {
        let size = CGSize(width: 44, height: 44)
        minusButton.setBackgroundImage(UIImage.plusOrMinusButton(color: tintColor, isPlus: false, size: size), for: .normal)
        plusButton.setBackgroundImage(UIImage.plusOrMinusButton(color: tintColor, isPlus: true, size: size), for: .normal)
    }

    fileprivate func drawArc() {
        let arc = UIBezierPath(arcCenter: arcCenter,
                               radius: radius,
                               startAngle: radAngleRange.lowerBound,
                               endAngle: radAngleRange.upperBound,
                               clockwise: true)
        arc.lineWidth = 1
        arc.stroke()

        drawLines(angles: [radAngleRange.lowerBound, radAngleRange.upperBound])
    }

    fileprivate func drawLines(angles: [CGFloat]? = nil) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        ctx.translateBy(x: arcCenter.x, y: arcCenter.y)
        let drawAngles = angles ?? Array(stride(from: radAngleRange.lowerBound, through: radAngleRange.upperBound, by: linesStep))
        for lineAngle in drawAngles {
            let line = UIBezierPath()
            line.lineWidth = 1
            line.move(to: CGPoint.zero)
            let endPoint = CGPoint(
                x: radius * cos(lineAngle),
                y: radius * sin(lineAngle))
            line.addLine(to: endPoint)
            line.stroke()
        }
        ctx.restoreGState()
    }

    fileprivate func drawQuarterAngles() {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        ctx.translateBy(x: arcCenter.x, y: arcCenter.y)
        let dashes: [CGFloat] = [16.0, 32.0].map {$0/4}
        for lineAngle in ([45, 135].map {($0 - 180).degreesToRadians}) {
            guard radAngleRange.contains(lineAngle) else {
                continue
            }
            let line = UIBezierPath()
            line.setLineDash(dashes, count: dashes.count, phase: 0)
            line.lineWidth = 1
            line.move(to: CGPoint.zero)
            let endPoint = CGPoint(
                x: radius * cos(lineAngle),
                y: radius * sin(lineAngle))
            line.addLine(to: endPoint)
            line.stroke()
        }
        ctx.restoreGState()
    }

    fileprivate func drawAnglesText() {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        ctx.translateBy(x: arcCenter.x, y: arcCenter.y)

        for angle in stride(from: radAngleRange.lowerBound, through: radAngleRange.upperBound, by: linesStep) {
            let degAngle = 180 + Int(round(angle.radiansToDegrees))
            let text = "\(degAngle)°"
            let fontSize: CGFloat = 13
            let attrText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.font : font.withSize(fontSize)])

            let width = NSAttributedString(string: "\(degAngle)", attributes: [NSAttributedStringKey.font : font.withSize(fontSize)]).size().width
            ctx.saveGState()
            ctx.translateBy(x: radius * 1.1 * cos(angle), y: radius * 1.1 * sin(angle))
            ctx.rotate(by: angle + CGFloat.pi/2)
            attrText.draw(at: CGPoint(x: -width/2, y: 0))
            ctx.restoreGState()
        }

        ctx.restoreGState()
    }

    fileprivate func drawNeedle() {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        ctx.translateBy(x: arcCenter.x, y: arcCenter.y)
        ctx.rotate(by: needleAngle)

        let needle = UIBezierPath()
        needle.move(to: CGPoint.zero)
        needle.addLine(to: CGPoint(x: radius, y: 0))
        needle.lineWidth = 2
        needle.lineCapStyle = .round
        needle.stroke()

        UIBezierPath(arcCenter: CGPoint(x: radius, y: 0),
                     radius: isTouching ? 8 : 5,
                     startAngle: 0,
                     endAngle: CGFloat.pi * 2,
                     clockwise: true).fill()


        ctx.restoreGState()
    }

    fileprivate func drawSeparatorLine() {
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: bounds.width, height: 2)).fill()
    }

    fileprivate func drawValueLabel() {
        let textRectSize = CGSize(width: 60, height: 20)
        let textRect = CGRect(
            x: arcCenter.x - textRectSize.width/2,
            y: arcCenter.y - textRectSize.height/2,
            width: textRectSize.width,
            height: textRectSize.height)
        let rect = UIBezierPath(rect: textRect)
        rect.fill()
        rect.stroke()

        let text = "\(value)°"
        let p = NSMutableParagraphStyle()
        p.alignment = .center
        let attrText = NSAttributedString(string: text,
                                          attributes: [.font: font.withSize(17),
                                                       .paragraphStyle: p
            ])
        attrText.draw(in: textRect)
    }

    public override func draw(_ rect: CGRect) {
        UIColor(red: 169/255, green: 177/255, blue: 186/255, alpha: 1.0).setStroke()

        drawArc()
        drawLines()
        drawQuarterAngles()
        drawAnglesText()
        
        tintColor.set()
        drawNeedle()

        if shouldDrawSeparatorLine {
            UIColor(red: 180/255, green: 188/255, blue: 199/255, alpha: 1).set()
            drawSeparatorLine()
        }

        if shouldDrawValueLabel {
            backgroundColor?.setFill()
            UIColor(red: 169/255, green: 177/255, blue: 186/255, alpha: 1.0).setStroke()
            drawValueLabel()
        }
    }

    // MARK: - User Interaction

    @objc func buttonLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .changed {
            if valueTimer == nil {
                valueTimer = Timer.scheduledTimer(timeInterval: 0.25/2, target: self, selector: #selector(Protractor.valueTimerFired(_:)), userInfo: sender.view?.tag, repeats: true)
                sendActions(for: .editingDidBegin)
                valueTimer!.fire()
            }
        } else if valueTimer != nil {
            valueTimer!.invalidate()
            valueTimer = nil
            sendActions(for: .editingDidEnd)
        }
    }

    @objc func valueTimerFired(_ timer: Timer) {
        guard let mult = timer.userInfo as? Double else {
            return
        }
        DispatchQueue.main.async {
            let oldValue = self.value
            self.value += mult * self.stepValue
            if oldValue != self.value {
                self.sendActions(for: .valueChanged)
            }
        }
    }

    @objc func buttonTapped(_ sender: UITapGestureRecognizer) {
        buttonTouched(sender.view as! UIButton)
    }

    @objc func buttonTouched(_ sender: UIButton) {
        let mult = Double(sender.tag)

        let oldValue = self.value
        self.value += mult * stepValue
        if oldValue != value {
            sendActions(for: .editingDidBegin)
            sendActions(for: .valueChanged)
            sendActions(for: .editingDidEnd)
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        let touchableRadius = CGFloat(radius * 0.8)...CGFloat(radius * 1.15)
        guard let touch = touches.first, touchableRadius.contains(dist(touch.location(in: self), arcCenter)) else {
            return
        }

        isTouching = true

        updateTouchLocation(touch: touch)
    }

    private func dist(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let distance = CGFloat(hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y)))

        return distance
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard isTouching, let touch = touches.first else {
            return
        }

        updateTouchLocation(touch: touch)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        isTouching = false
    }

    func updateTouchLocation(touch: UITouch) {
        var touchLocation = touch.location(in: self)
        touchLocation.y = min(arcCenter.y, touchLocation.y)
        var angle = atan2(touchLocation.y - arcCenter.y,
                          touchLocation.x - arcCenter.x)
        if (angle > 0) {
            angle -= CGFloat.pi * 2
        }
        angle = max(radAngleRange.lowerBound, min(radAngleRange.upperBound, angle))
        let oldValue = value
        needleAngle = angle

        if oldValue != value {
            sendActions(for: .valueChanged)
        }
    }
}
