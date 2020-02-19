//
//  WalkthroughViewController.swift
//  FoodPin
//
//  Created by Alex Navarro on 2/3/20.
//  Copyright © 2020 Alex Navarro. All rights reserved.
//

import UIKit

class WalkthroughViewController: UIViewController, WalkthroughPageViewControllerDelegate {

    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var nextButton: UIButton! {
        didSet {
            nextButton.layer.cornerRadius = 25.0
            nextButton.layer.masksToBounds = true
        }
    }
    @IBOutlet var skipButton: UIButton!
    
    var walkthroughPageViewController: WalkthroughPageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func updateUI() {
        if let index = walkthroughPageViewController?.currentIndex {
            switch index {
            case 0...1:
                nextButton.setTitle("NEXT", for: .normal)
                skipButton.isHidden = false
                
            case 2:
                nextButton.setTitle("GET STARTED", for: .normal)
                skipButton.isHidden = true
                
            default: break
            }
            
            pageControl.currentPage = index
        }
    }
    
    func didUpdatePageIndex(currentIndex: Int) {
        updateUI()
    }
    
    func createQuickActions() {
        //Add Quick Actions
        if traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                //Show Favorites
                let shortcutItem1 = UIApplicationShortcutItem(type: "\(bundleIdentifier).OpenFavorites", localizedTitle: "Show Favorites", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "favorite"), userInfo: nil)
                //Discover Restaurants
                let shortcutItem2 = UIApplicationShortcutItem(type: "\(bundleIdentifier).OpenDiscover", localizedTitle: "Discover Restaurants", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "discover"), userInfo: nil)
                //New Restaurant
                let shortcutItem3 = UIApplicationShortcutItem(type: "\(bundleIdentifier).NewRestaurant", localizedTitle: "New Restaurant", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(type: .add), userInfo: nil)
                
                UIApplication.shared.shortcutItems = [shortcutItem1, shortcutItem2, shortcutItem3]
                
            }
            
        }
    }
    

    // MARK: - Navigation
    
    //Skip button dismisses the walkthrough
    @IBAction func skipButtonTapped(sender: UIButton) {
        //Save that the user has seen the walkthrough
        UserDefaults.standard.set(true, forKey: "hasViewedWalkthrough")
        
        //Allow the use of shortcuts
        createQuickActions()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButtonTapped(sender: UIButton) {
        if let index = walkthroughPageViewController?.currentIndex {
            
            switch index {
            case 0...1:
                walkthroughPageViewController?.forwardPage()
            
            case 2:
                //Save that the user has seen the walkthrough
                UserDefaults.standard.set(true, forKey: "hasViewedWalkthrough")
                
                //Allow the user of shortcuts
                createQuickActions()
                
                dismiss(animated: true, completion: nil)
                
            default:
                break
            }
        }
        
        updateUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        if let pageViewController = destination as? WalkthroughPageViewController {
            walkthroughPageViewController = pageViewController
            walkthroughPageViewController?.walkthroughDelegate = self
        }
    }

}
