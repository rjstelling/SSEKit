//
//  ViewController.swift
//  SSEKitExample
//
//  Created by Richard Stelling on 23/02/2016.
//  Copyright © 2016 Richard Stelling All rights reserved.
//

import UIKit
import SSEKit

class ViewController: UIViewController {

    var manager: SSEManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserverForName(nil, object: nil, queue: nil) {
            
            //SSEManager.Notification.Key.Name.rawValue
            
            guard let name = $0.userInfo?[SSEManager.Notification.Key.Name.rawValue], let data = $0.userInfo?[SSEManager.Notification.Key.Data.rawValue] as? NSData else {
                
//                let scanner: NSScanner?
                
//                scanner?.scanUpToString(<#T##string: String##String#>, intoString: <#T##AutoreleasingUnsafeMutablePointer<NSString?>#>)
//                scanString
                return
            }
            
            let dataStr = String(data: data, encoding: 4)!
            
            print("NOTE: \(name) -> \(dataStr)")
        }
        
        
        let config = EventSourceConfiguration(withHost: "192.168.103.36", port: 15081, endpoint: "/notify", timeout: 300, events: ["nowplaying"])
        //let config2 = EventSourceConfiguration(withHost: "localhost", port: 8080, endpoint: "/sse", events: nil)
        //let config4 = EventSourceConfiguration(withHost: "192.168.37.76", port: 8080, endpoint: "/sse", events: ["bad-event"])
        
        //let config2 = EventSourceConfiguration(withHost: "localhost", port: 8080, endpoint: "/sse2")
        //let config3 = EventSourceConfiguration(withHost: "localhost", port: 8081, endpoint: "/sse")

        manager = SSEManager(sources: [])
        manager?.addEventSource(config)
        
        //manager = SSEManager(sources: [config2])
        //manager = SSEManager(sources: [config3])
        
        
        //manager = SSEManager(sources: [config, config2, config3])
        
        //TODO: Closed is getting set twice
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
