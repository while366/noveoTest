//
//  FrontViewController.swift
//  SoftomateTestTask
//
//  Created by Mikhail Zhadko on 5/24/16.
//  Copyright © 2016 Mikhail Zhadko. All rights reserved.
//

import UIKit
import CoreData

class FrontViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    let searchController = UISearchController(searchResultsController: nil)
    var people = [NSManagedObject]()
    var filteredPeople = [NSManagedObject]()
    var choosenCategory: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        choosenCategory = "All"
        tableView.tableFooterView = UIView()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FrontViewController.chooseCategory(_:)), name: "chooseCategory", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FrontViewController.modalDismissed), name: "modalDismissed", object: nil)
//        self.tableView.rowHeight = 60
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        self.revealViewController().rearViewRevealOverdraw = 0
        
        setUpSearchBar()

    }
    func chooseCategory(notification: NSNotification) {
        if let tmp = notification.userInfo!["categoryKey"] {
            self.choosenCategory = tmp as! String
            viewWillAppear(false)
        }
    }
    func modalDismissed() {
        viewWillAppear(false)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Person")
        if !(choosenCategory == "All") {
            let predicate = NSPredicate(format: "ANY categories.category == %@", choosenCategory)
            fetchRequest.predicate = predicate
        }
        do {
            let results =
                try managedContext.executeFetchRequest(fetchRequest)
            people = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        tableView.reloadData()
    }
    //MARK: - SEARCH CONTROLLER
    
    func setUpSearchBar() {
//        self.searchController = UISearchController(searchResultsController:  nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = false
        self.navigationItem.titleView = searchController.searchBar
        self.definesPresentationContext = true
        searchController.searchBar.barTintColor = UIColor(colorLiteralRed: (247.0/255.0), green: (247.0/255.0), blue: (247.0/255.0), alpha: 1)

    }
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        for item in people {
            if item.valueForKey("firstName") != nil {
                if item.valueForKey("firstName")!.lowercaseString.containsString(searchText.lowercaseString) {
                    filteredPeople.append(item)
                    tableView.reloadData()
                    continue
                }
            }
            if item.valueForKey("lastName") != nil {
                if item.valueForKey("lastName")!.lowercaseString.containsString(searchText.lowercaseString) {
                    filteredPeople.append(item)
                    tableView.reloadData()
                    
                }
            }
        }
        tableView.reloadData()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredPeople = []
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    //MARK: - TableViewDelegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && ( searchController.searchBar.text != nil ) {
            return filteredPeople.count
        }
        return people.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FrontViewCell") as! TableViewCell
        var tempStr = ""
        let person : NSManagedObject
        if searchController.active && searchController.searchBar.text != "" {
            person = filteredPeople[indexPath.row]
        } else {
            person = people[indexPath.row]
        }
        cell.icon.layer.cornerRadius = cell.icon.frame.width / 2
        if person.valueForKey("firstName") != nil {
            tempStr = "\(person.valueForKey("firstName")!) "
        }
        if person.valueForKey("lastName") != nil {
            tempStr.appendContentsOf(person.valueForKey("lastName")! as! String)
        }
        cell.name.text = tempStr
        guard let data = person.valueForKey("photo") as? NSData else {
            cell.icon.image = UIImage(named: "noPhoto")
            return cell
        }
        cell.icon.image = UIImage(data: data)
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete  {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            managedContext.deleteObject(people[indexPath.row])
            people.removeAtIndex(indexPath.row)
            appDelegate.saveContext()
            tableView.reloadData()
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("details", sender: self)
    }

    
    @IBAction func addNewPerson(sender: AnyObject) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("add")
        vc?.modalPresentationStyle = .OverFullScreen
        vc?.modalTransitionStyle = .CoverVertical
        self.presentViewController(vc!, animated: true, completion:  nil)
        
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "details" {
            let detailsVC = segue.destinationViewController as! DetailsViewController
            let indexPath = tableView.indexPathForSelectedRow!
            detailsVC.person = people[indexPath.row]
            
        }
    }

}

