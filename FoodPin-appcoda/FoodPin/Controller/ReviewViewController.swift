//
//  ReviewViewController.swift
//  FoodPin
//
//  Created by Alex Navarro on 1/21/20.
//  Copyright © 2020 Alex Navarro. All rights reserved.
//

import UIKit

class ReviewViewController: UIViewController {
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var rateButtons: [UIButton]!
    @IBOutlet var exitButton: UIButton!
    
    var restaurant: RestaurantMO!
    
    // MARK - View Controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let restaurantImage = restaurant.image {
            backgroundImageView.image = UIImage(data: restaurantImage as Data)
        }
        
        
        //Applying a blur effect to the background image view
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        backgroundImageView.addSubview(blurEffectView)
        
        //Animation setup for exit button(start state)
        let moveUpTransform = CGAffineTransform(translationX: 0, y: -200)
        exitButton.transform = moveUpTransform
        exitButton.alpha = 0
        
        //Animation setup for review buttons(start state)
        let moveRightTransform = CGAffineTransform(translationX: 600, y: 0)
        let scaleUpTransform = CGAffineTransform.init(scaleX: 5.0, y: 5.0)
        let moveScaleTransform = scaleUpTransform.concatenating(moveRightTransform)
        
        for rateButton in rateButtons {
            rateButton.transform = moveScaleTransform
            rateButton.alpha = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Animation end state for review buttons
        UIView.animate(withDuration: 1.0) {
            for rateButton in self.rateButtons {
                rateButton.transform = .identity
                rateButton.alpha = 1
            }
        }
        //Animation end state for exit button
        UIView.animate(withDuration: 1.0) {
            self.exitButton.transform = .identity
            self.exitButton.alpha = 1
            
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
