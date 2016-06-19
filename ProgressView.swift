//
//  ProgressView.swift
//  Tabless
//
//  Created by Eric Bomgardner on 3/24/16.
//  Copyright © 2016 Eric Bomgardner. All rights reserved.
//

import UIKit

class ProgressView: UIView {
    var progress = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.whiteColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        let loadedArea = CGRect(x: 0, y: 0, width: CGFloat(progress) * frame.size.width, height: frame.size.height)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1, 0.05)
        CGContextFillRect(context, loadedArea)
    }
}
