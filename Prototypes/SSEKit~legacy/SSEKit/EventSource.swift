//
//  EventSource.swift
//  SSEKit
//
//  Created by Richard Stelling on 09/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation
import State

//enum ObjCBool: DarwinBoolean, RawRepresentable {
//    case YES = true
//    case NO = false
//}

public class EventSource : HTTPStreamHandlerDelegate, StateDelegate {
    
    // MARK: ReadyState
    public enum ReadyState {
        
        //case Unknown
        case Connecting
        case Open
        case Closed(NSError?)
        
    }
    
    public typealias StateType = ReadyState
    
    // MARK: Callbacks
    public typealias eventSourceError = (error: NSError) -> Void
    public typealias eventSourceMessage = (message: String) -> Void
    
    let onError : eventSourceError!
    let onMessage : eventSourceMessage!
    
    // MARK: Ivars
    
    internal var host = "localhost"
    internal var path = "/"
    internal var port : Int = 8080
    
    // MARK: Stream Handlers
    private lazy var receiveStreamHandler : ReceiveStreamHandler = ReceiveStreamHandler(delegate: self)
    private lazy var sendStreamHandler : SendStreamHandler = SendStreamHandler(delegate: self, path: self.path, host: self.host, port: self.port)
    
    // MARK: Versions
    
    public static let version = "v1.0.0.2-alpha"
    public var versionString : String {
        get {
            return "\(EventSource.version) (State \(stateMachine.version))"
        }
    }
    
    private lazy var stateMachine : State<EventSource> = State<EventSource>(initialState: ReadyState.Closed(nil), delegate: self)
    
    // MARK: HTTPStreamHandlerDelegate
    
    func bytesSent(byteCount: Int) {
        print("Bytes send to host: \(byteCount)");
    }
    
    func bytesReceived(byteCount: Int) {
        print("Bytes received from host: \(byteCount)");
    }
    
    //TODO
    
    // MARK: StateDelegate
    
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
        
    }
  
    public func failedTransitionFrom(from:StateType, to:StateType) {
        
    }
    
    // MARK: Init Methods
    
    deinit {
        
        closeStreams()
        
        receiveStream = nil
        sendStream = nil
        
    }
    
    //TODO: Set state
    public init(message: eventSourceMessage = { (message: String) -> Void in print(message) }, error: eventSourceError = { (error: NSError) -> Void in print(error) }, host: String = "localhost", path: String = "/", port: Int = 8080) {
        
        onError = error
        onMessage = message
        
        self.host = host
        self.path = path
        self.port = port
        
        setup()
    }
    
    // MARK: Helpers
    private func setup() {
        
        NSStream.getStreamsToHostWithName(host, port: port, inputStream: &receiveStream, outputStream: &sendStream)
        
        //Set delegates
        sendStream?.delegate = sendStreamHandler
        receiveStream?.delegate = receiveStreamHandler
        
        //Set runloop
        sendStream?.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        receiveStream?.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        openStreams()
    }
    
    // MARK: Streams
    
    private var receiveStream : NSInputStream? = nil //These should be Implicitly Unwrapped Optionals! or not optionals?
    private var sendStream : NSOutputStream? = nil
    
    internal func openStreams() {
        
        print("Open streams...");
        
        sendStream?.open()
        receiveStream?.open()
        
    }
    
    internal func closeStreams() {
        
        print("Close streams...");
        
        sendStream?.close()
        receiveStream?.close()
        
    }
}