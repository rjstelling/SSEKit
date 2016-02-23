//
//  StreamHandler.swift
//  SSEKit
//
//  Created by Richard Stelling on 12/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation

internal class StreamHandler : NSObject {
    
    enum ContentType: String {
        case TextHTML = "text/html"
        case TextEventStream = "text/event-stream"
    }
    
    enum TransferEncoding: String {
        case Chunked = "chunked"
    }
    
    enum Connection: String {
        case KeepAlive = "Keep-Alive"
    }
    
    let delegate : HTTPStreamHandlerDelegate
    
    internal init(delegate : HTTPStreamHandlerDelegate) {
        self.delegate = delegate
    }
    
}

// TODO: break out into protocol extentions
protocol HTTPStreamHandlerDelegate {
    
    //MARK: Sending Data
    func bytesSent(byteCount: Int)
    
    
    //MARK: Receive Data
    func bytesReceived(byteCount: Int)
}