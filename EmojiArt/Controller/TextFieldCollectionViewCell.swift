//
//  TextViewCollectionViewCell.swift
//  EmojiArt
//
//  Created by Stanislav on 20.03.2019.
//  Copyright © 2019 Stanislav Kozlov. All rights reserved.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    
    
    @IBOutlet weak var textField: UITextField!{
        didSet{
            textField.delegate = self
        }
    }
    
    var resignationHandler: (() -> Void)?
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        resignationHandler?()
    }
    
    
    //to stop using the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
