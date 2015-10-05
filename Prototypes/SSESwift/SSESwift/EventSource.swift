//
//  EventSource.swift
//  server-sent-events
//
//  Created by Richard Stelling on 01/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation

public typealias eventSourceError = (error: NSError) -> Void
public typealias eventSourceMessage = (message: String) -> Void

enum ReadyState {
    
    case Connecting
    case Open
    case Closed(NSError)
    
}

public class EventSource {
    
    ////
    
    var host = "localhost"
    internal var path = "/"
    var port : Int = 8080
    
    let onError : eventSourceError?
    let onMessage : eventSourceMessage?
    
    static let onMessage: eventSourceMessage = { (message: String) -> Void in
        print(message)
    }
    
    static let onError: eventSourceError = { (error: NSError) -> Void in
        print(error)
    }
    
    private var receiveStream : NSInputStream? = nil //These should be Implicitly Unwrapped Optionals! or not optionals?
    private var sendStream : NSOutputStream? = nil
    
    private let receiveStreamHandler = ReceiveStreamHandler()
    private lazy var sendStreamHandler : SendStreamHandler = SendStreamHandler(path: self.path, host: self.host)
    
    // MARK: Init Methods
    
    deinit {
        
        closeStreams()
        
        receiveStream = nil
        sendStream = nil
        
    }
    
    public init(message: eventSourceMessage = onMessage, error: eventSourceError = onError, host: String = "localhost", path: String = "/", port: Int = 8080) {
        
        onError = error
        onMessage = message
        
        self.host = host
        self.path = path
        self.port = port
        
        setup()
    }
    
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
    
    // MARK: Public
    
    // MARK: Testing Functions
    
    func test() {
        
        print("Connecting to \(host)\(path) on port \(port)...");
        
        if onMessage != nil {
            onMessage!(message: " Test message...")
        }
        
        if onError != nil {
            onError!(error: NSError(domain: "SSE", code: 0, userInfo: nil))
        }
    }
}

internal class ReceiveStreamHandler: NSObject, NSStreamDelegate {
    
    var bytesRead = 0
    var buffer : NSMutableData!
    
    let initialBufferSize = 4096
    let maxReadSize = 2048
    
    override init() {
        
        super.init()
        
        buffer = NSMutableData(capacity: initialBufferSize)
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        let myStream = aStream as! NSInputStream
        
        //print("ReceiveStreamHandler: \(aStream) -> \(eventCode)");
        
        switch eventCode {
            
        case NSStreamEvent.HasBytesAvailable:
            
            var buf = [UInt8](count: maxReadSize, repeatedValue: 0)
            let readBytes = myStream.read(&buf, maxLength: maxReadSize)
            buffer.appendBytes(&buf, length: readBytes)
            bytesRead += readBytes
            
//            if(bytesRead < 256) {
//                var header = [UInt8](count: maxReadSize, repeatedValue: 0)
//                bytesRead += myStream.read(&header, maxLength: maxReadSize)
//            }
//            else {
//                //print("HasBytesAvailable")
//                
//                //print("---------------- HasBytesAvailable ----------------")
//                
//                let MAX_READ_BYTES = 4096
//                
//                var buffer = [UInt8](count: MAX_READ_BYTES, repeatedValue: 65)
//                let readBytes = myStream.read(&buffer, maxLength: MAX_READ_BYTES)
//                bytesRead += readBytes
//                
//                //print("BUFFER (\(readBytes)): \(buffer)")
//            
//                let data = NSData(bytes: &buffer, length: readBytes)
//            
//                let message = String(data: data, encoding: NSUTF8StringEncoding)!
//            
//                //print("BUFFER (\(readBytes)): \(message)")
//                print(message)
//                //print("HasBytesAvailable: \(NSDate().description)")
//                //print("\(message.characters.count)----------------------------------------------------")
//            }
            
        case NSStreamEvent.EndEncountered:
            let message = String(data: buffer, encoding: NSUTF8StringEncoding)!
            print("EOF: \(bytesRead)----------------------------------------------------")
            print("\(buffer)")
            print("---------------------------------------------------------------------")
            print("\(message)")
        default: break
        
        }
        
        
    }
}

internal class SendStreamHandler: NSObject, NSStreamDelegate {
    
    var isAttached = false
    
    let path : String
    let host : String
    
    init(path: String, host: String) {
        self.path = path
        self.host = host
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        let myStream = aStream as! NSOutputStream
        
        //print("SendStreamHandler: \(aStream) -> \(eventCode)");
        
        switch eventCode {
            
        case NSStreamEvent.HasSpaceAvailable where !isAttached:
            isAttached = true
            print("---------------- HasSpaceAvailable ---------------- ")
            
            var GET = "GET \(path) HTTP/1.1\r\n"
            GET += "Host: \(host)\r\n"
            GET += "User-Agent: SSEKit v0.1\r\n"
            GET += "Accept: text/event-stream\r\n"
            GET += "Cache-Control: no-cache\r\n"
            GET += "Connection: keep-alive\r\n\r\n"
            
            let getData = (GET as NSString).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            var bytes = [UInt8](count: getData.length, repeatedValue: 0)
            getData.getBytes(&bytes, length: bytes.count)
            
            let writtenBytes = myStream.write(bytes, maxLength: getData.length)
            
            print("Written: \(writtenBytes) bytes")
            
            print("---------------- /HasSpaceAvailable ---------------- ")
            
        case NSStreamEvent.ErrorOccurred:
            print("SendStreamHandler: \(aStream.streamError) -> \(eventCode)");
            
        default: break
            
        }
    }
}
