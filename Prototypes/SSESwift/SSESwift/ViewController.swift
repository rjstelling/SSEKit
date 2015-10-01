//
//  ViewController.swift
//  SSESwift
//
//  Created by Richard Stelling on 01/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

//    static let onMessage: eventSourceMessage = { (message: String) -> Void in
//        print(message)
//    }
//    
//    static let onError: eventSourceError = { (error) -> Void in
//        print(error)
//    }
//    
//    lazy var eventSource : EventSource? = EventSource(message: onMessage, error: onError, host: "localhost", path: "/sse", port: 8080)
    
    var eventSource : EventSource? = EventSource(path: "/sse")
    //var eventSource : EventSource? = EventSource(host: "www.thisismyengine.com", path: "/index.html", port: 80)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //_ = EventSource(uri: "leo.private", port: 15081, onMessage: { (message) -> () in print(message) }, onError: { (error) -> () in print(error) } ).test()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        eventSource?.test()
    }
}

