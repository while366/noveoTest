//
//  DetailsViewController.swift
//  SoftomateTestTask
//
//  Created by Mikhail Zhadko on 5/29/16.
//  Copyright © 2016 Mikhail Zhadko. All rights reserved.
//

import UIKit
import CoreData
import QuartzCore

class DetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var lastName: UILabel!
    @IBOutlet weak var firstName: UILabel!
    var person : NSManagedObject!
    var categories = [NSManagedObject]()
    var checked = [Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        photo.layer.masksToBounds = true
        photo.layer.cornerRadius = photo.frame.width / 2
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
        checked = Array(count: categories.count, repeatedValue: false)
        print(person.valueForKeyPath("categories.category")!.allObjects)

        for item in categories.enumerate() {
            if let temp = person.valueForKeyPath("categories.category")!.allObjects{
                if temp.contains(item.element.valueForKey("category") as! String) {
                    checked[item.index] = true
                } else {
                    checked[item.index] = false
                }
            }
        }
//        for item in checked.enumerate() {
//            if person.valueForKeyPath("categories.category")!.containsObject(categories[item.index]) {
//                checked[item.index] = true
//            } else {
//                checked[item.index] = false
//            }
//        }
        
        if person.valueForKey("firstName") != nil {
            firstName.text = "\(person.valueForKey("firstName")!) "
        } else {
            firstName.text = "First Name"
            firstName.textColor = UIColor.grayColor()
        }
        if person.valueForKey("lastName") != nil {
            lastName.text = "\(person.valueForKey("lastName")!) "
        } else {
            lastName.text = "Last Name"
            lastName.textColor = UIColor.grayColor()
        }
        if person.valueForKey("phone") != nil {
            phone.text = "\(person.valueForKey("phone")!) "
        } else {
            phone.text = "Phone"
            phone.textColor = UIColor.grayColor()
        }
        if person.valueForKey("address") != nil {
            address.text = "\(person.valueForKey("address")!) "
        } else {
            address.text = "Address"
            address.textColor = UIColor.grayColor()
        }
        guard let data = person.valueForKey("photo") as? NSData else {
            photo.image = UIImage(named: "noPhoto")
            return
        }
        photo.image = UIImage(data: data)
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        person.setValue(nil, forKey: "categories")
        for item in categories.enumerate() {
            if checked[item.index] {
                let categories = person.mutableSetValueForKey("categories")
                categories.addObject(item.element)
            }
        }
    }
    
    //MARK: - Table view delegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("detailsCell", forIndexPath: indexPath)
        cell.textLabel?.text = categories[indexPath.row].valueForKey("category") as? String
        if !checked[indexPath.row] {
            cell.accessoryType = .None
        } else if checked[indexPath.row] {
            cell.accessoryType = .Checkmark
        }
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if cell.accessoryType == .Checkmark {
                cell.accessoryType = .None
                checked[indexPath.row] = false
            } else {
                cell.accessoryType = .Checkmark
                checked[indexPath.row] = true
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Categories"
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
extension Array {
    func contains<T where T : Equatable>(obj: T) -> Bool {
        return self.filter({$0 as? T == obj}).count > 0
    }
}
