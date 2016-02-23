//
//  StreamHandler.swift
//  SSEKit
//
//  Created by Richard Stelling on 12/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation

let StreamHandlerErrorDomain = "StreamHandlerErrorDomain" //enum:string?

let HTTPLineEnd = NSData(bytes: [0x0D, 0x0A] as [UInt8], length: 2)
let HTTPBlankLine = NSData(bytes: [0x0D, 0x0A, 0x0D, 0x0A] as [UInt8], length: 4)

internal class StreamHandler : NSObject {
    
    internal enum ContentType: String {
        case TextHTML = "text/html"
        case TextEventStream = "text/event-stream"
    }
    
    internal enum TransferEncoding: String {
        case Chunked = "chunked"
    }
    
    internal enum Connection: String {
        case KeepAlive = "Keep-Alive"
    }
    
    internal unowned let delegate : HTTPStreamHandlerDelegate
    
    internal init(delegate : HTTPStreamHandlerDelegate) {
        self.delegate = delegate
    }
}

// TODO: ??? break out into protocol extentions ???
protocol HTTPStreamHandlerDelegate : class {
    
    //MARK: Sending Data
    func bytesSent(streamHandler: StreamHandler, byteCount: Int)
    func didOpenedConnection(streamHandler: StreamHandler)
    //TODO: fialed to open connection - REQUIRED
    
    //MARK: Receive Data
    func bytesReceived(streamHandler: StreamHandler, byteCount: Int)
    func didError(streamHandler: StreamHandler, error: NSError?)
    func didReceiveMessage(streamHandler: StreamHandler, message: String)
}

extension NSOperationQueue {
    
    convenience init(qualityOfService: NSQualityOfService, maxConcurrentOperationCount: Int = 1) {
        self.init()
        
        self.qualityOfService = qualityOfService
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
    
}