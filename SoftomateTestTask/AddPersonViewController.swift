//
//  AddPersonViewController.swift
//  SoftomateTestTask
//
//  Created by Mikhail Zhadko on 5/25/16.
//  Copyright © 2016 Mikhail Zhadko. All rights reserved.
//

import UIKit
import CoreData

class AddPersonViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var icon: UIImageView!
    let imagePicker = UIImagePickerController()
    let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()
    var categories = [NSManagedObject]()
    var checked = [Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        imagePicker.delegate = self
        let tapGesture = UITapGestureRecognizer(target:self, action:#selector(AddPersonViewController.imagePressed))
        icon.userInteractionEnabled = true
        icon.addGestureRecognizer(tapGesture)
        phone.delegate = self
        phone.keyboardType = .NumberPad

        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        saveButton.enabled = false
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
    }
    
    override func viewWillLayoutSubviews() {
        icon.layer.borderWidth = 0
        icon.layer.cornerRadius = icon.bounds.height / 2
        icon.clipsToBounds = true
    }

    func imagePressed() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    // MARK: - TextfieldDelegate

    func textFieldDidBeginEditing(textField: UITextField) {
//
//        if !firstName.text!.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty || !lastName.text!.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty  {
//            saveButton.enabled = true
//        } else {
//            saveButton.enabled = false
//        }

        
    }
    
    @IBAction func lastNameChanged(sender: AnyObject) {
        isEmpty()
    }

    @IBAction func firstNameChanged(sender: AnyObject) {
        isEmpty()
    }
    
    func isEmpty () {
        
        guard let text = firstName.text where !text.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty else {
            guard let text = lastName.text where !text.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty else {
                saveButton.enabled = false
                return
            }
            saveButton.enabled = true
            return
        }
        saveButton.enabled = true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    {
        if (textField == phone)
        {
            let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            
            let decimalString = components.joinWithSeparator("") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.characterAtIndex(0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11
            {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne
            {
                formattedString.appendString("1 ")
                index += 1
            }
            if (length - index) > 3
            {
                let areaCode = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("(%@)", areaCode)
                index += 3
            }
            if length - index > 3
            {
                let prefix = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substringFromIndex(index)
            formattedString.appendString(remainder)
            textField.text = formattedString as String
            return false
        }
        else
        {
            return true
        }
    }
    
    //MARK: - Table view delegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("addNewPersonCell", forIndexPath: indexPath)
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
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            icon.image = pickedImage
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Navigation

     @IBAction func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
     }

    //MARK: - SaveContact
    @IBAction func saveContact(sender: AnyObject) {
        saveToCoreData()
        dismissViewControllerAnimated(true, completion: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("modalDismissed", object: nil)

    }
    func saveToCoreData() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entityForName("Person", inManagedObjectContext:managedContext)
        let person = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)

        saveFirstName(person)
        saveLastName(person)
        savePhone(person)
        saveAddress(person)
        saveIcon(person)
        
        for item in categories.enumerate() {
            if checked[item.index] {
                let categories = person.mutableSetValueForKey("categories")
                categories.addObject(item.element)
//                person.setValue(NSSet(object: item.element), forKey: "categories")
            }
        }
        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    func saveFirstName(person: NSManagedObject) {
        guard let firstName = self.firstName.text where !firstName.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty else {
            return
        }
        person.setValue(firstName, forKey: "firstName")
    }
    func saveLastName(person: NSManagedObject) {
        guard let lastName = self.lastName.text where !lastName.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty else {
            return
        }
        person.setValue(lastName, forKey: "lastName")
    }
    func savePhone(person: NSManagedObject) {
        guard let phone = self.phone.text where !phone.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty else {
            return
        }
        person.setValue(phone, forKey: "phone")
        
    }
    func saveAddress(person: NSManagedObject) {
        guard let address = self.address.text where !address.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty else {
            return
        }
        person.setValue(address, forKey: "address")
    }
    func saveIcon(person: NSManagedObject) {
        if icon.image != UIImage(named: "defaultIcon") {
            person.setValue(UIImageJPEGRepresentation(icon.image!, 1), forKey: "photo")
        }
        
    }

}
