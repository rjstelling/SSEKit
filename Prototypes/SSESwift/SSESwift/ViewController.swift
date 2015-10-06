//
//  ViewController.swift
//  SSESwift
//
//  Created by Richard Stelling on 01/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import UIKit

extension ViewController : StateDelegate {
    
    enum TestState : Int {
        case Unknown = 0
        case Begin = 1
        case Processing = 2
        case End = 3
        case Error
    }
    
    typealias StateType = TestState
    
    func shouldTransitionFrom(from:StateType, to:StateType) -> Bool {
        
        switch(from, to) {
            
        case(.Unknown, .Begin):
            return true
            
        case(.Begin, .Processing):
            return true
            
        case(.Processing, .End), (.Processing, .Error):
            return true
            
        case(.Error, .Begin):
            return true
            
        case(.End, .Begin):
            return true
            
        default:
            return false
        }
        
    }
    
    func didTransitionFrom(from:StateType, to:StateType) {
        print("[\(stateMachine.lockingQueueName)] \(from) -> \(to)")
        
        if(to == .End)
        {
            self.onEnd()
        }
    }
    
    func failedTransitionFrom(from:StateType, to:StateType) {
        print("[\(stateMachine.lockingQueueName)] FAILED!")
    }
}

class ViewController: UIViewController {
    
    //typealias StateType = TestState
    var stateMachine : State<ViewController>!
    //var stateMachineTwo : State<ViewController>!
    
    //var stateMachine2 : State<ViewController>! = State(StateType.Unknown, delegate: self)

    //var eventSource : EventSource? = EventSource(path: "/sse")
    //var eventSource : EventSource? = EventSource(host: "192.168.103.100", path: "/test.php", port: 80)
    // var eventSource : EventSource? = EventSource(host: "www.thisismyengine.com", path: "/index.html", port: 80)
    
    var count = 0
    
    var queueOne = dispatch_queue_create("Q1", nil)
    var queueTwo = dispatch_queue_create("Q2", nil)
    var queueThree = dispatch_queue_create("Q3", nil)
    
    let MAX = 10000
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        stateMachine = State(initialState: .Unknown, delegate: self)
        //stateMachineTwo = State(initialState: .Unknown, delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        


        
        
//        print("Current state: \(stateMachine.state), try .Begin")
//        stateMachine.state = .Begin
//        print("Current state: \(stateMachine.state), try .Processing")
//        stateMachine.state = .Processing
//        print("Current state: \(stateMachine.state), try .End")
//        stateMachine.state = .End
//        print("Current state: \(stateMachine.state), try .Error")
//        stateMachine.state = .Error
//        print("Current state: \(stateMachine.state), try .Begin")
//        stateMachine.state = .Begin
        
//        self.synchronize {
//            dispatch_sync(self.queueOne) {
//                
//                for var i = 0; i < self.MAX; i++ {
//                    self.count++
//                    print("Q1: \(self.count)")
//                }
//            }
//            
//            dispatch_sync(self.queueTwo) {
//                
//                for var j = 0; j < self.MAX; j++ {
//                    self.count++
//                    print("Q2: \(self.count)")
//                }
//            }
//            
//            dispatch_sync(self.queueThree) {
//                
//                for var k = 0; k < self.MAX; k++ {
//                    self.count++
//                    print("Q3: \(self.count)")
//                }
//            }
//        }
//        
//        self.synchronize {
//            print("TOTAL: \(self.count)")
//        }
        
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
    
    func onEnd() {
        print("***********************************")
    }
    @IBAction func onTest(sender: UIButton) {
//        dispatch_async(self.queueOne) {
//            for var i = 0; i < self.MAX; i++ {
//                let randonState = TestState(rawValue: Int(arc4random_uniform(5)))
//                self.stateMachine.state = randonState!
//            }
//        }
        
        for var j = 0; j < self.MAX; j++ {
            
            let secondsToWait = Int(arc4random_uniform(10))
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(UInt64(secondsToWait) * NSEC_PER_SEC)), self.queueTwo) {
                let randonState = TestState(rawValue: Int(arc4random_uniform(5)))
                self.stateMachine.state = randonState!
                //self.stateMachineTwo.state = randonState!

            }
        }
        
//        dispatch_async(self.queueThree) {
//            for var k = 0; k < self.MAX; k++ {
//                let randonState = TestState(rawValue: Int(arc4random_uniform(5)))
//                self.stateMachine.state = randonState!
//            }
//        }
    }
}
