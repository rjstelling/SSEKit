//
//  SSEManager.swift
//  SSEKit
//
//  Created by Richard Stelling on 23/02/2016.
//  Copyright © 2016 Richard Stelling All rights reserved.
//

import Foundation

// MARK: Notifications
public extension SSEManager {
    
    public enum Notification: String {
        
        case Connected
        case Event
        case Disconnected
        
        public enum Key: String {
            
            // Event
            case Source
            case Identifier
            case Name
            case Data
            case Timestamp
            
            
        }
    }
}

public class SSEManager {
    
//    public enum Notification: String {
//        
//        case Connected
//        case Event
//        case Disconnected
//        
//        public enum Key: String {
//            
//            // Event
//            case Source
//            case Identifier
//            case Name
//            case Data
//            case Timestamp
//            
//            
//        }
//    }
    
    private var eventSources: [EventSource] = []
    
    // Manager Info
    
    
    internal init() {
        
    }
    
    public convenience init(sources: [EventSourceConfiguration]) {
    
        self.init()
        
        for config in sources {
            addEventSource(config)
        }
    }
    
    /**
     Add an EventSource to the manager
     */
    func addEventSource(eventSourceConfig: EventSourceConfiguration) {
        
        let eventSource = EventSource(configuration: eventSourceConfig, delegate: self)
        self.eventSources.append(eventSource)
    }
}

extension SSEManager: EventSourceDelegate {
    
    func eventSource(eventSource: EventSource, didChangeState state: EventSource.ReadyState) {
        
        print("State -> \(eventSource) -> \(state)")
    }
    
    func eventSourceDidConnect(eventSource: EventSource) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.Connected.rawValue, object: self, userInfo: [ Notification.Key.Source.rawValue : eventSource.configuration.uri ])
    }
    
    func eventSourceWillDisconnect(eventSource: EventSource) {
        
    }
    
    func eventSourceDidDisconnect(eventSource: EventSource) {
        
        //Remove disconnected EventSource objects from the array
        if let index = self.eventSources.indexOf(eventSource) {
            self.eventSources.removeAtIndex(index)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.Disconnected.rawValue, object: self, userInfo: [ Notification.Key.Source.rawValue : eventSource.configuration.uri ])
    }
    
    func eventSource(eventSource: EventSource, didReceiveEvent event: EventSource.Event) {
        
        //print("[ES#: \(eventSources.count)] \(eventSource) -> \(event)")
        
        var userInfo: [String: AnyObject] = [Notification.Key.Source.rawValue : eventSource.configuration.uri, Notification.Key.Timestamp.rawValue : event.metadata.timestamp]
        
        if let identifier = event.identifier {
            userInfo[Notification.Key.Identifier.rawValue] = identifier
        }
        
        if let name = event.event {
            userInfo[Notification.Key.Name.rawValue] = name
        }
        
        if let data = event.data {
            userInfo[Notification.Key.Data.rawValue] = data
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.Event.rawValue, object: self, userInfo: userInfo)
    }
    
    func eventSource(eventSource: EventSource, didEncounterError error: EventSource.Error) {
        
        //print("Error -> \(eventSource) -> \(error)")
    }
}