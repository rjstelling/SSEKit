//
//  EventSource.swift
//  SSEKit
//
//  Created by Richard Stelling on 22/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation
import State

public class EventSource {
    
    public typealias eventSourceError = (error: NSError) -> Void
    public typealias eventSourceMessage = (message: String) -> Void
    
    internal var host = "localhost"
    internal var path = "/"
    internal var port : Int = 8080
    
    internal var onError : eventSourceError = { (error: NSError) -> Void in print(error) }
    internal var onMessage : eventSourceMessage = { (message: String) -> Void in print(message) }
    
    private lazy var stateMachine : State<EventSource> = State<EventSource>(initialState: ReadyState.Closed(nil), delegate: self)
   
    private var receiveStream : NSInputStream?
    private var sendStream : NSOutputStream?
    
    private lazy var receiveStreamHandler : ReceiveStreamHandler = ReceiveStreamHandler(delegate: self)
    private lazy var sendStreamHandler : SendStreamHandler = SendStreamHandler(delegate: self, path: self.path, host: self.host, port: self.port)
    
    //MARK: Init
    public init(message: eventSourceMessage! = nil, error: eventSourceError! = nil, host: String! = nil, path: String! = nil, port: Int! = nil) {
        
        if(error != nil) { onError = error }
        if(message != nil) { onMessage = message }
        
        if(host != nil) { self.host = host }
        if(path != nil) { self.path = path }
        if(port != nil) { self.port = port }
        
        setup()
    }
}

//MARK: Streams
public extension EventSource {
    
    private func setup() {
        
        NSStream.getStreamsToHostWithName(host, port: port, inputStream: &receiveStream, outputStream: &sendStream)
        
        //Set stream delegates delegates, these are created above
        sendStream?.delegate = sendStreamHandler
        receiveStream?.delegate = receiveStreamHandler
        
        //Set runloop
        sendStream?.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        receiveStream?.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        openStreams()
    }
    
    private func openStreams() {
    
        sendStream?.open()
        receiveStream?.open()
        
        stateMachine.state = .Connecting
    }
    
    private func closeStreams() {
        
        sendStream?.close()
        receiveStream?.close()
        
        stateMachine.state = .Closed(nil)
    }
    
    public func dataTransfer() -> (Int, Int) {
        return (sendStreamHandler.totalBytesSent, receiveStreamHandler.totalBytesReveived)
    }
}

// MARK: HTTPStreamHandlerDelegate
extension EventSource: HTTPStreamHandlerDelegate {
    
    func bytesSent(streamHandler: StreamHandler, byteCount: Int) {
        //print("Bytes send to host[\(streamHandler)]: \(byteCount)");
    }
    
    func bytesReceived(streamHandler: StreamHandler, byteCount: Int) {
        //print("Bytes received from host[\(streamHandler)]: \(byteCount)");
    }
    
    func didOpenedConnection(streamHandler: StreamHandler) {
        stateMachine.state = .Open
    }
    
    func didError(streamHandler: StreamHandler, error: NSError?) {
        stateMachine.state = .Closed(error)
    }
    
    func didReceiveMessage(streamHandler: StreamHandler, message: String) {
        print("MESSAGE: \(message)");
    }
}

// MARK: Versions
public extension EventSource {
    
    public class var eventSourceVersion : String {
        get {
            return "v1.0.0.3-alpha"
        }
    }
    
    public class var packageVersion : String {
        get {
            return "\(EventSource.eventSourceVersion) (State \(State<EventSource>.version))"
        }
    }
}

//MARK: Debug Strings & Object Info
extension EventSource: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        get {
            return ("\(self.host):\(self.port)\(self.path) :: State: \(self.stateMachine.state) -> " + EventSource.packageVersion)
        }
    }
}

//MARK: State Delegate
extension EventSource: StateDelegate {
    
    public enum ReadyState {
        
        //case Unknown
        case Connecting
        case Open
        case Closed(NSError?)
    }
    
    public typealias StateType = ReadyState
    
    public func shouldTransitionFrom(from:StateType, to:StateType) -> Bool {
        switch (from, to) {
            
        case(.Connecting, .Open),
        (.Connecting, .Closed):
            return true
            
        case(.Open, .Closed):
            return true
            
        case(.Closed, .Connecting):
            return true
            
        default:
            return false
        }
    }
    
    public func didTransitionFrom(from:StateType, to:StateType) {
        print("EventSource state change: \(from) -> \(to)")
    }
    
    public func failedTransitionFrom(from:StateType, to:StateType) {
        
    }
}
