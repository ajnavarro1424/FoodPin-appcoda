//
//  UINavigationController+Ext.swift
//  FoodPin
//
//  Created by Alex Navarro on 1/20/20.
//  Copyright © 2020 Alex Navarro. All rights reserved.
//

import UIKit
import Foundation

extension UINavigationController {
    
    open override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
}
