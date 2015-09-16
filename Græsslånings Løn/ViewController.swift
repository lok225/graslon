//
//  ViewController.swift
//  Græsslånings Løn
//
//  Created by Martin Lok on 01/08/2015.
//  Copyright © 2015 Martin Lok. All rights reserved.
//

import UIKit
import MessageUI

// Kommentar

class ViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var myTable: UITableView! {
        didSet {
            myTable.delegate = self
            myTable.dataSource = self
        }
    }
    
    @IBOutlet weak var lblPenge: UILabel!
    @IBOutlet weak var myDatePicker: UIDatePicker!
    
    // MARK: Variables & Constants
    
    let dateArrayKey = "dateArrayKey"
    let lastMailDateKey = "lastMailDate"
    
    var dateArray: [NSDate!] = []
    var defaults: NSUserDefaults!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if NSUserDefaults(suiteName: "group.martinlok.grasslaaningsLon") != nil {
            defaults = NSUserDefaults(suiteName: "group.martinlok.grasslaaningsLon")
            print("Shared")
        } else {
            defaults = NSUserDefaults.standardUserDefaults()
            print("Standard")
        }
        
        if defaults.objectForKey(dateArrayKey) == nil {
            defaults.setObject(dateArray, forKey: dateArrayKey)
            defaults.synchronize()
        }
    }
    
    
    @IBAction func btnTilføjDato(sender: UIButton) {
        
        let date = myDatePicker.date
        
        dateArray = defaults.objectForKey(dateArrayKey) as! [NSDate]
        dateArray.append(date)
        
        defaults.setObject(dateArray, forKey: dateArrayKey)
        defaults.synchronize()
        
        myTable.reloadData()
    }
    
    @IBAction func btnSendMail(sender: UIBarButtonItem) {
        
        defaults.setObject(NSDate(), forKey: lastMailDateKey)
        defaults.synchronize()
        
        guard MFMailComposeViewController.canSendMail() == true else {
            print("Kan ikke sende mail")
            createAndPresentAlert("Los problemos")
            return
        }
        
        let mailViewController = MFMailComposeViewController()
        mailViewController.setSubject("Græs Løn")
        mailViewController.setToRecipients(["Martinlok@icloud.com"])
        mailViewController.setMessageBody(createStringFromDateArray(self.dateArray), isHTML: false)
        mailViewController.mailComposeDelegate = self
        
        self.presentViewController(mailViewController, animated: true, completion: nil)
    }
    
    // MARK: - Helper Functions
    
    func createStringFromDateArray(array: [NSDate!]) -> String {
        
        let firstString = "Så er det igen blevet tid til jeg skal have løn for græsslåning. Det er stadig 200 kr per gang. \n \n"
        var secondString: String = ""
        
        dateArray = defaults.objectForKey(dateArrayKey) as! [NSDate]
        
        for date in dateArray {
            
            let calendar = NSCalendar.currentCalendar()
            let month = calendar.component(NSCalendarUnit.Month, fromDate: date)
            let day = calendar.component(NSCalendarUnit.Day, fromDate: date)
            
            let currentString = "\(day)/\(month) \n"
            secondString += currentString
        }
        let finalString = firstString + secondString
        
        return finalString
    }
    
    func createAndPresentAlert(message: String) {
        let alertController = UIAlertController(title: "Advarsel", message: message, preferredStyle: .Alert)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func datesSinceLastMail() -> [NSDate!]{
        
        let currentDateArray = defaults.objectForKey(dateArrayKey) as! [NSDate]
        
        guard let lastMailDate = defaults.objectForKey(lastMailDateKey) else {
            return dateArray
        }
        
        let newArray = currentDateArray.filter { (date: NSDate) -> Bool in
            
            let intervalSinceLastMail = date.timeIntervalSinceDate(lastMailDate as! NSDate)
            
            if intervalSinceLastMail >= 0 {
                return true
            } else {
                return false
            }
        }
        
        return newArray
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        dateArray = defaults.objectForKey(dateArrayKey) as! [NSDate]
        
        return dateArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        
        dateArray = defaults.objectForKey(dateArrayKey) as! [NSDate]
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        let dateString = dateFormatter.stringFromDate(dateArray[indexPath.row])
        cell.textLabel?.text = dateString
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        dateArray = defaults.objectForKey(self.dateArrayKey) as! [NSDate]
        dateArray.removeAtIndex(indexPath.row)
        defaults.setObject(dateArray, forKey: self.dateArrayKey)
        defaults.synchronize()
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
    }
}

extension ViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue:
            print("Mail cancelled")
        case MFMailComposeResultSaved.rawValue:
            print("Mail saved")
        case MFMailComposeResultSent.rawValue:
            print("Mail sent")
        case MFMailComposeResultFailed.rawValue:
            print("Mail sent failure: \(error!.localizedDescription)")
        default:
            break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

