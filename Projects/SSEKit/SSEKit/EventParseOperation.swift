//
//  EventParseOperation.swift
//  SSEKit
//
//  Created by Richard Stelling on 09/03/2016.
//  Copyright © 2016 Richard Stelling All rights reserved.
//

import Foundation

internal class EventParseOperation: NSBlockOperation {
    
    // MARK: State
    private var _finished = false
    override var finished: Bool {
        get { return _finished }
        set { self.willChangeValueForKey("isFinished");  _finished = newValue; self.didChangeValueForKey("isFinished"); }
    }
    
    private var _ready = false
    override var ready: Bool {
        get { return _ready }
        set { self.willChangeValueForKey("isReady"); _ready = newValue; self.didChangeValueForKey("isReady"); }
    }
    
    private var _executing = false
    override var executing: Bool {
        get { return _executing }
        set { self.willChangeValueForKey("isExecuting"); _executing = newValue; self.didChangeValueForKey("isExecuting"); }
    }
    
    override var asynchronous: Bool { return false }
    
    weak var delegate: EventParseDelegate?
    
    let data: NSData
    var scanner: NSScanner?
    
    // MARK: Private Functuons
    private func extractValue(scanner: NSScanner) -> (String?, String?) {
        
        var field: NSString?
        scanner.scanUpToString(":", intoString: &field)
        scanner.scanString(":", intoString: nil)
        
        var value: NSString?
        scanner.scanUpToString("\n", intoString: &value)
        
        return (field?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
    }
    
    private func parseData() {
    
        self.executing = true
        
        defer {
            self.finished = true
            self.executing = false
            self.ready = false
            
            self.delegate = nil
        }
        
        self.data.enumerateByteRangesUsingBlock { (pointer, range, stop) in
            
            if let eventString = NSString(bytes: pointer, length: range.length, encoding: NSUTF8StringEncoding) {
                
                let scanner = NSScanner(string: eventString as String)
                scanner.charactersToBeSkipped = NSCharacterSet.whitespaceCharacterSet()
                
                var eventId: String?, eventName: String?, eventData: String?
                var stop = false
                
                repeat {
                    
                    let entity = self.extractValue(scanner)
                    
                    if entity.0 == nil && entity.1 ==  nil {
                        stop = true
                    }
                    else if entity.0 == "id" {
                        eventId = entity.1
                    }
                    else if entity.0 == "event" {
                        eventName = entity.1
                    }
                    else if entity.0 == "data" {
                        eventData = entity.1
                    }
                    
                } while(!stop) //TODO: This will only work for events sent one at a time
                
                if eventId != nil {
                    self.delegate?.eventParser(didParseEvent: eventId!, name: eventName, data: eventData, timestamp: NSDate())
                }
            }
        }
    }
    
    // MARK: Init
    init(data: NSData) {
    
        self.data = data
    
        super.init()
    
        self.addExecutionBlock {
            self.parseData()
        }
        
        self.ready = true
    }
}

internal protocol EventParseDelegate: class {
    
    func eventParser(didParseEvent identifier: String, name: String?, data: String?, timestamp: NSDate)
}