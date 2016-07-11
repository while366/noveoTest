


import UIKit
import CoreData
import MWFeedParser

class checkLink: NSObject, MWFeedParserDelegate {
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
    }
}

class MenuTableViewController: UITableViewController, MWFeedParserDelegate {

    let check = checkLink()
    var channels = [NSManagedObject]()
    let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()
    var feedInfo = [MWFeedInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadSources()
    }
    
    //MARK: - FEED PARSER DELEGARE + METHODS
    
    func feedParserDidStart(parser: MWFeedParser!) {
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
    }
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        feedInfo.append(info)
        
    }
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        if error.code == 2 {
            let alert = UIAlertController(title: "Error", message: "No network", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            AIManager.aiManager.removeActivityIndicator()
            return
        }
    }

    func reloadSources() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Channel")
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            channels = results as! [NSManagedObject]
            loadRSSList()
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func request(rssString: String) {
        let url = NSURL(string: rssString)
        let feedParser = MWFeedParser(feedURL: url)
        feedParser.delegate = self
        feedParser.connectionType = ConnectionTypeSynchronously
        feedParser.feedParseType = ParseTypeInfoOnly
        feedParser.parse()
    }
    func loadRSSList() {
        feedInfo = [MWFeedInfo]()
        
        for item in channels {
            request(item.valueForKey("channel") as! String)
        }
        self.tableView.reloadData()
        
    }

    @IBAction func addCategory(sender: AnyObject) {
        let alert = UIAlertController(title: "New Channel",
                                      message: "Add a new RSS",
                                      preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .Default,
                                       handler: { (action:UIAlertAction) -> Void in
                                        
                                        let textField = alert.textFields!.first
                                        
                                        guard let temp = textField?.text! where !temp.stringByTrimmingCharactersInSet(self.whitespaceSet).isEmpty else {
                                            return
                                        }
                                        do {
                                            let feedParser = MWFeedParser(feedURL: NSURL(string: (textField?.text)!))
                                            feedParser.connectionType = ConnectionTypeSynchronously
                                            feedParser.delegate = self.check
                                            if feedParser.parse() == false {
                                                let alert = UIAlertController(title: "Error", message: "Incorrect link type provided.", preferredStyle: UIAlertControllerStyle.Alert)
                                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                                                self.presentViewController(alert, animated: true, completion: nil)
                                                return
                                            }

                                        }
                                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                                        let managedContext = appDelegate.managedObjectContext
                                        let entity =  NSEntityDescription.entityForName("Channel", inManagedObjectContext:managedContext)
                                        let channel = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
                                        channel.setValue(textField?.text!, forKey: "channel")
                                        appDelegate.saveContext()
                                        self.reloadSources()
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


    // MARK: - TABLE VIEW DELEGATE

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return feedInfo.count
        }
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("menuCell", forIndexPath: indexPath)
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "All"
        case 1:
            cell.textLabel?.text = "Favorites"
        case 2:
            cell.textLabel?.text = feedInfo[indexPath.row].title
        default:
            break
        }
        
        return cell
    }
    
    //MARK: - TABLE VIEW DATA SOURCE
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let secondVC = (self.revealViewController().frontViewController as! CustomNavigationViewController).topViewController as! FrontViewController
        switch indexPath.section {
        case 0:
            secondVC.choosenChannel = "All"
        case 1:
            secondVC.choosenChannel = "Favorites"
        case 2:
            secondVC.choosenChannel = "\(indexPath.row)"
        default:
            break
        }
        self.revealViewController().revealToggle(self)
    }

 
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 2 {
            return true
        } else {
            return false
        }
    }
 
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete ) {

        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let favoriteAction = UITableViewRowAction(style: .Normal, title: channels[indexPath.row].valueForKey("isFavorite") as! Bool ? "Unfavorite" : "Favorite") { (action, indexPath) in
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            let fetchRequest = NSFetchRequest(entityName: "Channel")
            do {
                let results = try managedContext.executeFetchRequest(fetchRequest)
                let channel = results[indexPath.row]
                let tempBool = self.channels[indexPath.row].valueForKey("isFavorite") as! Bool ? false : true
                channel.setValue(tempBool, forKey: "isFavorite")
                appDelegate.saveContext()
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
            self.reloadSources()
        }
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) in
            let secondVC = (self.revealViewController().frontViewController as! CustomNavigationViewController).topViewController as! FrontViewController
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            managedContext.deleteObject(self.channels[indexPath.row])
            appDelegate.saveContext()
            if secondVC.choosenChannel == "\(indexPath.row)" {
                secondVC.choosenChannel = "All"
            }
            self.reloadSources()
        }
        return [deleteAction, favoriteAction]
    }

    // MARK: - Navigation


}
