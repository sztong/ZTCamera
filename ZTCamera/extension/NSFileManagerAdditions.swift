//
//  NSFileManagerAdditions.swift
//  ZTKamera
//
//  Created by Tony.su on 2017/12/25.
//  Copyright © 2017年 Tony.su. All rights reserved.
//

import Foundation

extension FileManager {
    
    func temporaryDirectory(withTemplateString templateString:String) -> String? {
        
        let mkdTemplate = NSString(string: NSTemporaryDirectory()).appendingPathComponent(templateString)
        
        do {
            try self.createDirectory(atPath: mkdTemplate, withIntermediateDirectories: true, attributes: nil)
            return mkdTemplate
        }catch {
            return nil
        }
        
    }
    
}
