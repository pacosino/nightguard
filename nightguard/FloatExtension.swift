//
//  FloatExtension.swift
//  nightguard
//
//  Created by Dirk Hermanns on 18.06.16.
//  Copyright © 2016 private. All rights reserved.
//

import Foundation

extension Float {
    
    // remove the decimal part of the float if it is ".0" and trim whitespaces
    var cleanValue: String {
        return self % 1 == 0
            ? String(format: "%5.0f", self).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            : String(format: "%5.1f", self).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}