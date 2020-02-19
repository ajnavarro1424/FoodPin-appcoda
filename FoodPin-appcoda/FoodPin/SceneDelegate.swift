//
//  SceneDelegate.swift
//  FoodPin
//
//  Created by Alex Navarro on 2/18/20.
//  Copyright © 2020 Alex Navarro. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    enum QuickAction: String {
        case OpenFavorites = "OpenFavorites"
        case OpenDiscover = "OpenDiscover"
        case NewRestaurant = "NewRestaurant"
        
        init?(fullIdentifier: String) {
            guard let shortcutIdentifier = fullIdentifier.components(separatedBy: ".").last else {
                return nil
            }
            
            self.init(rawValue: shortcutIdentifier)
        }
        
    }
    
    
}
