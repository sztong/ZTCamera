//
//  UIViewAdditions.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/23.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import UIKit

extension UIView {
    
    var frameX:CGFloat{
        set(newValue){
            self.frame = CGRect(x: newValue, y: self.frame.origin.y, width: self.frame.width, height: self.frame.height)
        }
        get {
            return self.frame.origin.x
        }
    }
    var frameY:CGFloat{
        set(newValue){
            self.frame = CGRect(x: self.frame.origin.x, y: newValue, width: self.frame.width, height: self.frame.height)
        }
        get {
            return self.frame.origin.y
        }
    }
    var frameWidth:CGFloat{
        set(newValue){
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: newValue, height: self.frame.height)
        }
        get {
            return self.frame.width
        }
    }
    var frameHeight:CGFloat{
        set(newValue){
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.width, height: newValue)
        }
        get {
            return self.frame.height
        }
    }
}
