//
//  FlightDetailsViewController.swift
//  TripKey2
//
//  Created by Peter on 9/15/16.
//  Copyright © 2016 Fontaine. All rights reserved.
//

import UIKit
import MapKit
import GoogleMobileAds
import StoreKit
import UserNotifications

class FlightDetailsViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @IBOutlet var flightNotificationsButton: UIButton!
    let blurEffectViewActivity = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.regular))
    var activityLabel = UILabel()
    var flightCount:[Int] = []
    let closeButton = UIButton()
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.regular))
    @IBOutlet var addFlightButton: UIButton!
    let notificationsManager = Bundle.main.loadNibNamed("Notification manager", owner: self, options: nil)?[0] as! NotificationsManagerView
    var notifyBankOfTravel:Bool!
    //var fourHours:Bool!
    var importantChanges:Bool!
    var notifyTripContacts:Bool!
    //var oneHour:Bool!
    var passportVisaExpirations:Bool!
    var travelVaccinationExpirations:Bool!
    //var twoDays:Bool!
    //var twoHours:Bool!
    var dictionaryIataArray:[Dictionary<String,String>]! = []
    var dictionaryIcaoArray:[Dictionary<String,String>]! = []
    var fsCode:String!
    var autoCompletePossibilitiesArray:[String]! = []
    var autoCompletePossibilitiesDictionary:[Dictionary<String,String>]! = []
    var fsCodes:[String]! = []
    var iataCodes:[String]! = []
    var icaoCodes:[String]! = []
    var airlineNames:[String]! = []
    var autoComplete = [String]()
    @IBOutlet var autoSuggestTable: UITableView!
    //@IBOutlet var referenceNumber: UITextField!
    var legs = [Dictionary<String,String>]()
    var sortedLegs = [Dictionary<String,String>]()
    var currentDateWhole:String!
    var activityIndicator:UIActivityIndicatorView!
    var number:String! = ""
    var refNumber:String! = " "
    var airlineNameArrayString:String! = ""
    var flights = [Dictionary<String,String>]()
    var sortedFlights = [Dictionary<String,String>]()
    @IBOutlet var myDatePicker: UIDatePicker!
    @IBOutlet weak var selectedDate: UILabel!
    var formattedFlightNumber:String!
    var formattedDepartureDate:String!
    @IBOutlet var airlineCode: UITextField!
    @IBOutlet var flightNumber: UITextField!
    var flightNumberTextField: String!
    var formattedTextFieldFlightNumber:String!
    var departureDate: String!
    @IBOutlet var departingDateTextField: UITextField!
    var button = UIButton(type: UIButtonType.custom)
    @IBOutlet var departureLabel: UILabel!
    let PREMIUM_PRODUCT_ID = "com.TripKeyLite.unlockPremium"
    var productID = ""
    var productsRequest = SKProductsRequest()
    var iapProducts = [SKProduct]()
    var nonConsumablePurchaseMade = UserDefaults.standard.bool(forKey: "nonConsumablePurchaseMade")
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        nonConsumablePurchaseMade = true
        UserDefaults.standard.set(nonConsumablePurchaseMade, forKey: "nonConsumablePurchaseMade")
        
        DispatchQueue.main.async {
            
            self.activityIndicator.stopAnimating()
            self.activityLabel.removeFromSuperview()
            self.blurEffectViewActivity.removeFromSuperview()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
        }
        
        UIAlertView(title: NSLocalizedString("TripKey", comment: ""),
                    message: NSLocalizedString("You've successfully restored your purchase!", comment: ""),
                    delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment: "")).show()
    }
    
    // MARK: - FETCH AVAILABLE IAP PRODUCTS
    func fetchAvailableProducts()  {
        
        // Put here your IAP Products ID's
        let productIdentifiers = NSSet(objects: PREMIUM_PRODUCT_ID)
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
    
    // MARK: - REQUEST IAP PRODUCTS
    func productsRequest (_ request:SKProductsRequest, didReceive response:SKProductsResponse) {
        
        
        
        if (response.products.count > 0) {
            
            iapProducts = response.products
            
            // 1st IAP Product (Consumable) ------------------------------------
            let firstProduct = response.products[0] as SKProduct
            
            // Get its price from iTunes Connect
            let numberFormatter = NumberFormatter()
            numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = firstProduct.priceLocale
            //let price1Str = numberFormatter.string(from: firstProduct.price)
            
            // Show its description
            //upgradePrice = firstProduct.localizedDescription + "\nfor just \(price1Str!)"
            // ------------------------------------------------
            
            
            
        }
    }
    
    // MARK: - MAKE PURCHASE OF A PRODUCT
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }
    
    func purchaseMyProduct(product: SKProduct) {
        
        DispatchQueue.main.async {
            self.activityLabel.text = "Purchasing"
            self.addActivityIndicatorCenter()
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        
        if self.canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            productID = product.productIdentifier
            
            
            
            // IAP Purchases dsabled on the Device
        } else {
            
            DispatchQueue.main.async {
                
                self.activityIndicator.stopAnimating()
                self.activityLabel.removeFromSuperview()
                self.blurEffectViewActivity.removeFromSuperview()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
            }
            
            UIAlertView(title: NSLocalizedString("TripKey", comment: ""),
                        message: NSLocalizedString("Purchases are disabled in your device!", comment: ""),
                        delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment: "")).show()
        }
    }
    
    
    
    // MARK:- IAP PAYMENT QUEUE
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        
        
        for transaction:AnyObject in transactions {
            
            if let trans = transaction as? SKPaymentTransaction {
                
                switch trans.transactionState {
                    
                case .purchased:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    
                    
                    // The Non-Consumable product (Premium) has been purchased!
                    if productID == PREMIUM_PRODUCT_ID {
                        
                        // Save your purchase locally (needed only for Non-Consumable IAP)
                        nonConsumablePurchaseMade = true
                        UserDefaults.standard.set(nonConsumablePurchaseMade, forKey: "nonConsumablePurchaseMade")
                        
                        //premiumLabel.text = "Premium version PURCHASED!"
                        
                        DispatchQueue.main.async {
                            
                            self.activityIndicator.stopAnimating()
                            self.activityLabel.removeFromSuperview()
                            self.blurEffectViewActivity.removeFromSuperview()
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            
                        }
                        
                        UIAlertView(title: NSLocalizedString("TripKey", comment: ""),
                                    message: NSLocalizedString("You've successfully unlocked the Premium version!", comment: ""),
                                    delegate: nil,
                                    cancelButtonTitle: NSLocalizedString("OK", comment: "")).show()
                    }
                    
                    break
                    
                case .failed:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    DispatchQueue.main.async {
                        
                        self.activityIndicator.stopAnimating()
                        self.activityLabel.removeFromSuperview()
                        self.blurEffectViewActivity.removeFromSuperview()
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                    }
                    break
                case .restored:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    DispatchQueue.main.async {
                        
                        self.activityIndicator.stopAnimating()
                        self.activityLabel.removeFromSuperview()
                        self.blurEffectViewActivity.removeFromSuperview()
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                    }
                    break
                    
                default: break
                }}}
    }

    
    func purchasePremium() {
        
        
            
            self.fetchAvailableProducts()
            
            let alert = UIAlertController(title: NSLocalizedString("Youv'e reached your limit of free flights.", comment: ""), message: NSLocalizedString("This will be a one time charge that is valid even if you switch phones or uninstall TripKey.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Unlock Premium for $2.99", comment: ""), style: .default, handler: { (action) in
                
                self.purchaseMyProduct(product: self.iapProducts[0])
                
                
                
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("No Thanks", comment: ""), style: .default, handler: { (action) in
                
                
                
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Restore Purchases", comment: ""), style: .default, handler: { (action) in
                
                SKPaymentQueue.default().add(self)
                SKPaymentQueue.default().restoreCompletedTransactions()
                
            }))
            
            self.present(alert, animated: true, completion: nil)
            
            
        
    }
    
    @IBAction func back(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    
   
    @IBAction func addFlight(_ sender: AnyObject) {
        
        //for tripKey
        self.nonConsumablePurchaseMade = true
        
       if self.flightCount.count >= 5 && self.nonConsumablePurchaseMade == false {
        
        let alert = UIAlertController(title: NSLocalizedString("You've reached your limit of flights!", comment: ""), message: "TripKey has taken an enourmous amount of work and it costs us money to provide you this service, please support the app and purchase the premium version, we GREATLY appreciate it :)", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Sure! :)", comment: ""), style: .default, handler: { (action) in
        
            self.purchasePremium()
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("No :(", comment: ""), style: .default, handler: { (action) in
            
            
        }))
        
        self.present(alert, animated: true, completion: nil)
        
        
        
       } else if self.flightCount.count >= 5 && self.nonConsumablePurchaseMade {
        
        if flightNumber.text == "" && airlineCode.text == "" {
            
            let alert = UIAlertController(title: NSLocalizedString("Please enter a Flight Number", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else if flightNumber.text == "" {
            
            let alert = UIAlertController(title: NSLocalizedString("Please enter a Flight Number", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else if airlineCode.text == "" {
            
            let alert = UIAlertController(title: NSLocalizedString("Please enter a Flight Number", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            formattedTextFieldFlightNumber = flightNumber.text!
            
            var characters: [Character] = Array(flightNumber.text!.characters)
            
            for _ in characters {
                
                if characters[0] == "0" {
                    
                    characters.remove(at: 0)
                    self.formattedTextFieldFlightNumber = String(characters)
                    
                }
                
            }
            
            flightNumberTextField = "\(airlineCode.text!)" + "\(flightNumber.text!)"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY/MM/dd"
            departureDate = dateFormatter.string(from: myDatePicker.date)
            self.parseFlightNumber()
            
        }

       } else if self.flightCount.count < 5 {
        
        if flightNumber.text == "" && airlineCode.text == "" {
            
            let alert = UIAlertController(title: NSLocalizedString("Please enter a Flight Number", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else if flightNumber.text == "" {
            
            let alert = UIAlertController(title: NSLocalizedString("Please enter a Flight Number", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else if airlineCode.text == "" {
            
            let alert = UIAlertController(title: NSLocalizedString("Please enter a Flight Number", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            formattedTextFieldFlightNumber = flightNumber.text!
            
            var characters: [Character] = Array(flightNumber.text!.characters)
            
            for _ in characters {
                
                if characters[0] == "0" {
                    
                    characters.remove(at: 0)
                    self.formattedTextFieldFlightNumber = String(characters)
                    
                }
                
            }
            
            flightNumberTextField = "\(airlineCode.text!)" + "\(flightNumber.text!)"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY/MM/dd"
            departureDate = dateFormatter.string(from: myDatePicker.date)
            self.parseFlightNumber()
            
        }
        
        }

        
     }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return UIInterfaceOrientationMask.portrait }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("This is viewdidload FlightDetailsViewController")
        //getAirlineCodes()
        
        flightNotificationsButton.setTitle(NSLocalizedString("Flight Notifications", comment: ""), for: .normal)
        
        departureLabel.text = NSLocalizedString("Departure", comment: "")
        
        addFlightButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        addFlightButton.setTitle(NSLocalizedString("Add Flight", comment: ""), for: .normal)
        
        if UserDefaults.standard.object(forKey: "flightCount") != nil {
            
            self.flightCount = UserDefaults.standard.object(forKey: "flightCount") as! [Int]
            
        } else {
            
            self.flightCount = []
            
        }
        
        if UserDefaults.standard.object(forKey: "airlines") != nil {
            
            self.autoCompletePossibilitiesArray = UserDefaults.standard.object(forKey: "airlines") as! [String]
            
        } else {
            
            getAirlineCodes()
            
        }
        
        //googleBanner.adUnitID = "ca-app-pub-1006371177832056/4508293729"
        //googleBanner.rootViewController = self
        //googleBanner.load(GADRequest())
        
        autoSuggestTable.isHidden = true
        
        flights = []
        
        self.airlineCode.delegate = self
        self.flightNumber.delegate = self
        //self.referenceNumber.delegate = self
        self.autoSuggestTable.delegate = self
        
        myDatePicker.datePickerMode = UIDatePickerMode.date
        let currentDate = NSDate()
        myDatePicker.date = currentDate as Date
        
        if (UserDefaults.standard.object(forKey: "flights") != nil) {
            
            flights = UserDefaults.standard.object(forKey: "flights") as! [Dictionary<String,String>]
        }
        
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                // Notifications not allowed
                
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "You have not allowed notifications yet", message: "You will NOT get any notifications for this flight, please update notification settings for TripKey to get notifications.", preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: "No Thanks", style: .default, handler: { (action) in
                        
                        
                    }))
                    
                    alertController.addAction(UIAlertAction(title: "Update Settings", style: .default, handler: { (action) in
                        
                        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                            UIApplication.shared.openURL(url as URL)
                        }
                        
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                    
                    print("notifications denied")
                    
                }
            }
        }
        
    }
    
    func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: self.notificationsManager)
        
        let notificationView = gestureRecognizer.view!
        
        notificationView.center = CGPoint(x: self.view.bounds.width / 2 + translation.x, y: self.view.bounds.height / 2 + translation.y)
       // let xFromCenter = notificationView.center.x - self.view.bounds.width / 2
        let yFromCenter = notificationView.center.y - self.view.bounds.width / 2
        
        if gestureRecognizer.state == UIGestureRecognizerState.ended {
            
            if yFromCenter >= 200 {
                
                UIView.animate(withDuration: 0.5, animations: {
                    
                    self.blurEffectView.alpha = 0
                    self.notificationsManager.alpha = 0
                    
                }) { _ in
                    
                    self.blurEffectView.removeFromSuperview()
                    self.notificationsManager.removeFromSuperview()
                    
                }
                
                print("swiped down")
                
            }
        } else {
            
            notificationView.center = CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2)
        }
        
        //print(translation)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        autoSuggestTable.tableFooterView = UIView()
        autoSuggestTable.reloadData()
        
        //setNotifications()
        
        if UserDefaults.standard.bool(forKey: "twoHours") != true && UserDefaults.standard.bool(forKey: "landing") != true && UserDefaults.standard.bool(forKey: "takeOff") != true && UserDefaults.standard.bool(forKey: "fourHours") != true && UserDefaults.standard.bool(forKey: "oneHour") != true && UserDefaults.standard.bool(forKey: "twoDays") != true {
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: NSLocalizedString("Notifications are off", comment: ""), message: NSLocalizedString("Would you like to set your notification settings for flights?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action) in
                    
                    self.setNotifications()
                    
                }))
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .default, handler: { (action) in
                    
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    func setNotifications() {
        
        blurEffectView.frame = self.view.frame
        let draggedDown = UIPanGestureRecognizer(target: self, action: #selector(self.wasDragged(gestureRecognizer:)))
        notificationsManager.center = self.view.center
        notificationsManager.addGestureRecognizer(draggedDown)
        blurEffectView.alpha = 0
        notificationsManager.alpha = 0
        view.addSubview(blurEffectView)
        view.addSubview(notificationsManager)
        
        
        closeButton.frame = CGRect(x: view.frame.maxX - 90, y: view.bounds.minY + 30, width: 30, height: 30)
        closeButton.backgroundColor = UIColor.red
        closeButton.setTitle("X", for: .normal)
        closeButton.layer.cornerRadius = 5
        closeButton.addTarget(self, action: #selector(self.closeNotifications), for: .touchUpInside)
        closeButton.alpha = 0
        view.addSubview(closeButton)
        
        UserDefaults.standard.set(notificationsManager.landing.isOn, forKey: "landing")
        UserDefaults.standard.set(notificationsManager.takeOff.isOn, forKey: "takeOff")
        UserDefaults.standard.set(notificationsManager.fourHours.isOn, forKey: "fourHours")
        UserDefaults.standard.set(notificationsManager.twoHours.isOn, forKey: "twoHours")
        UserDefaults.standard.set(notificationsManager.oneHour.isOn, forKey: "oneHour")
        UserDefaults.standard.set(notificationsManager.twoDays.isOn, forKey: "twoDays")
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.blurEffectView.alpha = 1
            self.notificationsManager.alpha = 1
            self.closeButton.alpha = 1
            
        }) { _ in
            
            
        }
    }
    
    func closeNotifications() {
      
        UIView.animate(withDuration: 0.5, animations: {
            
            self.blurEffectView.alpha = 0
            self.notificationsManager.alpha = 0
            self.closeButton.alpha = 0
            
        }) { _ in
            
            self.blurEffectView.removeFromSuperview()
            self.notificationsManager.removeFromSuperview()
            self.closeButton.removeFromSuperview()
        }

        
    }
    
    @IBAction func notificationsButton(_ sender: Any) {
        
        setNotifications()
        
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
        
        
        if let touch = touches.first {
            let currentPoint = touch.location(in: self.view)
            //let someFrame = CGRectMake(10,10,100,100)
            let isPointInTable = self.autoSuggestTable.frame.contains(currentPoint)
            
            if isPointInTable == false {
                
                self.autoSuggestTable.isHidden = true
                
            }
            
            //let isPointInFlightNumber = self.flightNumber.frame.contains(currentPoint)
            
            
        }
        
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        flightNumber.resignFirstResponder()
        airlineCode.resignFirstResponder()
        departingDateTextField.resignFirstResponder()
        //referenceNumber.resignFirstResponder()
        return true
        
    }

    func parseFlightNumber() {
        
        self.activityLabel.text = "Getting Flight"
        addActivityIndicatorCenter()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
 
        if let url = URL(string: "https://api.flightstats.com/flex/schedules/rest/v1/json/flight/" + (self.airlineCode.text!) + "/" + (self.formattedTextFieldFlightNumber!) + "/departing/" + (departureDate!) + "?appId=16d11b16&appKey=821a18ad545a57408964a537526b1e87") {
            
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        
                        print(error as Any)
                        
                        DispatchQueue.main.async {
                                
                                self.activityIndicator.stopAnimating()
                                self.activityLabel.removeFromSuperview()
                                self.blurEffectViewActivity.removeFromSuperview()
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                
                            
                            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Internet connection appears to be offline.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                            
                            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                                
                            }))
                            
                            self.present(alert, animated: true, completion: nil)
                            
                        }

                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonFlightData = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                var airport1:NSDictionary! = [:]
                                var airport2:NSDictionary! = [:]
                                //var airport3:NSDictionary! = [:]
                                //var airport4:NSDictionary! = [:]
                                var airport1FsCode:String! = ""
                                var airport2FsCode:String! = ""
                                //var airport3FsCode:String! = ""
                                //var airport4FsCode:String! = ""
                                var departureAirport:NSDictionary! = [:]
                                var arrivalAirport:NSDictionary! = [:]
                                var airlineName:String! = ""
                                var phoneNumber:String! = ""
                                var aircraft:String! = ""
                                var departureAirportCode:String! = ""
                                var arrivalAirportCode:String! = ""
                                var airlineCode:String! = ""
                                var arrivalDate:String! = ""
                                var flightNumber:String! = ""
                                var departureDate:String! = ""
                                var departureTerminal:String! = "-"
                                var arrivalTerminal:String! = "-"
                                var departureGate:String! = "-"
                                var arrivalGate:String! = "-"
                                var departureCountry:String! = ""
                                var departureLongitude:Double! = 0
                                //var departureAirportIata:String!
                                var departureLatitude:Double! = 0
                                var departureCity:String! = ""
                                var departureUtcOffset:Double! = 0
                                var arrivalCountry:String! = ""
                                var arrivalLongitude:Double! = 0
                                //var arrivalAirportIata:String! = ""
                                var arrivalLatitude:Double! = 0
                                var arrivalCity:String! = ""
                                var arrivalUtcOffset:Double! = 0
                                var airlineNameArrayString:String! = ""
                                var airlineNameArray:[String]! = []
                                var leg1:Dictionary<String,String>! = [:]
                                //var leg2:Dictionary<String,String>! = [:]
                                //var leg3:Dictionary<String,String>! = [:]
                                //var legs:[Dictionary<String,String>] = [[:]]
                                var convertedDepartureDate:String! = ""
                                var departureDateNumber:String! = ""
                                var departureDateUtc:String! = ""
                                var convertedArrivalDate:String! = ""
                                var arrivalDateNumber:String! = ""
                                var arrivalDateUtc:String! = ""
                                var departureDateUtcNumber:String! = ""
                                var urlDepartureDate:String! = ""
                                var urlArrivalDate:String! = ""
                                //var aircraftIata:String! = ""
                                //var airplaneIataCode:String! = ""
                                var arrivalDateUtcNumber:String! = ""
                                
                                
                                if let aircraftCheck = ((((jsonFlightData)["appendix"] as? NSDictionary)?["equipments"] as? NSArray)?[0] as? NSDictionary)?["name"] as? String {
                                    
                                    aircraft = aircraftCheck
                                }
                                
                                /*
                                if let aircraftIataCheck = ((((jsonFlightData)["appendix"] as? NSDictionary)?["equipments"] as? NSArray)?[0] as? NSDictionary)?["iata"] as? String {
                                    
                                    aircraftIata = aircraftIataCheck
                                }
                                */
                                
                                if let airlinesArray = ((jsonFlightData)["appendix"] as? NSDictionary)?["airlines"] as? NSArray {
                                    
                                    for item in airlinesArray {
                                        
                                        let obj = item as! NSDictionary
                                        let bookingAirlineName:String! = obj["name"] as? String
                                        let fs:String! = obj["fs"] as? String
                                        let iata:String! = obj["iata"] as? String
                                        let icao:String! = obj["icao"] as? String
                                        let airlineCode = "\(self.airlineCode.text!)"
                                        
                                        if airlineCode.uppercased() == fs || airlineCode.uppercased() == iata || airlineCode.uppercased() == icao {
                                            
                                            airlineName = bookingAirlineName
                                            
                                            if let phoneNumberCheck = obj["phoneNumber"] as? String {
                                                
                                                phoneNumber = phoneNumberCheck
                                                
                                                if airlineName == "American Airlines" {
                                                    
                                                    phoneNumber = "+1 800-433-7300"
                                                }
                                                
                                                if airlineName == "Virgin Australia" {
                                                    
                                                    phoneNumber = "+61 7 3295 2296"
                                                }
                                                
                                                if airlineName == "British Airways" {
                                                    
                                                    phoneNumber = "+1-800-247-9297"
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                        airlineNameArray.append(bookingAirlineName)
                                        
                                    }
                                    
                                    airlineNameArrayString = airlineNameArray.joined(separator: ", ")
                                    
                                }
                                
                                if let errorMessage = ((jsonFlightData)["error"] as? NSDictionary)?["errorMessage"] as? String {
                                    
                                    DispatchQueue.main.async {
                                        
                                        let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: "\(errorMessage)", preferredStyle: UIAlertControllerStyle.alert)
                                        
                                            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                                            
                                            self.airlineCode.text = ""
                                            self.flightNumber.text = ""
                                            
                                            }))
                                        
                                        self.present(alert, animated: true, completion: nil)
                                        
                                    }
                                    
                                } else if let scheduledFlightsArray = jsonFlightData["scheduledFlights"] as? NSArray {
                                    
                                    //if scheduledFlightsArray.count > 3 {
                                    if scheduledFlightsArray.count > 1 {
                                        
                                        var scheduledFlights:[Dictionary<String,String>]! = []
                                        DispatchQueue.main.async{
                                            
                                        for flight in scheduledFlightsArray {
                                            
                                            let arrivalAirport = (flight as! NSDictionary)["arrivalAirportFsCode"] as! String
                                            let departureAirport = (flight as! NSDictionary)["departureAirportFsCode"] as! String
                                            //let carrierFsCode = (flight as! NSDictionary)["carrierFsCode"] as! String
                                            //let departureTime = (flight as! NSDictionary)["departureTime"] as! String
                                            //let arrivalTime = (flight as! NSDictionary)["arrivalTime"] as! String
                                            
                                            airlineCode = (flight as! NSDictionary)["carrierFsCode"] as! String!
                                            flightNumber = (flight as! NSDictionary)["flightNumber"] as! String!
                                            //airplaneIataCode = (flight as! NSDictionary)["flightEquipmentIataCode"] as! String!
                                            
                                            departureDate = (flight as! NSDictionary)["departureTime"] as! String!
                                            convertedDepartureDate = self.convertDateTime(date: departureDate)
                                            departureDateUtc = self.getUtcTime(time: departureDate, utcOffset: String(departureUtcOffset))
                                            departureDateNumber = self.formatDateTimetoWhole(dateTime: departureDate)
                                            departureDateUtcNumber = self.formatDateTimetoWhole(dateTime: departureDateUtc)
                                            urlDepartureDate = self.convertToURLDate(date: departureDate)
                                            
                                            arrivalDate = (flight as! NSDictionary)["arrivalTime"] as! String!
                                            convertedArrivalDate = self.convertDateTime(date: arrivalDate)
                                            arrivalDateUtc = self.getUtcTime(time: arrivalDate, utcOffset: String(arrivalUtcOffset))
                                            arrivalDateNumber = self.formatDateTimetoWhole(dateTime: arrivalDate)
                                            urlArrivalDate = self.convertToURLDate(date: arrivalDate)
                                            arrivalDateUtcNumber = self.formatDateTimetoWhole(dateTime: arrivalDateUtc)
                                            
                                            if let departureTerminalCheck = (flight as! NSDictionary)["departureTerminal"] as? String {
                                                
                                                departureTerminal = departureTerminalCheck
                                                
                                            }
                                            
                                            if let arrivalTerminalCheck = (flight as! NSDictionary)["arrivalTerminal"] as? String {
                                                
                                                arrivalTerminal = arrivalTerminalCheck
                                                
                                            }
                                            
                                            if let departureGateCheck = (flight as! NSDictionary)["departureGate"] as? String {
                                                
                                                departureGate = departureGateCheck
                                                
                                            }
                                            
                                            if let arrivalGateCheck = (flight as! NSDictionary)["arrivalGate"] as? String {
                                                
                                                arrivalGate = arrivalGateCheck
                                                
                                            }
                                            
                                            let airportArray = ((jsonFlightData)["appendix"] as? NSDictionary)?["airports"] as? NSArray
                                            
                                            for (_, departureAirportDic) in (airportArray?.enumerated())! {
                                                
                                                let airportCode = (departureAirportDic as! NSDictionary)["fs"] as! String
                                                
                                                if airportCode == departureAirport {
                                                    
                                                    for (_, airport) in (airportArray?.enumerated())! {
                                                        
                                                        //let arrivalAirportCode = (airport as! NSDictionary)["fs"] as! String
                                                        
                                                        if (airport as! NSDictionary)["fs"] as! String == arrivalAirport {
                                                            
                                                            arrivalAirportCode = (airport as! NSDictionary)["fs"] as! String
                                                            arrivalCountry = (airport as! NSDictionary)["countryName"] as! String!
                                                            arrivalLongitude = (airport as! NSDictionary)["longitude"] as! Double!
                                                            //arrivalAirportIata = (airport as! NSDictionary)["iata"] as! String!
                                                            arrivalLatitude = (airport as! NSDictionary)["latitude"] as! Double!
                                                            arrivalCity = (airport as! NSDictionary)["city"] as! String!
                                                            arrivalUtcOffset = (airport as! NSDictionary)["utcOffsetHours"] as! Double!
                                                            
                                                            departureAirportCode = (departureAirportDic as! NSDictionary)["fs"] as! String
                                                            departureCountry = (departureAirportDic as! NSDictionary)["countryName"] as! String!
                                                            departureLongitude = (departureAirportDic as! NSDictionary)["longitude"] as! Double!
                                                            //departureAirportIata = (departureAirportDic as! NSDictionary)["iata"] as! String!
                                                            departureLatitude = (departureAirportDic as! NSDictionary)["latitude"] as! Double!
                                                            departureCity = (departureAirportDic as! NSDictionary)["city"] as! String!
                                                            departureUtcOffset = (departureAirportDic as! NSDictionary)["utcOffsetHours"] as! Double!
                                                            
                                                            
                                                                
                                                                leg1 = [
                                                                    
                                                                    "Leg 0":"false",
                                                                    "Reference Number":"\(self.refNumber!)",
                                                                    
                                                                    //Info that applies to both origin and destination
                                                                    "Airline Code":"\(airlineCode!)",
                                                                    "Flight Number":"\(flightNumber!)",
                                                                    "Airline Name":"\(airlineName!)",
                                                                    "Partner Airlines":"\(airlineNameArrayString!)",
                                                                    "Aircraft Type Name":"\(aircraft!)",
                                                                    "Phone Number":"\(phoneNumber!)",
                                                                    
                                                                    //Departure airport info
                                                                    "Departure Airport Code":"\(departureAirportCode!)",
                                                                    "Departure Country":"\(departureCountry!)",
                                                                    "Departure City":"\(departureCity!)",
                                                                    "Airport Departure Terminal":"\(departureTerminal!)",
                                                                    "Departure Gate":"\(departureGate!)",
                                                                    "Departure Airport UTC Offset":"\(departureUtcOffset!)",
                                                                    "Airport Departure Longitude":"\(departureLongitude!)",
                                                                    "Airport Departure Latitude":"\(departureLatitude!)",
                                                                    
                                                                    //Departure times
                                                                    "Published Departure":"\(departureDate!)",
                                                                    "Departure Date Number":"\(departureDateNumber!)",
                                                                    "Published Departure UTC":"\(departureDateUtc!)",
                                                                    "Published Departure UTC Number":"\(departureDateUtcNumber!)",
                                                                    "URL Departure Date":"\(urlDepartureDate!)",
                                                                    "Converted Published Departure":"\(convertedDepartureDate!)",
                                                                    
                                                                    //Arrival Airport Info
                                                                    "Arrival Airport Code":"\(arrivalAirportCode!)",
                                                                    "Airport Arrival Longitude":"\(arrivalLongitude!)",
                                                                    "Airport Arrival Latitude":"\(arrivalLatitude!)",
                                                                    "Arrival Country":"\(arrivalCountry!)",
                                                                    "Arrival City":"\(arrivalCity!)",
                                                                    "Airport Arrival Terminal":"\(arrivalTerminal!)",
                                                                    "Arrival Gate":"\(arrivalGate!)",
                                                                    "Arrival Airport UTC Offset":"\(arrivalUtcOffset!)",
                                                                    
                                                                    //Given in schedules json
                                                                    "Converted Published Arrival":"\(convertedArrivalDate!)",
                                                                    "Published Arrival":"\(arrivalDate!)",
                                                                    "Arrival Date Number":"\(arrivalDateNumber!)",
                                                                    "Published Arrival UTC":"\(arrivalDateUtc!)",
                                                                    "Published Arrival UTC Number":"\(arrivalDateUtcNumber!)",
                                                                    "URL Arrival Date":"\(urlArrivalDate!)",
                                                                    
                                                                    //given in statuses json
                                                                    "Flight Status":"",
                                                                    "Flight Duration Scheduled":"",
                                                                    "Baggage Claim":"-",
                                                                    "Primary Carrier":"",
                                                                    "Updated Flight Equipment":"",
                                                                    "Converted Scheduled Gate Departure":"",
                                                                    "Converted Estimated Gate Departure":"",
                                                                    "Converted Actual Runway Departure":"",
                                                                    "Converted Actual Gate Departure":"",
                                                                    "Converted Scheduled Gate Arrival":"",
                                                                    "Converted Estimated Runway Arrival":"",
                                                                    "Converted Estimated Gate Arrival":"",
                                                                    "Converted Actual Runway Arrival":"",
                                                                    "Converted Actual Gate Arrival":"",
                                                                    "Scheduled Gate Departure Whole Number":"",
                                                                    "Estimated Gate Departure Whole Number":"",
                                                                    "Scheduled Runway Departure Whole Number":"",
                                                                    "Estimated Runway Departure Whole Number":"",
                                                                    "Actual Gate Departure Whole":"",
                                                                    "Actual Runway Departure Whole Number":"",
                                                                    "Scheduled Gate Arrival Whole Number":"",
                                                                    "Actual Gate Arrival Whole":"",
                                                                    "Actual Runway Arrival Whole Number":"",
                                                                    "Scheduled Gate Arrival":"",
                                                                    "Estimated Runway Arrival":"",
                                                                    "Estimated Gate Arrival":"",
                                                                    "Scheduled Gate Departure":"",
                                                                    "Estimated Gate Departure":"",
                                                                    "Actual Runway Departure":"",
                                                                    "Actual Gate Departure":"",
                                                                    "Actual Runway Arrival":"",
                                                                    "Actual Gate Arrival":"",
                                                                    "Scheduled Runway Arrival Whole Number":"",
                                                                    "Estimated Gate Arrival Whole Number":"",//new after here
                                                                    "Scheduled Gate Departure UTC":"",
                                                                    "Estimated Gate Departure UTC":"",
                                                                    
                                                                    //add notifications
                                                                    "48 Hour Notification":"\(UserDefaults.standard.bool(forKey: "twoDays"))",
                                                                    "4 Hour Notification":"\(UserDefaults.standard.bool(forKey: "fourHours"))",
                                                                    "2 Hour Notification":"\(UserDefaults.standard.bool(forKey: "twoHours"))",
                                                                    "1 Hour Notification":"\(UserDefaults.standard.bool(forKey: "oneHour"))",
                                                                    "Taking Off Notification":"\(UserDefaults.standard.bool(forKey: "takeOff"))",
                                                                    "Landing Notification":"\(UserDefaults.standard.bool(forKey: "landing"))"

                                                                    
                                                                ]
                                                            
                                                            scheduledFlights.append(leg1)
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                               }
                                                
                                            }
                                            
                                        }
                                            
                                            DispatchQueue.main.async {
                                                
                                                self.activityIndicator.stopAnimating()
                                                self.activityLabel.removeFromSuperview()
                                                self.blurEffectViewActivity.removeFromSuperview()
                                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                                
                                            }
                                            
                                            let alert = UIAlertController(title: NSLocalizedString("Choose your route", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.alert)
                                            
                                            for (index, leg) in scheduledFlights.enumerated() {
                                                
                                                alert.addAction(UIAlertAction(title: "\(leg["Departure City"]!) \(NSLocalizedString("to", comment: "")) \(leg["Arrival City"]!)", style: .default, handler: { (action) in
                                                    
                                                    self.flights.append(scheduledFlights[index])
                                                    
                                                    // for tripkeylite
                                                    self.flightCount.append(1)
                                                    UserDefaults.standard.set(self.flightCount, forKey: "flightCount")
                                                    
                                                    self.sortFlightsbyDepartureDate()
                                                    
                                                    let departureDate = scheduledFlights[index]["Published Departure"]!
                                                    let utcOffset = scheduledFlights[index]["Departure Airport UTC Offset"]!
                                                    let departureCity = scheduledFlights[index]["Departure City"]!
                                                    let arrivalCity = scheduledFlights[index]["Arrival City"]!
                                                    
                                                    let departingTerminal = "\(scheduledFlights[index]["Airport Departure Terminal"]!)"
                                                    let departingGate = "\(scheduledFlights[index]["Departure Gate"]!)"
                                                    let departingAirport = "\(scheduledFlights[index]["Departure Airport Code"]!)"
                                                    let arrivalAirport = "\(scheduledFlights[index]["Arrival Airport Code"]!)"
                                                    
                                                    let arrivalDate = "\(scheduledFlights[index]["Published Arrival"]!)"
                                                    let arrivalOffset = "\(scheduledFlights[index]["Arrival Airport UTC Offset"]!)"
                                                    
                                                    let delegate = UIApplication.shared.delegate as? AppDelegate
                                                    
                                                    if scheduledFlights[index]["4 Hour Notification"] == "true" {
                                                        
                                                        delegate?.schedule4HrNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                    }
                                                    
                                                    if scheduledFlights[index]["1 Hour Notification"] == "true" {
                                                        
                                                        delegate?.schedule1HourNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                    }
                                                    
                                                    if scheduledFlights[index]["2 Hour Notification"] == "true" {
                                                        
                                                        delegate?.schedule2HrNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                    }
                                                    
                                                    if scheduledFlights[index]["48 Hour Notification"] == "true" {
                                                        
                                                        delegate?.schedule48HrNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                    }
                                                    
                                                    if scheduledFlights[index]["Taking Off Notification"] == "true" {
                                                    
                                                    delegate?.scheduleTakeOffNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                        
                                                    }
                                                    
                                                    if scheduledFlights[index]["Landing Notification"] == "true" {
                                                    
                                                    delegate?.scheduleLandingNotification(estimatedArrival: "", arrivalDate: arrivalDate, arrivalOffset: arrivalOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                        
                                                    }
                                                    
                                                    self.airlineCode.text = ""
                                                    self.flightNumber.text = ""
                                                    //self.referenceNumber.text = ""
                                                    self.sortFlightsbyDepartureDate()
                                                    UserDefaults.standard.set(self.flights, forKey: "flights")
                                                    
                                                    let alert = UIAlertController(title: NSLocalizedString("Flight Added :)", comment: ""), message: nil, preferredStyle: UIAlertControllerStyle.alert)
                                                    
                                                    alert.addAction(UIAlertAction(title: NSLocalizedString("Finished Adding Flights", comment: ""), style: .default, handler: { (action) in
                                                        
                                                        self.performSegue(withIdentifier: "goToNearMe", sender: self)
                                                        
                                                        
                                                        
                                                    }))
                                                    
                                                    alert.addAction(UIAlertAction(title: NSLocalizedString("Add Another Flight", comment: ""), style: .default, handler: { (action) in
                                                        
                                                    //self.setNotifications()
                                                    
                                                    }))
                                                    
                                                    self.present(alert, animated: true, completion: nil)
                                                    
                                                    
                                                }))
                                                
                                                
                                                
                                            }
                                            
                                            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                                                
                                            }))
                                        
                                        self.present(alert, animated: true, completion: nil)
                                            
                                        }
                                     
                                    } else if scheduledFlightsArray.count == 1 {
                                        
                                        if let airportDic1Check = (((jsonFlightData)["appendix"] as? NSDictionary)?["airports"] as? NSArray)?[0] as? NSDictionary {
                                            
                                            airport1 = airportDic1Check
                                            airport1FsCode = airport1["fs"] as! String
                                            
                                        }
                                        
                                        if let airportDic2Check = (((jsonFlightData)["appendix"] as? NSDictionary)?["airports"] as? NSArray)?[1] as? NSDictionary {
                                            
                                            airport2 = airportDic2Check
                                            airport2FsCode = airport2["fs"] as! String
                                            
                                        }
                                        
                                        if let leg0Check = (((jsonFlightData)["scheduledFlights"]) as? NSArray)?[0] as? NSDictionary {
                                            
                                            departureAirportCode = leg0Check["departureAirportFsCode"] as! String
                                            arrivalAirportCode = leg0Check["arrivalAirportFsCode"]! as! String
                                            
                                        
                                        
                                            //checks for optional terminal and gate info
                                            if let departureTerminalCheck = leg0Check["departureTerminal"] as? String {
                                                
                                                departureTerminal = departureTerminalCheck
                                            }
                                            
                                            if let arrivalTerminalCheck = leg0Check["arrivalTerminal"] as? String {
                                                
                                                arrivalTerminal = arrivalTerminalCheck
                                            }
                                            
                                            if let departureGateCheck = leg0Check["departureGate"] as? String {
                                                
                                                departureGate = departureGateCheck
                                            }
                                            
                                            if let arrivalGateCheck = leg0Check["arrivalGate"] as? String {
                                                
                                                arrivalGate = arrivalGateCheck
                                            }
                                            
                                            
                                            //assigns correct airports to flight
                                            if departureAirportCode == airport1FsCode {
                                                
                                                departureAirport = airport1
                                                
                                            } else if departureAirportCode == airport2FsCode {
                                                
                                                departureAirport = airport2
                                                
                                            }
                                            
                                            if arrivalAirportCode == airport1FsCode {
                                                
                                                arrivalAirport = airport1
                                                
                                            } else if arrivalAirportCode == airport2FsCode {
                                                
                                                arrivalAirport = airport2
                                                
                                            }
                                            
                                            //assigns correct airport variables to departure
                                            departureCountry = departureAirport["countryName"] as! String!
                                            departureLongitude = departureAirport["longitude"] as! Double!
                                            //departureAirportIata = departureAirport["iata"] as! String!
                                            departureLatitude = departureAirport["latitude"] as! Double!
                                            departureCity = departureAirport["city"] as! String!
                                            departureUtcOffset = departureAirport["utcOffsetHours"] as! Double!
                                            
                                            //assigns correct airport variables to arrival
                                            arrivalCountry = arrivalAirport["countryName"] as! String!
                                            arrivalLongitude = arrivalAirport["longitude"] as! Double!
                                            //arrivalAirportIata = arrivalAirport["iata"] as! String!
                                            arrivalLatitude = arrivalAirport["latitude"] as! Double!
                                            arrivalCity = arrivalAirport["city"] as! String!
                                            arrivalUtcOffset = arrivalAirport["utcOffsetHours"] as! Double!
                                            
                                            
                                            airlineCode = leg0Check["carrierFsCode"] as! String!
                                            flightNumber = leg0Check["flightNumber"] as! String!
                                            //airplaneIataCode = leg0Check["flightEquipmentIataCode"] as! String!
                                            
                                            departureDate = leg0Check["departureTime"] as! String!
                                            convertedDepartureDate = self.convertDateTime(date: departureDate)
                                            departureDateUtc = self.getUtcTime(time: departureDate, utcOffset: String(departureUtcOffset))
                                            departureDateNumber = self.formatDateTimetoWhole(dateTime: departureDate)
                                            departureDateUtcNumber = self.formatDateTimetoWhole(dateTime: departureDateUtc)
                                            urlDepartureDate = self.convertToURLDate(date: departureDate)
                                            
                                            arrivalDate = leg0Check["arrivalTime"] as! String!
                                            convertedArrivalDate = self.convertDateTime(date: arrivalDate)
                                            arrivalDateUtc = self.getUtcTime(time: arrivalDate, utcOffset: String(arrivalUtcOffset))
                                            arrivalDateNumber = self.formatDateTimetoWhole(dateTime: arrivalDate)
                                            urlArrivalDate = self.convertToURLDate(date: arrivalDate)
                                            arrivalDateUtcNumber = self.formatDateTimetoWhole(dateTime: arrivalDateUtc)
                                            
                                            leg1 = [
                                                
                                                "Leg 0":"false",
                                                "Reference Number":"\(self.refNumber!)",
                                                
                                                //Info that applies to both origin and destination
                                                "Airline Code":"\(airlineCode!)",
                                                "Flight Number":"\(flightNumber!)",
                                                "Airline Name":"\(airlineName!)",
                                                "Partner Airlines":"\(airlineNameArrayString!)",
                                                "Aircraft Type Name":"\(aircraft!)",
                                                "Phone Number":"\(phoneNumber!)",
                                                
                                                //Departure airport info
                                                "Departure Airport Code":"\(departureAirportCode!)",
                                                "Departure Country":"\(departureCountry!)",
                                                "Departure City":"\(departureCity!)",
                                                "Airport Departure Terminal":"\(departureTerminal!)",
                                                "Departure Gate":"\(departureGate!)",
                                                "Departure Airport UTC Offset":"\(departureUtcOffset!)",
                                                "Airport Departure Longitude":"\(departureLongitude!)",
                                                "Airport Departure Latitude":"\(departureLatitude!)",
                                                
                                                //Departure times
                                                "Published Departure":"\(departureDate!)",
                                                "Departure Date Number":"\(departureDateNumber!)",
                                                "Published Departure UTC":"\(departureDateUtc!)",
                                                "Published Departure UTC Number":"\(departureDateUtcNumber!)",
                                                "URL Departure Date":"\(urlDepartureDate!)",
                                                "Converted Published Departure":"\(convertedDepartureDate!)",
                                                
                                                //Arrival Airport Info
                                                "Arrival Airport Code":"\(arrivalAirportCode!)",
                                                "Airport Arrival Longitude":"\(arrivalLongitude!)",
                                                "Airport Arrival Latitude":"\(arrivalLatitude!)",
                                                "Arrival Country":"\(arrivalCountry!)",
                                                "Arrival City":"\(arrivalCity!)",
                                                "Airport Arrival Terminal":"\(arrivalTerminal!)",
                                                "Arrival Gate":"\(arrivalGate!)",
                                                "Arrival Airport UTC Offset":"\(arrivalUtcOffset!)",
                                                
                                                //Given in schedules json
                                                "Converted Published Arrival":"\(convertedArrivalDate!)",
                                                "Published Arrival":"\(arrivalDate!)",
                                                "Arrival Date Number":"\(arrivalDateNumber!)",
                                                "Published Arrival UTC":"\(arrivalDateUtc!)",
                                                "Published Arrival UTC Number":"\(arrivalDateUtcNumber!)",
                                                "URL Arrival Date":"\(urlArrivalDate!)",
                                                
                                                //given in statuses json
                                                "Flight Status":"",
                                                "Flight Duration Scheduled":"",
                                                "Baggage Claim":"-",
                                                "Primary Carrier":"",
                                                "Updated Flight Equipment":"",
                                                "Converted Scheduled Gate Departure":"",
                                                "Converted Estimated Gate Departure":"",
                                                "Converted Actual Runway Departure":"",
                                                "Converted Actual Gate Departure":"",
                                                "Converted Scheduled Gate Arrival":"",
                                                "Converted Estimated Runway Arrival":"",
                                                "Converted Estimated Gate Arrival":"",
                                                "Converted Actual Runway Arrival":"",
                                                "Converted Actual Gate Arrival":"",
                                                "Scheduled Gate Departure Whole Number":"",
                                                "Estimated Gate Departure Whole Number":"",
                                                "Scheduled Runway Departure Whole Number":"",
                                                "Estimated Runway Departure Whole Number":"",
                                                "Actual Gate Departure Whole":"",
                                                "Actual Runway Departure Whole Number":"",
                                                "Scheduled Gate Arrival Whole Number":"",
                                                "Actual Gate Arrival Whole":"",
                                                "Actual Runway Arrival Whole Number":"",
                                                "Scheduled Gate Arrival":"",
                                                "Estimated Runway Arrival":"",
                                                "Estimated Gate Arrival":"",
                                                "Scheduled Gate Departure":"",
                                                "Estimated Gate Departure":"",
                                                "Actual Runway Departure":"",
                                                "Actual Gate Departure":"",
                                                "Actual Runway Arrival":"",
                                                "Actual Gate Arrival":"",
                                                "Scheduled Runway Arrival Whole Number":"",
                                                "Estimated Gate Arrival Whole Number":"",
                                                "Scheduled Gate Departure UTC":"",
                                                "Estimated Gate Departure UTC":"",
                                                
                                                //add notifications
                                                "48 Hour Notification":"\(UserDefaults.standard.bool(forKey: "twoDays"))",
                                                "4 Hour Notification":"\(UserDefaults.standard.bool(forKey: "fourHours"))",
                                                "2 Hour Notification":"\(UserDefaults.standard.bool(forKey: "twoHours"))",
                                                "1 Hour Notification":"\(UserDefaults.standard.bool(forKey: "oneHour"))",
                                                "Taking Off Notification":"\(UserDefaults.standard.bool(forKey: "takeOff"))",
                                                "Landing Notification":"\(UserDefaults.standard.bool(forKey: "landing"))"
                                                
                                            ]
                                            
                                            DispatchQueue.main.async {
                                                
                                                
                                                self.activityIndicator.stopAnimating()
                                                self.activityLabel.removeFromSuperview()
                                                self.blurEffectViewActivity.removeFromSuperview()
                                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                                    
                                                
                                                let leg1DepCity = leg1["Departure City"]!
                                                let leg1ArrCity = leg1["Arrival City"]!
                                                
                                                let flightNumber = "\(leg1["Airline Code"]!)" + "\(leg1["Flight Number"]!)"
                                                
                                                let alert = UIAlertController(title: NSLocalizedString("Non-stop flight", comment: ""), message: "\(NSLocalizedString("Flight", comment: "")) \(flightNumber) \(NSLocalizedString("with", comment: "")) \(airlineName!) \(NSLocalizedString("departs", comment: "")) \(leg1DepCity) \(NSLocalizedString("on", comment: "")) \(convertedDepartureDate!) \(NSLocalizedString("and arrives in", comment: "")) \(leg1ArrCity) \(NSLocalizedString("on", comment: "")) \(convertedArrivalDate!)\n\(NSLocalizedString("Please tap to add.", comment: ""))", preferredStyle: UIAlertControllerStyle.actionSheet)
                                                
                                                alert.addAction(UIAlertAction(title: "\(leg1DepCity) \(NSLocalizedString("to", comment: "")) \(leg1ArrCity)", style: .default, handler: { (action) in
                                                    
                                                    self.flights.append(leg1 as Dictionary<String, String>)
                                                    
                                                    // for tripkeylite
                                                    self.flightCount.append(1)
                                                    UserDefaults.standard.set(self.flightCount, forKey: "flightCount")
                                                    
                                                    self.sortFlightsbyDepartureDate()
                                                    
                                                    let departureDate = leg1["Published Departure"]!
                                                    let utcOffset = leg1["Departure Airport UTC Offset"]!
                                                    let departureCity = leg1["Departure City"]!
                                                    let arrivalCity = leg1["Arrival City"]!
                                                    let departingTerminal = "\(leg1["Airport Departure Terminal"]!)"
                                                    let departingGate = "\(leg1["Departure Gate"]!)"
                                                    let departingAirport = "\(leg1["Departure Airport Code"]!)"
                                                    let arrivalAirport = "\(leg1["Arrival Airport Code"]!)"
                                                    
                                                    let arrivalDate = leg1["Published Arrival"]!
                                                    let arrivalOffset = leg1["Arrival Airport UTC Offset"]!
                                                    
                                                    let delegate = UIApplication.shared.delegate as? AppDelegate
                                                    
                                                    print("4 Hour Notification = \(String(describing: leg1["4 Hour Notification"]))")
                                                    
                                                    
                                                    if leg1["4 Hour Notification"] == "true" {
                                                        
                                                        delegate?.schedule4HrNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                    }
                                                    
                                                    print("1 Hour Notification = \(String(describing: leg1["1 Hour Notification"]))")
                                                    
                                                    if leg1["1 Hour Notification"] == "true" {
                                                        
                                                        delegate?.schedule1HourNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                    }
                                                    
                                                    print("2 Hour Notification = \(String(describing: leg1["2 Hour Notification"]))")
                                                    
                                                    if leg1["2 Hour Notification"] == "true" {
                                                        
                                                        delegate?.schedule2HrNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                    }
                                                    
                                                    print("48 Hour Notification = \(String(describing: leg1["48 Hour Notification"]))")
                                                    
                                                    if leg1["48 Hour Notification"] == "true" {
                                                        
                                                        delegate?.schedule48HrNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                    }
                                                    
                                                    print("Taking Off Notification = \(String(describing: leg1["Taking Off Notification"]))")
                                                    
                                                    if leg1["Taking Off Notification"] == "true" {
                                                        
                                                        delegate?.scheduleTakeOffNotification(estimatedDeparture: "", departureDate: departureDate, departureOffset: utcOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                        
                                                    }
                                                    
                                                    print("Landing Notification = \(String(describing: leg1["Landing Notification"]))")
                                                    
                                                    if leg1["Landing Notification"] == "true" {
                                                        
                                                        delegate?.scheduleLandingNotification(estimatedArrival: "", arrivalDate: arrivalDate, arrivalOffset: arrivalOffset, departureCity: departureCity, arrivalCity: arrivalCity, flightNumber: flightNumber, departingTerminal: departingTerminal, departingGate: departingGate, departingAirport: departingAirport, arrivingAirport: arrivalAirport)
                                                        
                                                        
                                                    }

                                                    
                                                    
                                                    self.airlineCode.text = ""
                                                    self.flightNumber.text = ""
                                                    //self.referenceNumber.text = ""
                                                    self.sortFlightsbyDepartureDate()
                                                    UserDefaults.standard.set(self.flights, forKey: "flights")
                                                    
                                                    let alert = UIAlertController(title: NSLocalizedString("Flight Added :)", comment: ""), message: nil, preferredStyle: UIAlertControllerStyle.alert)
                                                    
                                                    alert.addAction(UIAlertAction(title: NSLocalizedString("Finished Adding Flights", comment: ""), style: .default, handler: { (action) in
                                                        
                                                        self.performSegue(withIdentifier: "goToNearMe", sender: self)
                                                        
                                                        
                                                        
                                                    }))
                                                    
                                                    alert.addAction(UIAlertAction(title: NSLocalizedString("Add Another Flight", comment: ""), style: .default, handler: { (action) in
                                                        
                                                        //self.setNotifications()
                                                        
                                                    }))
                                                    
                                                    self.present(alert, animated: true, completion: nil)
                                                    
                                                }))
                                                
                                                
                                                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                                                    
                                                }))
                                                
                                                self.present(alert, animated: true, completion: nil)
                                                
                                            }
                                            
                                        }
                                       
                                    } else if let numberCheck = (((jsonFlightData)["request"] as? NSDictionary)?["flightNumber"] as? NSDictionary)?["interpreted"] as? String {
                                      
                                        let number = numberCheck
                                        
                                        let departingDay = (((jsonFlightData)["request"] as? NSDictionary)?["date"] as? NSDictionary)?["day"] as? String
                                        let departingMonth = (((jsonFlightData)["request"] as? NSDictionary)?["date"] as? NSDictionary)?["month"] as? String
                                        let departingYear = (((jsonFlightData)["request"] as? NSDictionary)?["date"] as? NSDictionary)?["year"] as? String
                                    
                                        self.formattedDepartureDate = "\(departingDay!)/\(departingMonth!)/\(departingYear!)"
                                        self.formattedFlightNumber = "\(self.airlineCode.text!)" + "\(number)"
                                         
                                        DispatchQueue.main.async {
                                            
                                            
                                            self.activityIndicator.stopAnimating()
                                            self.activityLabel.removeFromSuperview()
                                            self.blurEffectViewActivity.removeFromSuperview()
                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                                

                                                let alert = UIAlertController(title: "\(NSLocalizedString("There are no scheduled flights for flight number", comment: "")) \(self.formattedFlightNumber!), \(NSLocalizedString("departing on", comment: "")) \(self.formattedDepartureDate!)", message: "\n\(NSLocalizedString("Please make sure you input the correct flight number and departure date.", comment: ""))", preferredStyle: UIAlertControllerStyle.alert)
                                            
                                                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                                                    
                                                    self.airlineCode.text = ""
                                                    self.flightNumber.text = ""
                                                    //self.referenceNumber.text = ""
                                                
                                                }))
                                            
                                            self.present(alert, animated: true, completion: nil)
                                        }

                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } catch {
                        
                    
                    print("Error parsing")
                    
                    DispatchQueue.main.async {
                        
                        self.activityIndicator.stopAnimating()
                        self.activityLabel.removeFromSuperview()
                        self.blurEffectViewActivity.removeFromSuperview()
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            
                        
                        let alert = UIAlertController(title: NSLocalizedString(NSLocalizedString("There was an unknown error!", comment: ""), comment: ""), message: NSLocalizedString("Please contact customer support at TripKeyApp@gmail.com", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                        
                        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                            
                        }))
                        
                        self.present(alert, animated: true, completion: nil)
                        
                    }

                    
                }
                
            }
            
            task.resume()
            
        }
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 3
        
    }
    
    /*
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "Cell")
        cell.textLabel!.text = "foo"
        return cell
        
    }
    
    */
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.view.endEditing(true)
        return false
    }
 
    
    func sortLegsByDepartureDate() {
        
        sortedLegs = legs.sorted {
            
            (dictOne, dictTwo) -> Bool in
            
            let d1 = Double(dictOne["Published Departure UTC Number"]!)
            let d2 = Double(dictTwo["Published Departure UTC Number"]!)
            
            
            return d1! < d2!
            
        }
        
        legs = sortedLegs
    }
    
    func sortFlightsbyDepartureDate() {
        
        sortedFlights = flights.sorted {
            
            (dictOne, dictTwo) -> Bool in
            
            let d1 = Double(dictOne["Published Departure UTC Number"]!)
            let d2 = Double(dictTwo["Published Departure UTC Number"]!)
            

            return d1! < d2!
            
        };
        flights = sortedFlights
        //self.flightNumbersTableView.reloadData()
    }
    
    func formatDateTimetoWhole(dateTime: String) -> String {
        
        let dateTimeAsNumberStep1 = dateTime.replacingOccurrences(of: "-", with: "")
        let dateTimeAsNumberStep2 = dateTimeAsNumberStep1.replacingOccurrences(of: "T", with: "")
        let dateTimeAsNumberStep3 = dateTimeAsNumberStep2.replacingOccurrences(of: ":", with: "")
        let dateTimeWhole = dateTimeAsNumberStep3.replacingOccurrences(of: ".", with: "")
        return dateTimeWhole
    }
    
    
    func formatDate(date: String) -> String {
        
        var dateTimeArray = date.components(separatedBy: "T")
        let dateOnly = dateTimeArray[0]
        var dateArray = dateOnly.components(separatedBy: "-")
        let formattedDate = "\(dateArray[2])/" + "\(dateArray[1])/" + "\(dateArray[0])"
        return formattedDate
    }
    
    func formatTime(time: String) -> String {
        
        var dateTimeArray = time.components(separatedBy: "T")
        let timeOnly = dateTimeArray[1]
        var splitTime = timeOnly.components(separatedBy: ":")
        let formattedTime = "\(splitTime[0]):" + "\(splitTime[1])"
        return formattedTime
    }
    
    func convertDateTime (date: String) -> (String) {
        
        
        var dateArray = date.components(separatedBy: "T")
        let dateSegment = dateArray[0]
        let timeSegment = dateArray[1]
        var timeArray = timeSegment.components(separatedBy: ":00.000")
        let time1 = timeArray[0]
        var hoursAndMinutes = time1.components(separatedBy: ":")
        let hour = hoursAndMinutes[0]
        let minutes = hoursAndMinutes[1]
        
        var dateSplitArray = dateSegment.components(separatedBy: "-")
        let year = dateSplitArray[0]
        let month = dateSplitArray[1]
        let day1 = dateSplitArray[2]
        
        let dateComponents = NSDateComponents()
        dateComponents.day = Int(day1)!
        dateComponents.month = Int(month)!
        dateComponents.year = Int(year)!
        dateComponents.hour = Int(hour)!
        dateComponents.minute = Int(minutes)!
        
        let dateToBeFormatted = NSCalendar.current.date(from: dateComponents as DateComponents)
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy, HH:mm"
        
        let dateString = formatter.string(from: dateToBeFormatted!)
        
        return dateString
        
    }
    
    func convertToURLDate (date: String) -> (String) {
        
        var dateArray = date.components(separatedBy: "T")
        let dateSegment = dateArray[0]
        
        var dateSplitArray = dateSegment.components(separatedBy: "-")
        let year = dateSplitArray[0]
        let month = dateSplitArray[1]
        let day = dateSplitArray[2]
        
        let urlDepartureDate = "\(year)/" + "\(month)/" + "\(day)"
        
        return urlDepartureDate
        
    }
    
    func convertCurrentDateToWhole (date: NSDate) -> (String) {
        
        let currentDate = NSDate()
        let dateString = String(describing: currentDate)
        let date1 = dateString.replacingOccurrences(of: "-", with: "")
        let date2 = date1.replacingOccurrences(of: ":", with: "")
        let date3 = date2.replacingOccurrences(of: "+", with: "")
        let date4 = date3.replacingOccurrences(of: "-", with: "")
        let date5 = date4.replacingOccurrences(of: " ", with: "")
        
        return date5
        
    }
    
    func checkLeg2Date(downlinesArrivalDate: String, downlinesDepartureDate: String, destinationArrivalDate: String) ->(String, String) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        let downlinesArrivalDateFormatted = dateFormatter.date(from: downlinesArrivalDate)
        let downlinesDepartureDateFormatted = dateFormatter.date(from: downlinesDepartureDate)
        let destinationArrivalDateFormatted = dateFormatter.date(from: destinationArrivalDate)
        
        //Turns downlines arrival date into an actual date using date components
        var downlinesArrivalDateArray = downlinesArrivalDate.components(separatedBy: "T")
        let downlinesArrivalDateSegment = downlinesArrivalDateArray[0]
        var downlinesArrivalDateSplitArray = downlinesArrivalDateSegment.components(separatedBy: "-")
        let downlinesArrivalYear = Int(downlinesArrivalDateSplitArray[0])
        let downlinesArrivalMonth = Int(downlinesArrivalDateSplitArray[1])
        let downlinesArrivalDay = Int(downlinesArrivalDateSplitArray[2])
        
        let downlinesArrivalTimeSegment = downlinesArrivalDateArray[1]
        var downlinesArrivalTimeArray = downlinesArrivalTimeSegment.components(separatedBy: ":00.000")
        let downlinesArrivalTime1 = downlinesArrivalTimeArray[0]
        var downlinesArrivalHoursAndMinutes = downlinesArrivalTime1.components(separatedBy: ":")
        let downlinesArrivalHour = Int(downlinesArrivalHoursAndMinutes[0])
        let downlinesArrivalMinutes = Int(downlinesArrivalHoursAndMinutes[1])
        
        let downlinesArrivalDateComponents = NSDateComponents()
        downlinesArrivalDateComponents.day = downlinesArrivalDay!
        downlinesArrivalDateComponents.month = downlinesArrivalMonth!
        downlinesArrivalDateComponents.year = downlinesArrivalYear!
        downlinesArrivalDateComponents.hour = downlinesArrivalHour!
        downlinesArrivalDateComponents.minute = downlinesArrivalMinutes!
        
        //Turns downlines departure date into an actual date using date components
        var downlinesDepartureDateArray = downlinesDepartureDate.components(separatedBy: "T")
        let downlinesDepartureDateSegment = downlinesDepartureDateArray[0]
        var downlinesDepartureDateSplitArray = downlinesDepartureDateSegment.components(separatedBy: "-")
        let downlinesDepartureYear = Int(downlinesDepartureDateSplitArray[0])
        let downlinesDepartureMonth = Int(downlinesDepartureDateSplitArray[1])
        let downlinesDepartureDay = Int(downlinesDepartureDateSplitArray[2])
        
        let downlinesDepartureTimeSegment = downlinesDepartureDateArray[1]
        var downlinesDepartureTimeArray = downlinesDepartureTimeSegment.components(separatedBy: ":00.000")
        let downlinesDepartureTime1 = downlinesDepartureTimeArray[0]
        var downlinesDepartureHoursAndMinutes = downlinesDepartureTime1.components(separatedBy: ":")
        let downlinesDepartureHour = Int(downlinesDepartureHoursAndMinutes[0])
        let downlinesDepartureMinutes = Int(downlinesDepartureHoursAndMinutes[1])
        
        let downlinesDepartureDateComponents = NSDateComponents()
        downlinesDepartureDateComponents.day = downlinesDepartureDay!
        downlinesDepartureDateComponents.month = downlinesDepartureMonth!
        downlinesDepartureDateComponents.year = downlinesDepartureYear!
        downlinesDepartureDateComponents.hour = downlinesDepartureHour!
        downlinesDepartureDateComponents.minute = downlinesDepartureMinutes!
        
        if downlinesArrivalHour! >= 13 && downlinesDepartureHour! <= 12 {
            
            let correctedDownlineDepartureDate = downlinesDepartureDateFormatted?.addingTimeInterval(86400)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            let correctedDownlineDepartureDateString = dateFormatter.string(from: correctedDownlineDepartureDate!)
            
            let correctedDestinationArrivalDate = destinationArrivalDateFormatted?.addingTimeInterval(86400)
            let correctedDestinationArrivalDateString = dateFormatter.string(from: correctedDestinationArrivalDate!)
            
            return(correctedDownlineDepartureDateString, correctedDestinationArrivalDateString)
            
        } else if downlinesDepartureDateFormatted! < downlinesArrivalDateFormatted! {
            
            let correctedDownlineDepartureDate = downlinesDepartureDateFormatted?.addingTimeInterval(86400)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            let correctedDownlineDepartureDateString = dateFormatter.string(from: correctedDownlineDepartureDate!)
            
            let correctedDestinationArrivalDate = destinationArrivalDateFormatted?.addingTimeInterval(86400)
            let correctedDestinationArrivalDateString = dateFormatter.string(from: correctedDestinationArrivalDate!)
            
            return(correctedDownlineDepartureDateString, correctedDestinationArrivalDateString)
            
        } else {
            
            return(downlinesDepartureDate, destinationArrivalDate)
        }
        
        
    }
    
    func getUtcTime(time: String, utcOffset: String) -> (String) {
        
        //here we change departure date to UTC time
        let departureDateFormatter = DateFormatter()
        departureDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        let departureDateTime = departureDateFormatter.date(from: time)
        
        var utcInterval = (Double(utcOffset)! * 60 * 60)
        
        if utcInterval < 0 {
            
            utcInterval = abs(utcInterval)
            
        } else if utcInterval > 0 {
            
            utcInterval = utcInterval * -1
            
        } else if utcInterval == 0 {
            
            utcInterval = 0
        }
        
        let departureDateUtc = departureDateTime!.addingTimeInterval(utcInterval)
        let utcTime = departureDateFormatter.string(from: departureDateUtc)
        
        return utcTime
    }
    
    func addActivityIndicatorCenter() {
        
        self.activityLabel.frame = CGRect(x: 0, y: 0, width: 150, height: 20)
        self.activityLabel.center = CGPoint(x: self.view.frame.width/2 , y: self.view.frame.height/1.815)
        self.activityLabel.font = UIFont(name: "HelveticaNeue-Light", size: 15.0)
        self.activityLabel.textColor = UIColor.white
        self.activityLabel.textAlignment = .center
        self.activityLabel.alpha = 0
        
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.alpha = 0
        activityIndicator.isUserInteractionEnabled = true
        activityIndicator.startAnimating()
        
        blurEffectViewActivity.frame = CGRect(x: 0, y: 0, width: 150, height: 120)
        blurEffectViewActivity.center = CGPoint(x: self.view.center.x, y: ((self.view.center.y) + 14))
        blurEffectViewActivity.alpha = 0
        blurEffectViewActivity.layer.cornerRadius = 30
        blurEffectViewActivity.clipsToBounds = true
        
        view.addSubview(self.blurEffectViewActivity)
        view.addSubview(self.activityLabel)
        view.addSubview(activityIndicator)
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.blurEffectViewActivity.alpha = 1
            self.activityIndicator.alpha = 1
            self.activityLabel.alpha = 1
            
        }) { (true) in
            
            
        }
        
    }
    
    func didFlightAlreadyTakeoff (departureDate: String, utcOffset: String) -> (Bool) {
        
        // here we set the current date to UTC
        let date = NSDate()
        var secondsFromGMT: Int { return NSTimeZone.local.secondsFromGMT() }
        var utcInterval = secondsFromGMT
        
        if utcInterval < 0 {
            
            utcInterval = abs(utcInterval)
            
        } else if utcInterval > 0 {
            
            utcInterval = utcInterval * -1
            
        } else if utcInterval == 0 {
            
            utcInterval = 0
        }
        
        //here we set arrival date to utc and convert from string to date and compare the dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        let currentDateUtc = date.addingTimeInterval(TimeInterval(utcInterval))
        let departureDateUtc = self.getUtcTime(time: departureDate, utcOffset: utcOffset)
        
        let departureDateUtcDate = dateFormatter.date(from: departureDateUtc)
        
        if departureDateUtcDate! < currentDateUtc as Date {
            
            return true
            
        } else {
            
            return false
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let autoCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) 
        
        //autoCell.attributionText.attributedText = self.attributedTextArray[indexPath.row]
        autoCell.textLabel?.text = autoComplete[indexPath.row]
        
        
        return autoCell
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.autoComplete.count
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedCell:UITableViewCell! = tableView.cellForRow(at: indexPath)!
        
        let selectedCellString = String("\(selectedCell.textLabel!.text!)")
        
        let cellArray = selectedCellString?.components(separatedBy: "- ")
        let airlineCodeString = cellArray?[1]
        
        self.airlineCode.text = airlineCodeString!
        
        self.flightNumber.becomeFirstResponder()
        autoSuggestTable.isHidden = true
        
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == self.flightNumber {
            
           autoSuggestTable.isHidden = true
            
        } else if textField == self.airlineCode {
            
            let substring = (airlineCode.text! as NSString).replacingCharacters(in: range, with: string)
            autoSuggestTable.isHidden = false
            searchAutoCompleteEntriesWithSubstrings(substring: substring)
            
            
        }
        
        return true
        
    }
    
    func searchAutoCompleteEntriesWithSubstrings(substring: String) {
        
        autoComplete.removeAll(keepingCapacity: false)
        
        for key in self.autoCompletePossibilitiesArray {
            
            let myString:NSString! = key as NSString
            let substringRange:NSRange! = myString.range(of: substring)
            
            if (substringRange.location == 0) {
                
                autoComplete.append(key)
                
            }
        }
        
        if autoComplete.count == 0 {
            
            self.autoSuggestTable.isHidden = true
        }
        
        self.autoSuggestTable.reloadData()
    }
    
    func getAirlineCodes() {
        
        self.activityLabel.text = "Loading"
        addActivityIndicatorCenter()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let url = URL(string: "https://api.flightstats.com/flex/airlines/rest/v1/json/active?appId=16d11b16&appKey=821a18ad545a57408964a537526b1e87")!
        
        let airlineTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if error != nil {
                
                print(error as Any)
                
            } else {
                
                if let urlContent = data {
                    
                    do {
                        
                        
                        
                        let airlineJsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
                        //print("airlineJsonResult = \(airlineJsonResult)")
                        
                        var airlineName:String! = ""
                        var airlineIcao:String! = ""
                        var airlineIata:String! = ""
                        //var airlineFs:String! = ""
                        
                        if let airlines = airlineJsonResult["airlines"] as? NSArray {
                            
                            if airlines.count > 1 {
                                
                                for airline in airlines {
                                    
                                    let airlineDictionary:NSDictionary! = airline as! NSDictionary
                                    
                                    airlineName = airlineDictionary["name"] as! String
                                    
                                    if let icaoCheck = airlineDictionary["icao"] as? String {
                                        
                                        airlineIcao = icaoCheck
                                        
                                    }
                                    
                                    if let iataCheck = airlineDictionary["iata"] as? String {
                                        
                                        airlineIata = iataCheck
                                        
                                    }
                                    
                                    /*
                                    if let fsCheck = airlineDictionary["fs"] as? String {
                                        
                                        airlineFs = fsCheck
                                        
                                    }
                                    */
                                    
                                    if airlineIcao != "" {
                                        
                                       self.autoCompletePossibilitiesArray.append("\(airlineName.lowercased()) - \(airlineIcao!)")
                                    }
                                    
                                    if airlineIata != "" {
                                        
                                    self.autoCompletePossibilitiesArray.append("\(airlineName.lowercased()) - \(airlineIata!)")
                                        
                                    }
                                    
                                    
                                }
                                
                                self.autoCompletePossibilitiesArray = self.autoCompletePossibilitiesArray.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
                                
                                UserDefaults.standard.set(self.autoCompletePossibilitiesArray, forKey: "airlines")
                                
                                DispatchQueue.main.async {
                                    
                                    self.activityIndicator.stopAnimating()
                                    self.activityLabel.removeFromSuperview()
                                    self.blurEffectViewActivity.removeFromSuperview()
                                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                    
                                }
                                
                            }
                            
                            
                        }
                        
                     } catch {
                        DispatchQueue.main.async {
                            
                            self.activityIndicator.stopAnimating()
                            self.activityLabel.removeFromSuperview()
                            self.blurEffectViewActivity.removeFromSuperview()
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            
                        }
                        print("JSON Processing Failed")
                        
                    }
                    
                }
                
            }
            
        }
        
        airlineTask.resume()
        
    }
    
    @IBAction func backToAddFlight(segue:UIStoryboardSegue) {
    }
    


}