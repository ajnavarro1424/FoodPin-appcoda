//
//  DiscoverTableViewController.swift
//  FoodPin
//
//  Created by Alex Navarro on 2/10/20.
//  Copyright © 2020 Alex Navarro. All rights reserved.
//

import UIKit
import CloudKit


@available(iOS 13.0, *)
class DiscoverTableViewController: UITableViewController {
    
    @IBOutlet 
    
    var restaurants: [CKRecord] = []
    var spinner = UIActivityIndicatorView()
    private var imageCache = NSCache<CKRecord.ID, NSURL>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //Configure the navigation bar appearance
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        if let customFont = UIFont(name: "Rubik-Medium", size: 40.0) {
            navigationController?.navigationBar.largeTitleTextAttributes = [ NSAttributedString.Key.foregroundColor: UIColor(red: 231, green: 76, blue: 60), NSAttributedString.Key.font: customFont ]
        }
        
        //Configure the spinning indicator
        spinner.style = .large
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        
        //Define layout constraints for spinner
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([ spinner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150.0),
                                      spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor) ])
        
        //Activate the spinner
        spinner.startAnimating()
        
        //Pull to Refresh Control
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor.white
        refreshControl?.tintColor = UIColor.red
        refreshControl?.addTarget(self, action: #selector(fetchRecordsFromCloud), for: UIControl.Event.valueChanged)
        
        fetchRecordsFromCloud()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return restaurants.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverCell", for: indexPath) as! DiscoverTableViewCell
        
        //Configure the cell
        let restaurant = restaurants[indexPath.row]
        
        cell.nameLabel?.text = restaurant.object(forKey: "name") as? String
        cell.typeLabel?.text = restaurant.object(forKey: "type") as? String
        cell.locationLabel?.text = restaurant.object(forKey: "location") as? String
        cell.phoneLabel?.text = restaurant.object(forKey: "phone") as? String
        cell.descriptionLabel?.text = restaurant.object(forKey: "description") as? String
        
        // Set the default image in the cell to setup lazy loading
        cell.photoImageView?.image = UIImage(systemName: "photo")?.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
        
        //Check if the image is stored in the cache before getting from Cloud
        if let imageFileURL = imageCache.object(forKey: restaurant.recordID) {
            //Fetch the image from cache
            print("Get image from cache: \(restaurant.recordID)")
            if let imageData = try? Data.init(contentsOf: imageFileURL as URL) {
                cell.photoImageView?.image = UIImage(data: imageData)
            }
        } else {
            //Fetch image from Cloud in the background
            let publicDatabase = CKContainer.default().publicCloudDatabase
            let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [restaurant.recordID])
            fetchRecordsImageOperation.desiredKeys = ["image"]
            fetchRecordsImageOperation.queuePriority = .veryHigh
            
            fetchRecordsImageOperation.perRecordCompletionBlock = { (record, recordID, error) -> Void in
                if let error = error {
                    print("Failed to get restaurant image: \(error.localizedDescription)")
                    
                    return
                }
                
                if let restaurantRecord = record, let image = restaurantRecord.object(forKey: "image"), let imageAsset = image as? CKAsset {
                    if let imageData = try? Data.init(contentsOf: imageAsset.fileURL!) {
                        //Replace the placeholder image with the restaurant image
                        DispatchQueue.main.async {
                            cell.photoImageView?.image = UIImage(data: imageData)
                            
                            //Set new photoImageView constraights to replace 
                            cell.setNeedsLayout()
                        }
                        //Add the image URL to the cache
                        self.imageCache.setObject(imageAsset.fileURL! as NSURL, forKey: restaurant.recordID)
                        
                    }
                }
            }
            
            publicDatabase.add(fetchRecordsImageOperation)
            
        }
        
        
        return cell
    }
    
    @objc func fetchRecordsFromCloud() {
        //Remove existing records from the table before refreshing
        restaurants.removeAll()
        tableView.reloadData()
        
        //Fetch data using Convenience API
        
        //Get the default CloudKit container
        let cloudContainer = CKContainer.default()
        //Get the default public database
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(value: true)
        
        //Construct the query to get the Restaurant record types
        let query = CKQuery(recordType: "Restaurant", predicate: predicate)
        
        //Sort the query by reverse chronological order
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        //Create the query operations with the query
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["name", "type", "location", "phone", "description"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        
        //Executed for every record returned. Append each restaurant to the array
        queryOperation.recordFetchedBlock = { (record) -> Void in
            self.restaurants.append(record)
        }
        //Executed after all the records are fetched.
        queryOperation.queryCompletionBlock = { [unowned self] (cursor, error) -> Void in
            if let error = error {
                print("Failed to get data from iCloud public DB - \(error.localizedDescription)")
                return
            }
            
            print("Successfully retrieve the data from iCloud public DB")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.tableView.reloadData()
                
                //Hide the pull to refresh indicator after data is loaded
                if let refreshControl = self.refreshControl {
                    if refreshControl.isRefreshing {
                        refreshControl.endRefreshing()
                    }
                }
            }
            
        }
        
        //Execute the query
        publicDatabase.add(queryOperation)
        
        
        //Perform the query
//        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {
//            (results, error) -> Void in
//
//            if let error = error {
//                print(error)
//                return
//            }
//
//            if let results  = results {
//                self.restaurants = results
//
//                //Update UI on the main thread
//                DispatchQueue.main.sync {
//                    self.tableView.reloadData()
//                }
//
//                print("Completed the download of the Restaurant data from CloudKit database.")
//            }
//        })
        
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
