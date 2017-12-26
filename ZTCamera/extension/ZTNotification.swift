//
//  ZTNotification.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/26.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import Foundation

enum ZTNotification:String {
    case startRecording
    case stopRecording
    
    var stringValue: String {
        return "ZT" + rawValue
    }
    
    var notificationName: NSNotification.Name {
        return NSNotification.Name(stringValue)
    }
    
}

extension NotificationCenter {
    
    static func post(customNotification name: ZTNotification, object: Any? = nil){
        NotificationCenter.default.post(name: name.notificationName, object: object)
    }
    
    static func addObserver(_ observer: Any, selector aSelector: Selector, name aName: ZTNotification, object anObject: Any?) {
        NotificationCenter.default.addObserver(observer, selector: aSelector, name: aName.notificationName, object: anObject)
    }
}
