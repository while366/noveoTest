

import UIKit
import CoreData
import Alamofire
import AlamofireImage
import MWFeedParser
import DZNWebViewController

class FrontViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MWFeedParserDelegate, SWRevealViewControllerDelegate {
    
    @IBOutlet weak var noRSSView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    let searchController = UISearchController(searchResultsController: nil)
    var channels = [NSManagedObject]()
    var choosenChannel: String!
    var feeditem = [MWFeedItem]()
    var feedInfo = MWFeedInfo()
    var parsedItems = [MWFeedItem]()
    
    struct oneChannel {
        var rssName : String!
        var rssFeeds : [MWFeedItem]
    }
    var allRSSArray = [oneChannel]()
    var filterdAllRssArray = [oneChannel]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        choosenChannel = "All"
        tableView.tableFooterView = UIView()
        if self.revealViewController() != nil {
            self.revealViewController().delegate = self
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.revealViewController().rearViewRevealOverdraw = 0
        }
        setUpSearchBar()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadChannels()
    }
    
    //MARK: - Feed parser delegate
    
    func feedParserDidStart(parser: MWFeedParser!) {
        
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        allRSSArray.append(oneChannel(rssName: feedInfo.title, rssFeeds: parsedItems))
        parsedItems = [MWFeedItem]()
        if !channels.isEmpty {
            request()
        } else {
            AIManager.aiManager.removeActivityIndicator()
            self.tableView.reloadData()
        }
        
    }
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        feedInfo = info
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        parsedItems.append(item)
    }
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        if error.code == 2 {
            let alert = UIAlertController(title: "Error", message: "No network", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            AIManager.aiManager.removeActivityIndicator()
            return
        }
        if !channels.isEmpty {
            request()
        } else {
            AIManager.aiManager.removeActivityIndicator()
            self.tableView.reloadData()
        }
    }

    func request() {
        let url = NSURL(string: channels.removeFirst().valueForKey("channel") as! String)
        let feedParser = MWFeedParser(feedURL: url)
        feedParser.delegate = self
        feedParser.connectionType = ConnectionTypeAsynchronously
        feedParser.parse()
    }
    
    func reloadChannels() {
        AIManager.aiManager.addActivityIndicator(self.view, style: nil, color: nil, backgroundColor: nil)
        allRSSArray = [oneChannel]()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Channel")
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            if results.isEmpty {
                AIManager.aiManager.removeActivityIndicator()
                noRSSView.hidden = false
                return
            } else {
                noRSSView.hidden = true
            }
            switch choosenChannel {
            case "All":
                channels = results as! [NSManagedObject]
            case "Favorites":
                for result in results {
                    if result.valueForKey("isFavorite") as! Bool {
                        channels.append(result as! NSManagedObject)
                    }
                }
                if channels.isEmpty {
                    AIManager.aiManager.removeActivityIndicator()
                    noRSSView.hidden = false
                }
            default:
                channels.append(results[Int(choosenChannel)!] as! NSManagedObject)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        if !channels.isEmpty {
            request()
        }
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
        filterdAllRssArray = [oneChannel]()
        for item in allRSSArray {
            var filteredParsedItems = [MWFeedItem]()
            for feed in item.rssFeeds {
                if feed.title.lowercaseString.containsString(searchText.lowercaseString) {
                    filteredParsedItems.append(feed)
                }
            }
            if !filteredParsedItems.isEmpty {
                filterdAllRssArray.append(oneChannel(rssName: item.rssName, rssFeeds: filteredParsedItems))
            }
        }
        tableView.reloadData()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    //MARK: - TABLE VIEW DELEGATE
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if searchController.active && ( searchController.searchBar.text != "" ) {
            return filterdAllRssArray.count
        }
        return allRSSArray.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && ( searchController.searchBar.text != "" ) {
            return filterdAllRssArray[section].rssFeeds.count
        }
        return allRSSArray[section].rssFeeds.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FrontViewCell") as! TableViewCell
        var item = MWFeedItem()
        if searchController.active && searchController.searchBar.text != "" {
            item = filterdAllRssArray[indexPath.section].rssFeeds[indexPath.row]
        } else {
            item = allRSSArray[indexPath.section].rssFeeds[indexPath.row]
        }
        cell.name.text = item.title
        cell.icon.image = UIImage(named: "placeholder")
        if item.content != nil {
            let htmlContent = item.content as NSString
            var imageSource = ""
            let rangeOfString = NSMakeRange(0, htmlContent.length)
            let regex = try! NSRegularExpression(pattern: "<img.*?src=\"([^\"]*)\"", options: [])
            if htmlContent.length > 0 {
                let match = regex.firstMatchInString(htmlContent as String, options: [], range: rangeOfString)
                if match != nil {
                    let imageURL = htmlContent.substringWithRange(match!.rangeAtIndex(1)) as NSString
                    if NSString(string: imageURL.lowercaseString).rangeOfString("feedburner").location == NSNotFound {
                        imageSource = imageURL as String
                    }
                }
                
            }
            if imageSource != "" {
                cell.icon.af_setImageWithURL(NSURL(string: imageSource)!)
            } else {
                cell.icon.image = UIImage(named: "placeholder")
            }
        }
        return cell
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.active && searchController.searchBar.text != "" {
            return filterdAllRssArray[section].rssName
        }
        return allRSSArray[section].rssName
    }
  
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }
    
    var webModalNC: UINavigationController?
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let url = NSURL(string: allRSSArray[indexPath.section].rssFeeds[indexPath.row].link)
        let WVC = DZNWebViewController(URL: url)
        webModalNC = UINavigationController(rootViewController: WVC)
        WVC.supportedWebNavigationTools = DZNWebNavigationTools.All
        WVC.supportedWebActions = DZNsupportedWebActions.DZNWebActionAll
        WVC.showLoadingProgress = true
        WVC.allowHistory = true
        WVC.hideBarsWithGestures = true
        let closeButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(FrontViewController.dismissWebView))
        WVC.navigationItem.rightBarButtonItem = closeButton
        self.presentViewController(webModalNC!, animated: true, completion: nil)
        
    }
    
    // MARK: - Navigation
    
    func revealController(revealController: SWRevealViewController!, willMoveToPosition position: FrontViewPosition) {
        if revealViewController().frontViewPosition != FrontViewPosition.Left {
            reloadChannels()
        }
        
    }

    func dismissWebView() {
        webModalNC?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func reloadData(sender: AnyObject) {
        reloadChannels()
    }


}


