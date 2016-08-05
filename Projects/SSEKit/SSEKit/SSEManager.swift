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

// MARK: - SSEManager
public class SSEManager {
    
    private var eventSources = Set<EventSource>()
    
    public init(sources: [EventSourceConfiguration]) {
    
        for config in sources {
            addEventSource(config)
        }
    }
    
    /**
     Add an EventSource to the manager.
     */
    public func addEventSource(eventSourceConfig: EventSourceConfiguration) -> EventSource {
    
        var eventSource: EventSource!
        
        if let primaryIndex = self.eventSources.indexOf( { eventSourceConfig.uri == $0.configuration.uri } ) {
            
            if let primaryEventSource = self.eventSources[primaryIndex] as? PrimaryEventSource {
                eventSource = ChildEventSource(withConfiguration: eventSourceConfig, primaryEventSource: primaryEventSource, delegate: self)
            }
        }
        else {
            
            eventSource = PrimaryEventSource(configuration: eventSourceConfig, delegate: self)
        }
        
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            self.eventSources.insert(eventSource)
        }
        
        // Cast `eventSource` to `EventSourceConnectable` and connect
        (eventSource as? EventSourceConnectable)?.connect()
        
        return eventSource
    }
    
    /**
     Disconnect and remove EventSource from manager.
     */
    internal func removeEventSource<T: EventSource where T: EventSourceConnectable>(eventSource: T) {
        
        eventSource.disconnect()

        //TODO
        
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            self.eventSources.remove(eventSource)
        }
    }
}

// MARK: - EventSourceDelegate
extension SSEManager: EventSourceDelegate {
    
    public func eventSource(eventSource: EventSource, didChangeState state: ReadyState) {
        
        //TODO: Logging
        print("State -> \(eventSource) -> \(state)")
    }
    
    public func eventSourceDidConnect(eventSource: EventSource) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.Connected.rawValue, object: eventSource, userInfo: [ Notification.Key.Source.rawValue : eventSource.configuration.uri ])
    }
    
    public func eventSourceWillDisconnect(eventSource: EventSource) {}
    
    public func eventSourceDidDisconnect(eventSource: EventSource) {
        
        //Remove disconnected EventSource objects from the array
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            //TODO
//            if let esIndex = self.eventSources.indexOf(eventSource) {
//                self.eventSources.removeAtIndex(esIndex)
//            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.Disconnected.rawValue, object: eventSource, userInfo: [ Notification.Key.Source.rawValue : eventSource.configuration.uri ])
    }
    
    public func eventSource(eventSource: EventSource, didReceiveEvent event: Event) {
        
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
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.Event.rawValue, object: eventSource, userInfo: userInfo)
    }
    
    public func eventSource(eventSource: EventSource, didEncounterError error: Error) {
        
        //TODO: Send error notification
        //print("Error -> \(eventSource) -> \(error)")
    }
}