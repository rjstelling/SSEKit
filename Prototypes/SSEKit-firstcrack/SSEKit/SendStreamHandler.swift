//
//  SendStreamHandler.swift
//  SSEKit
//
//  Created by Richard Stelling on 12/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation

internal class SendStreamHandler: StreamHandler {
    
    var isAttached = false
    
    let path : String
    let host : String
    let port : Int
    
    init(delegate: HTTPStreamHandlerDelegate, path: String, host: String, port: Int) {
        
        self.path = path
        self.host = host
        self.port = port
        
        super.init(delegate: delegate)
    }

    internal var totalBytesSent : Int = 0
}

extension SendStreamHandler: NSStreamDelegate {
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        let myStream = aStream as! NSOutputStream
        
        switch eventCode {
            
        case NSStreamEvent.HasSpaceAvailable where !isAttached:
            isAttached = true
            //print("---------------- HasSpaceAvailable ---------------- ")
            
            var GET = "GET \(path) HTTP/1.1\r\n"
            GET += "Host: \(host):\(port)\r\n"
            GET += "User-Agent: SSEKit v1.0-alpha\r\n"
            GET += "Accept: \(ContentType.TextEventStream.rawValue)\r\n"
            GET += "Cache-Control: no-cache\r\n"
            GET += "Connection: \(Connection.KeepAlive.rawValue)\r\n\r\n"
            
            let getData = (GET as NSString).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            var bytes = [UInt8](count: getData.length, repeatedValue: 0)
            getData.getBytes(&bytes, length: bytes.count)
            
            let writtenBytes = myStream.write(bytes, maxLength: getData.length)
            
            self.delegate.bytesSent(self, byteCount: writtenBytes)
            self.delegate.didOpenedConnection(self)
            
            totalBytesSent += writtenBytes
            
        case NSStreamEvent.ErrorOccurred:
            print("SendStreamHandler: \(aStream.streamError) -> \(eventCode)");
            
        default: break
            
        }
    }
}