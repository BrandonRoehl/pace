//
//  AdBadge.swift
//  Pace
//
//  Created by Brandon Roehl on 3/3/23.
//

import SwiftUI

class AdBadge: UILabel {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.layer.borderColor = self.textColor.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 3.0
    }
}
