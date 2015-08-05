//
//  CreditCardViewController.swift
//  WorkoutWithMe
//
//  Created by Bobby Ren on 8/2/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit

class CreditCardViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var labelCurrentCard: UILabel!
    @IBOutlet var inputCreditCard: UITextField!
    @IBOutlet var inputExpiration: UITextField!
    @IBOutlet var inputCVV: UITextField!

    var currentCard: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let card: String = NSUserDefaults.standardUserDefaults().objectForKey("creditcard:cached") as? String {
            self.currentCard = card
            let last4:String = self.currentCard!.substringFromIndex(advance(card.endIndex, -4))
            self.labelCurrentCard.text = "Your current credit card is *\(last4)"
        }
        else {
            self.labelCurrentCard.text = "Please enter a new credit card"
        }
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: UIBarButtonItemStyle.Done, target: self, action: "close")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func close() {
        self.navigationController!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == self.inputCreditCard {
            if count(textField.text) != 16 {
                self.simpleAlert("Invalid credit card number", message: "Please make sure you enter the credit card number correctly")
                self.inputCreditCard.becomeFirstResponder()
            }
            else {
                NSUserDefaults.standardUserDefaults().setObject(self.inputCreditCard.text, forKey: "creditcard:cached")
            }
        }
    }
    
    func simpleAlert(title: String?, message: String?) {
        var alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
