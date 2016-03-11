//
//  EventSource.swift
//  SSEKit
//
//  Created by Richard Stelling on 23/02/2016.
//  Copyright © 2016 Richard Stelling All rights reserved.
//

import Foundation

@objc
public class EventSource: NSObject {
    
    internal enum ReadyState: Int {
        case Connecting = 0
        case Open = 1
        case Closed = 2
    }
    
    public struct Event: CustomDebugStringConvertible {
        
        struct Metadata {
            
            let timestamp: NSDate
            let hostUri: String
        }
        
        let metadata: Metadata
        let configuration: EventSourceConfiguration
        
        let identifier: String?
        let event: String?
        let data: NSData?
        
        init?(withEventSource eventSource: EventSource, identifier: String?, event: String?, data: NSData?) {
            
            guard identifier != nil else {
                
                return nil
            }
            
            configuration = eventSource.configuration
            self.metadata = Metadata(timestamp: NSDate(), hostUri: configuration.uri)
            
            self.identifier = identifier
            self.event = event
            self.data = data
        }
        
        public var debugDescription: String {
            
            return "Event {\(self.identifier != nil ? self.identifier! : "nil"), \(self.event != nil ? self.event! : "nil"), Data length: \(self.data != nil ? self.data!.length : 0)}"
        }
    }
    
    public enum Error: ErrorType {
        
        case BadEvent
        case SourceConnectionTimeout
        case SourceNotFound(Int?) //HTTP Status code
        case Unknown
    }
    
    internal private(set) var readyState: ReadyState = .Closed {
        
        didSet {
            
            if let delegate  = self.delegate {
                delegate.eventSource(self, didChangeState: self.readyState) //???: what queue
            }
        }
    }
    
    private let opsQueue = NSOperationQueue()
    
    internal let configuration: EventSourceConfiguration
    private let delegate: EventSourceDelegate?
    
    private var connectionTimer: NSTimer? = nil
    
    private func cancelConnectionTimer() {
        
        self.connectionTimer?.invalidate()
        self.connectionTimer = nil
    }
    
    private var task: NSURLSessionDataTask?
    
    internal init(configuration: EventSourceConfiguration, delegate: EventSourceDelegate? = nil) {
        
        self.configuration = configuration //copy
        self.delegate = delegate
        
        self.opsQueue.maxConcurrentOperationCount = 1
        
        super.init()
        
        connect()
    }
    
    func connect() {
        
        self.readyState = .Connecting
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.timeoutIntervalForRequest = NSTimeInterval(INT_MAX)
        sessionConfig.timeoutIntervalForResource = NSTimeInterval(INT_MAX)
        sessionConfig.HTTPAdditionalHeaders = ["Accept" : "text/event-stream", "Cache-Control" : "no-cache"]
        
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil) //This requires self be marked as @objc
        
        //???: We might need this task\\?
        
        let urlComponents = NSURLComponents()
        urlComponents.host = self.configuration.hostAddress
        urlComponents.path = self.configuration.endpoint
        urlComponents.port = self.configuration.port
        urlComponents.scheme = "http" //FIXME: This should be settable in config
        
        if let url = urlComponents.URL {
//            if #available(Swift 2.2) {
//                //self.connectionTimer = NSTimer.scheduledTimerWithTimeInterval(self.configuration.timeout, target: self, selector: #selector(onConnectionTimeout(_:)), userInfo: nil, repeats: false)
//            }
//            else {
//                self.connectionTimer = NSTimer.scheduledTimerWithTimeInterval(self.configuration.timeout, target: self, selector: "onConnectionTimeout:", userInfo: nil, repeats: false)
//            }
            
            self.connectionTimer = NSTimer.scheduledTimerWithTimeInterval(self.configuration.timeout, target: self, selector: "onConnectionTimeout:", userInfo: nil, repeats: false)
            self.task = session.dataTaskWithURL(url)
            self.task?.resume()
        }
        else {
            //error
        }
    }
    
    func disconnect() {
        
        delegate?.eventSourceWillDisconnect(self)
        
        self.task?.cancel()
        self.task = nil
        self.readyState = .Closed
        
        delegate?.eventSourceDidDisconnect(self)
    }
}

extension EventSource {
    
    @objc
    private func onConnectionTimeout(timer: NSTimer) {
        
        timer.invalidate()
        
        disconnect()
    }
}

extension EventSource: NSURLSessionDataDelegate {
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        disconnect()
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        cancelConnectionTimer() //If we get here we have some kind of connection we can handle
        
        guard let httpResponce = response as? NSHTTPURLResponse else {
            
            self.delegate?.eventSource(self, didEncounterError: .Unknown)
            disconnect()
            completionHandler(.Cancel)
            return
        }
        
        switch httpResponce.statusCode {
            
        case 200...299:
            fallthrough
        case 300...399:
            self.delegate?.eventSourceDidConnect(self)
            completionHandler(.Allow)
            self.readyState = .Open
            break
        
        case 400...499:
            fallthrough
        default:
            self.delegate?.eventSource(self, didEncounterError: .SourceNotFound(httpResponce.statusCode))
            disconnect()
            completionHandler(.Cancel)
        }
    }

    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        if Process.arguments.count > 1 && Process.arguments[1] == "INLINE" {
            inline_URLSession(session, dataTask: dataTask, didReceiveData: data)
        }
        else if Process.arguments.count > 1 && Process.arguments[1] == "OPS" {
            ops_URLSession(session, dataTask: dataTask, didReceiveData: data)
        }
        else {
            inline_URLSession(session, dataTask: dataTask, didReceiveData: data)
        }
    }
    
    public func ops_URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            let parserOp = EventParseOperation(data: data)
            parserOp.delegate = self
            self.opsQueue.addOperation(parserOp)
        }
    }

    public func inline_URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        func extractValue(scanner: NSScanner) -> (String?, String?) {
            
            var field: NSString?
            scanner.scanUpToString(":", intoString: &field)
            scanner.scanString(":", intoString: nil)
            
            var value: NSString?
            scanner.scanUpToString("\n", intoString: &value)
            
            return (field?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
        }
                
        data.enumerateByteRangesUsingBlock { (pointer, range, stop) in
            
            if let eventString = NSString(bytes: pointer, length: range.length, encoding: 4) {
                
                let scanner = NSScanner(string: eventString as String)
                scanner.charactersToBeSkipped = NSCharacterSet.whitespaceCharacterSet()
                
                var eventId: String?, eventName: String?, eventData: String?
                var stop = false
                
                repeat {
                    
                    let entity = extractValue(scanner)
                    
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
                    
                } while(!stop)
                
                
                /////////////////////////////
                // dont create events if nobody is listerning
                /////////////////////////////
                if let evnArray = self.configuration.events, let evn = eventName where evnArray.contains(evn) {
                    
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                        
                        let event = Event(withEventSource: self, identifier: eventId, event: evn, data: eventData?.dataUsingEncoding(NSUTF8StringEncoding))
                        
                        if let delegate = self.delegate, let event = event {
                            delegate.eventSource(self, didReceiveEvent: event)
                        }
                    }
                }
                else if self.configuration.events == nil {
                 
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                        
                        let event = Event(withEventSource: self, identifier: eventId, event: eventName, data: eventData?.dataUsingEncoding(NSUTF8StringEncoding))
                        
                        if let delegate = self.delegate, let event = event {
                            delegate.eventSource(self, didReceiveEvent: event)
                        }
                    }
                    
                }
                ////////////////////////////
            }
        }
    }

}

extension EventSource: EventParseDelegate {
    
    func eventParser(didParseEvent identifier: String, name: String?, data: String?, timestamp: NSDate) {
        
        //TODO: Dispatch on another background thread?
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
        
            if let event = Event(withEventSource: self, identifier: identifier, event: name, data: data?.dataUsingEncoding(NSUTF8StringEncoding)) {
                self.delegate?.eventSource(self, didReceiveEvent: event)
            }
        }
    }
}

internal protocol EventSourceDelegate {
    
    func eventSource(eventSource: EventSource, didChangeState state: EventSource.ReadyState)
    
    func eventSourceDidConnect(eventSource: EventSource)
    func eventSourceWillDisconnect(eventSource: EventSource)
    func eventSourceDidDisconnect(eventSource: EventSource)
    
    func eventSource(eventSource: EventSource, didReceiveEvent event: EventSource.Event)
    func eventSource(eventSource: EventSource, didEncounterError error: EventSource.Error)
}
