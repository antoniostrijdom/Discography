//
//  TimelineDecorationView.swift
//  NaimDemo
//
//  Created by Antonio Strijdom on 21/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import UIKit

/// Enumerates timeline arrow directions
///
/// - up: arrow points up
/// - down: arrow points down
enum TimelineDecorationViewLayoutAttributesDirection {
    case up
    case down
}

/// Layout attributes for the timeline decoration view
class TimelineDecorationViewLayoutAttributes: UICollectionViewLayoutAttributes {
    var direction = TimelineDecorationViewLayoutAttributesDirection.up
    var start = false
    var offset: CGFloat = 0
}

/// Timeline decoration view
class TimelineDecorationView: UICollectionReusableView {
    
    // MARK: - Private
    
    fileprivate let color = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
    fileprivate let lineWidth: CGFloat = 10.0
    fileprivate var start = false
    fileprivate var offset: CGFloat = 0
    fileprivate var direction = TimelineDecorationViewLayoutAttributesDirection.up
    
    // MARK: - UICollectionReusableView
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        // apply the layout attributes
        if let attributes = layoutAttributes as? TimelineDecorationViewLayoutAttributes {
            start = attributes.start
            direction = attributes.direction
            offset = attributes.offset
            // redraw
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        // draw a line with a curved arrow pointing in one of two directions 
        
        if let context = UIGraphicsGetCurrentContext() {
            let currentBounds = self.bounds
            let middleLeftPoint = CGPoint(x: currentBounds.minX,
                                          y: currentBounds.midY)
            let middleRightPoint = CGPoint(x: currentBounds.maxX,
                                           y: currentBounds.midY)
            let middleMiddlePoint = CGPoint(x: currentBounds.midX + offset,
                                            y: currentBounds.midY)
            let middleTopPoint = CGPoint(x: currentBounds.midX + offset,
                                         y: currentBounds.minY)
            let middleBottomPoint = CGPoint(x: currentBounds.midX + offset,
                                            y: currentBounds.maxY)
            
            // draw a line through the middle
            context.beginPath()
            context.move(to: middleLeftPoint)
            context.setLineWidth(lineWidth)
            context.setStrokeColor(color.cgColor)
            context.addLine(to: middleRightPoint)
            context.drawPath(using: .fillStroke)
            
            if (start) {
                // draw start line
                context.beginPath()
                context.move(to: CGPoint(x: currentBounds.minX + (lineWidth / 2.0),
                                         y: currentBounds.minY))
                context.setLineWidth(lineWidth)
                context.setStrokeColor(color.cgColor)
                context.addLine(to: CGPoint(x: currentBounds.minX + (lineWidth / 2.0),
                                            y: currentBounds.maxY))
                context.drawPath(using: .fillStroke)
            }
            
            // draw the arrow
            context.beginPath()
            context.setLineWidth(lineWidth)
            context.setStrokeColor(color.cgColor)
            context.setFillColor(color.cgColor)
            context.move(to: CGPoint(x: currentBounds.minX,
                                     y: currentBounds.midY))
            switch direction {
            case TimelineDecorationViewLayoutAttributesDirection.up:
                let topPoint = CGPoint(x: currentBounds.midX + offset,
                                       y: currentBounds.midY - (currentBounds.maxY / 3.0))
                context.addCurve(to: topPoint, control1: middleLeftPoint, control2: middleMiddlePoint)
                context.addCurve(to: middleRightPoint, control1: topPoint, control2: middleMiddlePoint)
            case TimelineDecorationViewLayoutAttributesDirection.down:
                let bottomPoint = CGPoint(x: currentBounds.midX + offset,
                                          y: currentBounds.midY + (currentBounds.maxY / 3.0))
                context.addCurve(to: bottomPoint, control1: middleLeftPoint, control2: middleMiddlePoint)
                context.addCurve(to: middleRightPoint, control1: bottomPoint, control2: middleMiddlePoint)
            }
            context.drawPath(using: .fillStroke)
            
            // draw a centre line
            context.beginPath()
            context.move(to: middleMiddlePoint)
            context.setLineWidth(lineWidth)
            context.setStrokeColor(color.cgColor)
            switch direction {
            case TimelineDecorationViewLayoutAttributesDirection.up:
                context.addLine(to: middleTopPoint)
            case TimelineDecorationViewLayoutAttributesDirection.down:
                context.addLine(to: middleBottomPoint)
            }
            context.drawPath(using: .fillStroke)
        }
    }
}
