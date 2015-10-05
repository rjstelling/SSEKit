//
//  ViewController.swift
//  SSESwift
//
//  Created by Richard Stelling on 01/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController, Locking {
    
    //var eventSource : EventSource? = EventSource(path: "/sse")
    //var eventSource : EventSource? = EventSource(host: "192.168.103.100", path: "/test.php", port: 80)
    // var eventSource : EventSource? = EventSource(host: "www.thisismyengine.com", path: "/index.html", port: 80)
    
    var count = 0
    
    var queueOne = dispatch_queue_create("Q1", nil)
    var queueTwo = dispatch_queue_create("Q2", nil)
    var queueThree = dispatch_queue_create("Q3", nil)
    
    let MAX = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.synchronize {
            dispatch_sync(self.queueOne) {
                
                for var i = 0; i < self.MAX; i++ {
                    self.count++
                    print("Q1: \(self.count)")
                }
            }
            
            dispatch_sync(self.queueTwo) {
                
                for var j = 0; j < self.MAX; j++ {
                    self.count++
                    print("Q2: \(self.count)")
                }
            }
            
            dispatch_sync(self.queueThree) {
                
                for var k = 0; k < self.MAX; k++ {
                    self.count++
                    print("Q3: \(self.count)")
                }
            }
        }
        
        self.synchronize {
            print("TOTAL: \(self.count)")
        }
        
//        with {
//            
//            print("Hello world, im in a lock!");
//            
//        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        //eventSource?.test()
    }
    
    // MARK: Locking
    
//    var name : String {
//        
//        get {
//            return "my-swift-sse.disptch.queue"
//        }
//        
//    }
    
    //var name = "my-swift-sse.disptch.queue2"
    
}

