//
//  RestaurantTableViewController.swift
//  FoodPin
//
//  Created by Alex Navarro on 1/7/20.
//  Copyright © 2020 Alex Navarro. All rights reserved.
//

import UIKit
import CoreData

@available(iOS 13.0, *)
class RestaurantTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    
    //Outlet variable for the Restaurant table empty state
    @IBOutlet var emptyRestaurantView: UIView!
    
    var searchController: UISearchController!
    var searchResults: [RestaurantMO] = []
    
    var restaurants: [RestaurantMO] = []
    var fetchResultController: NSFetchedResultsController<RestaurantMO>!
    
    // MARK: - View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Fetch restaurants from data store
        let fetchRequest: NSFetchRequest<RestaurantMO> = RestaurantMO.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController.delegate = self
            
            do {
                try fetchResultController.performFetch()
                if let fetchedObjects = fetchResultController.fetchedObjects {
                    restaurants = fetchedObjects
                }
            } catch {
                print(error)
            }
        }
        
        //Setup the searchbar in the navigation bar
        searchController = UISearchController(searchResultsController: nil)
        self.navigationItem.searchController = searchController
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        
        //Enable large navigation bar title
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //Set the navigation bar background/shadow image to be blank
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        //Customize the navigation bar title
        if let customFont = UIFont(name: "Rubik-Medium", size: 40.0) {
            navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0), NSAttributedString.Key.font: customFont ]
        }
        
        //Hide the navigation bar on swipe up of the list
        navigationController?.hidesBarsOnSwipe = true
        
        //Prepare the empty state view
        tableView.backgroundView = emptyRestaurantView
        tableView.backgroundView?.isHidden = true
        
        //Search Controller config and customization
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.placeholder = "Search restaurants..."
        searchController.searchBar.barTintColor = .white
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.tintColor = UIColor(red: 231, green: 76, blue: 60)
        
        //Removes extra separators on empty cells of the table view
        tableView.tableFooterView = UIView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Hide the navigation bar on swipe up
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //If user has seen walkthrough return to Restaurant table view
        if UserDefaults.standard.bool(forKey: "hasViewedWalkthrough") {
            return
        }
        //Otherwise, display the walkthrough
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        
        if let walkthroughViewController = storyboard.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController {
            present(walkthroughViewController, animated: true, completion: nil)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if restaurants.count > 0 {
            tableView.backgroundView?.isHidden = true
            tableView.separatorStyle = .singleLine
        } else {
            tableView.backgroundView?.isHidden = false
            tableView.separatorStyle = .none
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Display search results if search bar is active
        if searchController.isActive {
            return searchResults.count
        //Otherwise return the restaurant list
        } else {
            return restaurants.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "datacell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! RestaurantTableViewCell
        
    
        //Determine if we get the restaurant from the search result or the original array
        let restaurant = (searchController.isActive) ? searchResults[indexPath.row] : restaurants[indexPath.row]
        
        // Configure the cell...
        cell.nameLabel?.text = restaurant.name
        
        if let restaurantImage = restaurant.image {
            cell.thumbnailImageView?.image = UIImage(data: restaurantImage as Data)
            
        }
        cell.locationLabel?.text = restaurant.location
        cell.typeLabel?.text = restaurant.type
        
        //Set the accessory portion of the cell
        //cell.accessoryType = restaurantVisited[indexPath.row] ? .checkmark : .none
        
        //Set the accessory portion of the cell to an image
        cell.accessoryImageView?.image = restaurant.isVisited ? UIImage(named: "heart-tick") : nil
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completetionHandler) in
            //Delete the row from the data store
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                let restaurantToDelete = self.fetchResultController.object(at: indexPath)
                
                context.delete(restaurantToDelete)
                
                appDelegate.saveContext()
            }

            //Call the completion handler to dismiss the action button
            completetionHandler(true)
            }
        
        let shareAction = UIContextualAction(style: .normal, title: "Share") { (action, sourceView, completionHandler) in
            
            //Text to be shared
            let defaultText = "Just checking in at " + self.restaurants[indexPath.row].name!
            
            
            let activityController: UIActivityViewController
            
            //If one exists, share an image along with the default text
            if let restaurantImage = self.restaurants[indexPath.row].image,
                 let imageToShare = UIImage(data: restaurantImage as Data) {
                    activityController = UIActivityViewController(activityItems: [defaultText, imageToShare], applicationActivities: nil)
                } else {
                    activityController = UIActivityViewController(activityItems: [defaultText], applicationActivities: nil)
                }
            
            //Configure popoverController for ipads
            if let popoverController = activityController.popoverPresentationController {
                if let cell = tableView.cellForRow(at: indexPath) {
                    popoverController.sourceView = cell
                    popoverController.sourceRect = cell.bounds
                }
            }
            self.present(activityController, animated: true, completion: nil)
            
            completionHandler(true)
        }
        
        //Customizing Contextual Action
        deleteAction.backgroundColor = UIColor(red: 231, green: 76, blue: 60)
        deleteAction.image = UIImage(systemName: "trash")
        
        shareAction.backgroundColor = UIColor(red: 254, green: 149, blue: 38)
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        
        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
        
        return swipeConfiguration
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //
        let cell = tableView.cellForRow(at: indexPath) as! RestaurantTableViewCell
        
        if restaurants[indexPath.row].isVisited {
            //Undo Check-In Action
            let undoCheckInAction = UIContextualAction(style: .normal, title: "Undo Check In") { (action, sourceView, completionHandler) in
            
                //Clear the accessoryImage
                cell.accessoryImageView?.image = nil
                
                //Set the restaurant to not visited
                self.restaurants[indexPath.row].isVisited = false
                
                completionHandler(true)
            }
            
            //Customizing the Check In/Out Action
            undoCheckInAction.backgroundColor = UIColor.orange
            undoCheckInAction.image = UIImage(systemName: "arrow.uturn.left")
            
            //Set the swipeConfiguration
            let swipeConfiguration = UISwipeActionsConfiguration(actions:[undoCheckInAction])
            return swipeConfiguration
        } else {
               //Check In Action
               let checkInAction = UIContextualAction(style: .normal, title: "Check In") { (action, sourceView, completionHandler) in
                    //Add the heart-tick image to the accessory image area
                    cell.accessoryImageView?.image = UIImage(named: "heart-tick")
                    
                    //Set the restaurant to visited
                    self.restaurants[indexPath.row].isVisited = true
                
                    completionHandler(true)
               }
               
               //Customizing the Check In/Out Action
               checkInAction.backgroundColor = UIColor.green
               checkInAction.image = UIImage(systemName: "checkmark")
            
               //Set the swipeConfiguration
               let swipeConfiguration = UISwipeActionsConfiguration(actions:[checkInAction])
               return swipeConfiguration
        }
        
        
                       
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        default:
            tableView.reloadData()
        }
        
        if let fetchedObjects = controller.fetchedObjects {
            restaurants = fetchedObjects as! [RestaurantMO]
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func filterContent(for searchText: String) {
        
        searchResults = restaurants.filter({ (restaurant) -> Bool in
            //Restaurant name and location search
            if let name = restaurant.name, let location = restaurant.location {
                let isMatch = name.localizedCaseInsensitiveContains(searchText) || location.localizedCaseInsensitiveContains(searchText)
                
                return isMatch
            }
            
            return false
            
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContent(for: searchText)
            tableView.reloadData()
            
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showRestaurantDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                //Sets the destination controller
                let destinationController = segue.destination as! RestaurantDetailViewController
                //Handoff restaurant object
                destinationController.restaurant = (searchController.isActive) ? searchResults[indexPath.row] : restaurants[indexPath.row]
                
            }
        }
    }
    
    @IBAction func unindToHome(segue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
    

}
