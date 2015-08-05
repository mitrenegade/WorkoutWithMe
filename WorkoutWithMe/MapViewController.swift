//
//  MapViewController.swift
//  WorkoutWithMe
//
//  Created by Bobby Ren on 8/1/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit
import GoogleMaps

enum RequestState: String {
    case NoRequest = "NoRequest"
    case Searching = "Searching"
    case Matched = "Matched"
    case Cancelled = "Cancelled"
}

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {

    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var iconLocation: UIImageView!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    @IBOutlet var buttonRequest: UIButton!
    
    // address view
    @IBOutlet var viewAddress: UIView!
    @IBOutlet var inputStreet: UITextField!
    @IBOutlet var inputCity: UITextField!
    
    // request status
    var requestState: RequestState = .NoRequest
    var requestAlert: UIAlertController?
    var requestMarker: GMSMarker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.buttonRequest.enabled = false
        
        locationManager.delegate = self
        
        if (locationManager.respondsToSelector("requestWhenInUseAuthorization")) {
            locationManager.requestWhenInUseAuthorization()
        }
        else {
            locationManager.startUpdatingLocation()
        }

        self.mapView.myLocationEnabled = true
        self.iconLocation.layer.zPosition = 1
        self.iconLocation.image = UIImage(named: "iconLocation")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.iconLocation.tintColor = UIColor(red: 215.0/255.0, green: 84.0/255.0, blue: 82.0/255.0, alpha: 1)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Done, target: self, action: "close")
        
        if let previousState: String = NSUserDefaults.standardUserDefaults().objectForKey("request:state") as? String {
            let newState: RequestState = RequestState(rawValue: previousState)!
            
            if newState == RequestState.Searching {
                let previousLat: Double? = NSUserDefaults.standardUserDefaults().objectForKey("request:lat") as? Double
                let previousLon: Double? = NSUserDefaults.standardUserDefaults().objectForKey("request:lon") as? Double
                
                if previousLat != nil && previousLon != nil {
                    self.currentLocation = CLLocation(latitude: previousLat!, longitude: previousLon!)
                    self.updateMapToCurrentLocation()
                    self.toggleRequestState(newState)
                    self.fakeSearchForDoctor()
                }
            }
            else {
                self.toggleRequestState(newState)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func close() {
        self.toggleRequestState(RequestState.NoRequest)
        self.navigationController!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
        else if status == .Denied {
            println("Authorization is not available")
        }
        else {
            println("status unknown")
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.first as? CLLocation {
            locationManager.stopUpdatingLocation()
            
            self.currentLocation = location
            self.updateMapToCurrentLocation()
            self.enableRequest()
        }
    }

    func updateMapToCurrentLocation() {
        var zoom = self.mapView.camera.zoom
        if zoom < 12 {
            zoom = 17
        }
        self.mapView.camera = GMSCameraPosition(target: self.currentLocation!.coordinate, zoom: zoom, bearing: 0, viewingAngle: 0)
    }
    
    func enableRequest() {
        self.buttonRequest.enabled = true
        self.buttonRequest.layer.zPosition = 1
    }
    // MARK: - GMSMapView  delegate
    func didTapMyLocationButtonForMapView(mapView: GMSMapView!) -> Bool {
        self.view.endEditing(true)

        if self.currentLocation != nil {
            self.updateMapToCurrentLocation()
        }
        locationManager.startUpdatingLocation()
        return false
    }
    
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        self.currentLocation = CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)
        self.enableRequest()
    }
    
    // MARK: Location search
    @IBAction func didClickSearch(button: UIButton) {
        var address: String = "\(self.inputStreet.text) \(self.inputCity.text)"
        println("address: \(address)")
        
        self.view.endEditing(true)
        
        let coder = CLGeocoder()
        coder.geocodeAddressString(address, completionHandler: { (results, error) -> Void in
            if error != nil {
                println("error: \(error.userInfo)")
                self.simpleAlert("Could not find that location", message: "Please check your address and try again")
            }
            else {
                println("result: \(results)")
                if let placemarks: [CLPlacemark] = results as? [CLPlacemark] {
                    if let placemark: CLPlacemark = placemarks.first as CLPlacemark! {
                        self.currentLocation = CLLocation(latitude: placemark.location.coordinate.latitude, longitude: placemark.location.coordinate.longitude)
                        self.updateMapToCurrentLocation()
                        self.enableRequest()
                    }
                }
            }
        })
    }
    
    // MARK: - TextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - request
    @IBAction func didClickRequest(sender: UIButton) {
        if self.requestState == RequestState.Searching {
            self.toggleRequestState(self.requestState)
            return
        }
        
        if self.currentLocation != nil {
            let coder = GMSGeocoder()
            coder.reverseGeocodeCoordinate(self.currentLocation!.coordinate, completionHandler: { (response, error) -> Void in
                if let gmresponse:GMSReverseGeocodeResponse = response as GMSReverseGeocodeResponse! {
                    let results: [AnyObject] = gmresponse.results()
                    let addresses: [GMSAddress] = results as! [GMSAddress]
                    let address: GMSAddress = addresses.first!
                    
                    var addressString: String = ""
                    let lines: [String] = address.lines as! [String]
                    for line: String in lines {
                        addressString = "\(addressString)\n\(line)"
                    }
                    println("Address: \(addressString)")
                    
                    self.confirmRequestForAddress(addressString, coordinate: address.coordinate)
                }
                else {
                    self.simpleAlert("Invalid location", message: "We could not request a visit; your current location is invalid")
                }
            })
        }
        else {
            self.simpleAlert("Invalid location", message: "We could not request a visit; your current location was invalid")
        }
    }
    
    func confirmRequestForAddress(addressString: String, coordinate: CLLocationCoordinate2D) {
        var alert: UIAlertController = UIAlertController(title: "Request doctor?", message: "Do you want to schedule a visit at \(addressString)?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Pronto!", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            println("requesting")
            self.toggleRequestState(RequestState.Searching)
            self.fakeSearchForDoctor()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func toggleRequestState(newState: RequestState) {
        self.requestState = newState
        NSUserDefaults.standardUserDefaults().setObject(newState.rawValue, forKey: "request:state")

        switch self.requestState {
        case .NoRequest:
            if self.requestAlert != nil {
                self.requestAlert!.dismissViewControllerAnimated(true, completion: nil)
            }
            self.requestAlert = nil
            self.buttonRequest.setTitle("Request a visit here", forState: UIControlState.Normal)
            if self.requestMarker != nil {
                self.requestMarker!.map = nil
                self.requestMarker = nil
                self.iconLocation.hidden = false
            }
            NSUserDefaults.standardUserDefaults().removeObjectForKey("request:lat")
            NSUserDefaults.standardUserDefaults().removeObjectForKey("request:lon")
            return
        case .Cancelled:
            if self.requestAlert != nil {
                self.requestAlert!.dismissViewControllerAnimated(true, completion: nil)
            }
            self.requestAlert = UIAlertController(title: "Search was cancelled", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            self.requestAlert?.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.toggleRequestState(RequestState.NoRequest)
            }))
            self.presentViewController(self.requestAlert!, animated: true, completion: nil)
            return
        case .Searching:
            if self.requestAlert != nil {
                self.requestAlert!.dismissViewControllerAnimated(true, completion: nil)
            }
            self.requestAlert = UIAlertController(title: "Searching for a doctor near you", message: "Please be patient while we connect you with a doctor. If this is an emergency, dial 911!", preferredStyle: UIAlertControllerStyle.Alert)
            self.requestAlert?.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                self.toggleRequestState(RequestState.Cancelled)
            }))
            self.requestAlert?.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            }))
            self.presentViewController(self.requestAlert!, animated: true, completion: nil)
            
            self.buttonRequest.setTitle("Searching for a doctor", forState: UIControlState.Normal)
            
            if self.requestMarker == nil {
                var marker = GMSMarker()
                marker.position = self.currentLocation!.coordinate
                marker.title = "Doctor's Visit"
                marker.snippet = "I need a doc, pronto"
                marker.map = self.mapView
                marker.icon = UIImage(named: "iconLocation")!
                self.requestMarker = marker
                
                self.iconLocation.hidden = true
            }
            NSUserDefaults.standardUserDefaults().setObject(self.currentLocation!.coordinate.latitude, forKey: "request:lat")
            NSUserDefaults.standardUserDefaults().setObject(self.currentLocation!.coordinate.longitude, forKey: "request:lon")
            
            break
        case .Matched:
            if self.requestAlert != nil {
                self.requestAlert!.dismissViewControllerAnimated(true, completion: nil)
            }
            self.requestAlert = UIAlertController(title: "A doctor was matched!", message: "Expect a call within the next hour from Dr. Klein.", preferredStyle: UIAlertControllerStyle.Alert)
            self.requestAlert?.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                self.toggleRequestState(RequestState.NoRequest)
            }))
            self.requestAlert?.addAction(UIAlertAction(title: "See doctor", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.viewDoctorInfo()
                self.toggleRequestState(RequestState.NoRequest)
            }))
            self.presentViewController(self.requestAlert!, animated: true, completion: nil)
            break
        default:
            break
        }
    }
    
    func fakeSearchForDoctor() {
        let timeInterval: NSTimeInterval = Double(arc4random() % 10) + 3
        NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: "didGetDoctor", userInfo: nil, repeats: false)
    }
    func didGetDoctor() {
        // TODO: this would be a delegate function for a parse call
        if self.requestState == RequestState.Searching {
            self.toggleRequestState(RequestState.Matched)
            if self.currentLocation != nil {
            }
        }
    }

    // TODO
    func viewDoctorInfo() {
        println("display doctor info")
        self.performSegueWithIdentifier("GoToViewDoctor", sender: nil)
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
