//
//  TimelineFlowLayout.swift
//  NaimDemo
//
//  Created by Antonio Strijdom on 21/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import UIKit

/// Flow layout for diplaying album timeline
class TimelineFlowLayout: UICollectionViewFlowLayout {
    
    // MARK: - Private
    
    fileprivate let decorationHeight: CGFloat = 100.0
    fileprivate let lineDecorationKind = "Line"
    
    // MARK: - Properties
    public let cellHeight: CGFloat = 122.0
    
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollDirection = .horizontal
        self.estimatedItemSize = CGSize(width: cellHeight, height: cellHeight)
        self.itemSize = CGSize(width: cellHeight, height: cellHeight)
        self.headerReferenceSize = CGSize(width: 80.0, height: collectionView?.frame.size.height ?? 0)
        self.footerReferenceSize = CGSize(width: 100.0, height: collectionView?.frame.size.height ?? 0)
        
        self.register(TimelineDecorationView.self, forDecorationViewOfKind: lineDecorationKind)
    }
    
    // MARK: - UICollectionViewFlowLayout
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // only generate layout attributes for the custom decoration
        if "Line" == elementKind {
            if let collectionView = self.collectionView {
                // create layout attributes for the direction view
                let layoutAttributes = TimelineDecorationViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                var cellWidth: CGFloat = 0.0
                var headerWidth: CGFloat = 0.0
                var x: CGFloat = 0.0
                if collectionView.traitCollection.verticalSizeClass == .regular {
                    if let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
                        // calculate the x position of the decoration
                        // unfortunately, headers are optional so we have to do this the hard way
                        // TODO: cache this as it is an expensive operation
                        x = (0..<indexPath.section).reduce(0.0, { (result: CGFloat, section: Int) -> CGFloat in
                            return result + delegate.collectionView!(collectionView, layout: self, referenceSizeForHeaderInSection: section).width + cellHeight + footerReferenceSize.width
                        })
                        // calculate the width of this decoration
                        // header (optional) plus the cell width (same as height) and footer
                        headerWidth = delegate.collectionView!(collectionView, layout: self, referenceSizeForHeaderInSection: indexPath.section).width
                        cellWidth = headerWidth + cellHeight + footerReferenceSize.width
                    }
                }
                // y is comparitively simple
                let y = (collectionView.frame.size.height / 2.0) - (decorationHeight / 2.0)
                // set frame
                layoutAttributes.frame = CGRect(x: x,
                                                y: y,
                                                width: cellWidth,
                                                height: decorationHeight)
                // if this is the first album (draws a start line)
                layoutAttributes.start = indexPath.section == 0
                // alternate the arrows
                if indexPath.section % 2 == 0 {
                    // even points down
                    layoutAttributes.direction = .down
                } else {
                    // odd points up
                    layoutAttributes.direction = .up
                }
                // offset to make sure arrow is centered
                layoutAttributes.offset = (headerWidth / 2.0) - (footerReferenceSize.width / 2.0)
                return layoutAttributes
            }
        }
        // otherwise use the super class' layout attributes
        return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // add our custom decoration view attributes to the standard list
        let attributes = super.layoutAttributesForElements(in: rect)
        if let collectionView = self.collectionView, var attributes = attributes {
            for section in 0..<collectionView.numberOfSections {
                let indexPath = IndexPath(item: 0, section: section)
                if let decorationAttributes = self.layoutAttributesForDecorationView(ofKind: lineDecorationKind, at: indexPath) {
                    if rect.contains(decorationAttributes.frame) {
                        attributes.append(decorationAttributes)
                    }
                }
            }
            return attributes
        }
        return attributes
    }
}
