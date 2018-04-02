//
//  TimelineHeaderReusableView.swift
//  Discography
//
//  Created by Antonio Strijdom on 21/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import UIKit

/// Header view for discography timeline
class TimelineHeaderReusableView: UICollectionReusableView {
    public var headerLabel: UILabel! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)
        headerLabel.leftAnchor.constraintEqualToSystemSpacingAfter(leftAnchor, multiplier: 1.0)
        headerLabel.topAnchor.constraintEqualToSystemSpacingBelow(topAnchor, multiplier: 1.0)
        rightAnchor.constraintEqualToSystemSpacingAfter(headerLabel.rightAnchor, multiplier: 1.0)
        bottomAnchor.constraintEqualToSystemSpacingBelow(headerLabel.bottomAnchor, multiplier: 1.0)
        headerLabel.adjustsFontSizeToFitWidth = true
        headerLabel.textColor = .black
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
