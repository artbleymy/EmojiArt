//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Stanislav on 13.03.2019.
//  Copyright © 2019 Stanislav Kozlov. All rights reserved.
//

import UIKit

class EmojiArtView: UIView {

    
    var backgoundImage: UIImage? {didSet {setNeedsDisplay()}}
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        backgoundImage?.draw(in: bounds)
    }

}
