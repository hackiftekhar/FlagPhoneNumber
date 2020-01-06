//
//  FlagPhoneNumberTextField.swift
//  FlagPhoneNumber
//
//  Created by Iftekhar on 06/01/20.
//  Copyright (c) 2017 Aurélien Grifasi. All rights reserved.
//

import UIKit

open class FPNButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        if let imageView = self.imageView {
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = 10
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if let imageView = self.imageView {
            imageView.frame = CGRect(origin: .zero, size: CGSize(width: 20, height: 20))
            imageView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        }
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
