import UIKit

class ProgressView: UIView {
    private var progress = 0.0

    private let progressLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false

        backgroundColor = UIColor.clear

        progressLayer.position = CGPoint.zero
        progressLayer.strokeEnd = 0.0
        progressLayer.strokeColor = UIColor.lightGray.cgColor

        layer.addSublayer(progressLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProgress(_ progress: Double, animated: Bool = true) {
        let oldValue = self.progress

        if oldValue == progress {
            return
        }

        // Reset alpha to 1 (could have been fading/faded)
        alpha = 1

        if animated {
           if progress < oldValue {
                animate(from: 0.0, to: progress)
            } else if progress != 1 {
                animate(from: oldValue, to: progress)
            } else {
                animate(from: oldValue, to: progress) {
                    self.fadeAndReset()
                }
            }
        } else {
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = CGFloat(progress)
            CATransaction.setDisableActions(false)
        }

        self.progress = progress
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.setDisableActions(true)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.midY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
        progressLayer.path = path.cgPath
        progressLayer.lineWidth = bounds.height
        CATransaction.setDisableActions(false)
    }

    private func animate(from oldValue: Double, to progress: Double, completion: (() -> Void)? = nil) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = oldValue
        animation.toValue = progress
        animation.duration = 0.3

        CATransaction.setCompletionBlock(completion)
        CATransaction.begin()
        progressLayer.add(animation, forKey: nil)
        CATransaction.commit()

        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = CGFloat(progress)
        CATransaction.setDisableActions(false)
    }

    private func fadeAndReset() {
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0
        }, completion: { completed in
            if completed && self.progress == 1.0 {
                self.setProgress(0, animated: false)
            }
        })
    }
}
