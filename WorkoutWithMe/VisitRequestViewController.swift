//
//  VisitRequestViewController.swift
//  WorkoutWithMe
//
//  Created by Bobby Ren on 8/2/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit

class VisitRequestViewController: UITableViewController {
    let TAG_ICON = 1
    let TAG_TITLE = 2
    let TAG_DETAILS = 3
    
    var shouldShowEmergencyAlert: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.shouldShowEmergencyAlert = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if self.shouldShowEmergencyAlert {
            return 3
        }
        return 2
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 || indexPath.row == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("VisitRequestCell", forIndexPath: indexPath) as! UITableViewCell
            
            // Configure the cell...
            let icon: UIImageView = cell.contentView.viewWithTag(TAG_ICON) as! UIImageView
            let labelTitle: UILabel = cell.contentView.viewWithTag(TAG_TITLE) as! UILabel
            let labelDetails: UILabel = cell.contentView.viewWithTag(TAG_DETAILS) as! UILabel
            
            switch indexPath.row {
            case 0:
                icon.image = UIImage(named: "iconPill")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                icon.tintColor = UIColor(red: 215.0/255.0, green: 84.0/255.0, blue: 82.0/255.0, alpha: 1)
                labelTitle.text = "Sickness or injury"
                labelDetails.text = "See a doctor for a sickness, illness or malady"
                break
            case 1:
                icon.image = UIImage(named: "iconStethoscope")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                icon.tintColor = UIColor(red: 55/255.0, green: 123/255.0, blue: 181/255.0, alpha: 1)
                labelTitle.text = "Physical"
                labelDetails.text = "See a doctor for a physical exam or checkup"
                break
            default:
                break
            }
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("EmergencyCell", forIndexPath: indexPath) as! UITableViewCell
            let icon: UIImageView = cell.contentView.viewWithTag(TAG_ICON) as! UIImageView
            let labelTitle: UILabel = cell.contentView.viewWithTag(TAG_TITLE) as! UILabel
            icon.image = icon.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            icon.tintColor = UIColor.whiteColor()
            
            return cell
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let row = indexPath.row
        if row == 2 {
            self.shouldShowEmergencyAlert = false
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)
        }
        else {
            self.goToMap()
        }
    }

    func goToMap() {
        self.performSegueWithIdentifier("GoToMap", sender: self)
    }

}
