//
//  ProgressView.swift
//  Tabless
//
//  Created by Eric Bomgardner on 3/24/16.
//  Copyright © 2016 Eric Bomgardner. All rights reserved.
//

import UIKit

class ProgressView: UIView {
    var progress = 0.0 {
        didSet {
            if progress == oldValue {
                return
            }
            update(from: oldValue, to: progress)
        }
    }

    private let progressLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
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

    private func update(from oldValue: Double, to progress: Double) {
        if progress == 0 || progress < oldValue {
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = CGFloat(progress)
            CATransaction.setDisableActions(false)
        }

        // Reset alpha to 1 (could have been fading/faded)
        alpha = 1

        if progress == 0 {
            // No animation
        } else if progress < oldValue {
            animate(from: 0.0, to: progress)
        } else if progress != 1 {
            animate(from: oldValue, to: progress)
        } else {
            animate(from: oldValue, to: progress) {
                self.fadeAndReset()
            }
        }
    }

    private func animate(from oldValue: Double, to progress: Double, completion: (()->())? = nil) {
        // todo: don't have these called every time
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.midY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
        progressLayer.path = path.cgPath
        progressLayer.lineWidth = bounds.height

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
                self.progress = 0.0
            }
        })
    }
}
