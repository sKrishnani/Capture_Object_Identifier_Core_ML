//
//  RoundedShadowImageView.swift
//  CaptureObjectIdentifier
//
//  Created by Shuchita Krishnani on 04/11/17.
//  Copyright © 2017 Shuchita Krishnani. All rights reserved.
//

import UIKit

class RoundedShadowImageView: UIImageView {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 0.75
        self.layer.shadowRadius = 15
        self.layer.cornerRadius = 15
        
    }

}
