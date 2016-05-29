//
//  MenuTableViewController.swift
//  SoftomateTestTask
//
//  Created by Mikhail Zhadko on 5/24/16.
//  Copyright © 2016 Mikhail Zhadko. All rights reserved.
//

import UIKit
import CoreData

class MenuTableViewController: UITableViewController {

    var categories = [NSManagedObject]()
    let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Category")
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            categories = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }

    @IBAction func addCategory(sender: AnyObject) {
        let alert = UIAlertController(title: "New Category",
                                      message: "Add a new category",
                                      preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .Default,
                                       handler: { (action:UIAlertAction) -> Void in
                                        
                                        let textField = alert.textFields!.first
                                        guard let temp = textField?.text! where !temp.stringByTrimmingCharactersInSet(self.whitespaceSet).isEmpty else {
                                            return
                                        }
                                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                                        let managedContext = appDelegate.managedObjectContext
                                        let entity =  NSEntityDescription.entityForName("Category", inManagedObjectContext:managedContext)
                                        let category = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
                                        category.setValue(textField?.text!, forKey: "category")
                                        appDelegate.saveContext()
                                        self.categories.append(category)
                                        self.tableView.reloadData()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField) -> Void in
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert,
                              animated: true,
                              completion: nil)
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return categories.count
        }
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("menuCell", forIndexPath: indexPath)
        if indexPath.section == 0 {
            cell.textLabel?.text = "All"
        } else if indexPath.section == 2 {
            cell.textLabel?.text = "About"
        } else {
            cell.textLabel?.text = categories[indexPath.row].valueForKey("category") as? String
        }
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 2 {
            let aboutVC = storyboard?.instantiateViewControllerWithIdentifier("about")
            aboutVC?.modalTransitionStyle = .CoverVertical
            aboutVC?.modalPresentationStyle = .OverFullScreen
            self.presentViewController(aboutVC!, animated: true, completion: nil)

        } else if indexPath.section == 1 {
            self.revealViewController().revealToggle(self)
            NSNotificationCenter.defaultCenter().postNotificationName("chooseCategory", object: nil, userInfo: ["categoryKey" : categories[indexPath.row].valueForKey("category")!])
        } else if indexPath.section == 0 {
            self.revealViewController().revealToggle(self)
            NSNotificationCenter.defaultCenter().postNotificationName("chooseCategory", object: nil, userInfo: ["categoryKey" : "All"])
        }
    }

 

 
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete ) && (indexPath.section == 1) {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            managedContext.deleteObject(categories[indexPath.row])
            categories.removeAtIndex(indexPath.row)
            appDelegate.saveContext()
            tableView.reloadData()
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
 

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.isKindOfClass(SWRevealViewControllerSegueSetController) {
            
        }
    }


}
