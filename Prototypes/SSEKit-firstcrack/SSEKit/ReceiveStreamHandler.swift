//
//  ReceiveStreamHandler.swift
//  SSEKit
//
//  Created by Richard Stelling on 22/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation
import State

internal class ReceiveStreamHandler: StreamHandler {
    
    //var totalBytesRead = 0
    internal var totalBytesReveived : Int = 0
    var buffer : NSMutableData!
    var drainingBuffer = false
    
    let initialBufferSize = 4096
    let maxReadSize = 2048
    let minDrainDataSize = 64
    
    var store: [String] = []
    var rawstore: [String] = []
    
    //Drain
    var distance: String.Index.Distance = 0
    
    private lazy var stateMachine : State<ReceiveStreamHandler> = State<ReceiveStreamHandler>(initialState: ReadSocketState.Idle, delegate: self)
    
    internal var headers : Dictionary<String, String>?
    
    let dataContainer = StreamedDataContainer()
    private let underlyingQueue: dispatch_queue_t!
    private let appendDataQueue = NSOperationQueue(qualityOfService: .Background, maxConcurrentOperationCount: 1)
    private let drainDataQueue = NSOperationQueue(qualityOfService: .Utility, maxConcurrentOperationCount: 1)
    
    override init(delegate: HTTPStreamHandlerDelegate) {
        
        //print("*******************************************************")
        
        let attrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0)
        underlyingQueue = dispatch_queue_create("com.naim.ReceiveStreamHandler.TargetQueue", attrs)
        
        appendDataQueue.underlyingQueue = underlyingQueue //dispatch_queue_create("com.naim.ReceiveStreamHandler.Queue.1", attrs)
        drainDataQueue.underlyingQueue = underlyingQueue //dispatch_queue_create("com.naim.ReceiveStreamHandler.Queue.2", attrs)
        
       // dispatch_set_target_queue(appendDataQueue.underlyingQueue, underlyingQueue)
        //dispatch_set_target_queue(drainDataQueue.underlyingQueue, underlyingQueue)
        
        super.init(delegate: delegate)
    }
}

extension ReceiveStreamHandler: StateDelegate {
    
    enum ReadSocketState {
        
        case Idle
        case HeaderParsing
        case MessageParsing
        case ConnectionClosed
        case Error(NSError?)
    }
    
    typealias StateType = ReadSocketState
    
    func shouldTransitionFrom(from:StateType, to:StateType) -> Bool {
        
        switch (from, to) {
            
        case(.Idle, .HeaderParsing):
            return true
            
        case(.HeaderParsing, .MessageParsing),
        (.HeaderParsing, .Error):
            return true
            
        case(.MessageParsing, .ConnectionClosed),
        (.MessageParsing, .Error):
            return true
            
        case(.Error, .Idle):
            return true
            
        default:
            return false
        }
        
    }
    
    func didTransitionFrom(from:ReadSocketState, to:ReadSocketState) {
        
        switch(from, to) {
            
        case(_, .Error((let error))):
            print("ERROR: \(error)")
            delegate.didError(self, error: error)
            break;
            
        default:
            return
        }
    }
    
    func failedTransitionFrom(from:StateType, to:StateType) {
        
    }
}

extension ReceiveStreamHandler: NSStreamDelegate {
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        let myStream = aStream as! NSInputStream
        
        switch(eventCode, stateMachine.state) {
            
        case(NSStreamEvent.OpenCompleted, .Idle):
            stateMachine.state = .HeaderParsing
            break
            
        case(NSStreamEvent.HasBytesAvailable, _):
            
            /*

            When running messages in fast rawstroe gets more data than with slower conectins thsi si expects and the parsing algo needs to handel this
            
            basicly we are loosing some data while moving from the stram to the DataContainer
            
            */
            
            appendDataQueue.addOperationWithBlock {
                var buffer = [UInt8](count: self.maxReadSize, repeatedValue: 0)
                let readBytes = myStream.read(&buffer, maxLength: self.maxReadSize)
                self.dataContainer.append(buffer, length: readBytes)
                
                ////
                let data = NSData(bytes: buffer, length: readBytes)
                
                if let string = String(data: data, encoding: NSUTF8StringEncoding) {
                    self.rawstore.append(string)
                }
                
                ////
                
                
                
                self.totalBytesReveived += readBytes
            }
            
            self.scheduleDrain()
            
            break
            
        case(NSStreamEvent.EndEncountered, _):
            //print("Streamed data: \(dataContainer.length)")
            //print("Data string: \(dataContainer.internalStringStorage)")
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.drainDataQueue.addOperationWithBlock {
                    print("***********************************")
                    print("\(self.store)")
                    print("***********************************")
                    print("\(self.rawstore)")
                }
            }
            break
            
        default:
            break
        }
        
        self.delegate.bytesReceived(self, byteCount: totalBytesReveived)
    }
}

internal extension ReceiveStreamHandler {
    
    func scheduleDrain() {
        
        //print("Schedule Drain: [\(drainDataQueue.operationCount )]");
        
        if( drainDataQueue.operationCount == 0 &&
            dataContainer.length >= minDrainDataSize ) {
            
                drainDataQueue.addOperationWithBlock {
                    self.drain()
                }
        }
    }
    
    private func drain() {
        
        //print("Draining");
        
        let start = dataContainer.startIndex.advancedBy(distance, limit: dataContainer.endIndex)
        let chunk = dataContainer.chunk(fromIndex: start)
        
        let delimiter = "\r\n\r\n"
        
        //print("Chunk: \(chunk.characters.count)");
        
        if (chunk.characters.count > 0) {
            
            let scanner = NSScanner(string: chunk) //the scanner will by default skip white space
        
            while(!scanner.atEnd) {
            
                var stringBuffer: NSString? = nil
                
                if scanner.scanUpToString(delimiter, intoString: &stringBuffer) { //capture string in nil
                
                    if let foundString: String! = (stringBuffer as! String) {

//                        switch(stateMachine.state) {
//                        case(.HeaderParsing):
//                            
//                            appendDataQueue.addOperationWithBlock {
//                            
//                                //print("SENDING TO HEADER PARSER: \(foundString)")
//                                self.parseHeaderData(foundString)
//                            }
//                            break
//                            
//                        case(.MessageParsing):
//                            appendDataQueue.addOperationWithBlock {
//                                self.parseMessageData(foundString)
//                            }
//                            break
//                            
//                        default:
//                            break
//                        }
                        
                        print("---------> \(foundString)")
                        
                        appendDataQueue.addOperationWithBlock {
                            self.consumeQueueItem(fromList: foundString)
                        }
                        
                        let distanceToAdvance = 4 + (foundString.characters.count as String.Index.Distance) //+1 for the '+'
                        distance += distanceToAdvance
                        
                    } //else { print("Did not convert string") }
                } //else { print("Did not find message") }
            }
        }
    }
}

internal extension ReceiveStreamHandler {
    
    enum ParsingErrors: Int {
        case InvalidHeaders = -128
        case InvalidResponceCode
    }
    
    func consumeQueueItem(fromList item: String!) {
        
        print("Storing string of length \(item.characters.count)")
        
        store.append(item)
    }
    
    func parseHeaderData(headers: String) {
    
        var headerDict = Dictionary<String, String>(minimumCapacity: 4)
        
        let headerArray : [String] = headers.componentsSeparatedByString(String(data: HTTPLineEnd, encoding: NSUTF8StringEncoding)!)
        let HTTPStatus = headerArray[0]
        
        if(HTTPStatus == "HTTP/1.1 200 OK")
        {
            for field in headerArray.suffixFrom(1) {
                let fieldArray : [String] = field.componentsSeparatedByString(":")
                headerDict[fieldArray[0]] = fieldArray[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            }
            
            self.headers = headerDict //copy to let
            //print("Headers: \(self.headers!)")
            
            if( self.headers!["Connection"] == Connection.KeepAlive.rawValue &&
                self.headers!["Content-Type"] == ContentType.TextEventStream.rawValue &&
                self.headers!["Transfer-Encoding"] == TransferEncoding.Chunked.rawValue) {
                    self.stateMachine.state = .MessageParsing
            }
            else {
                self.stateMachine.state = .Error(NSError(domain: StreamHandlerErrorDomain, code: ParsingErrors.InvalidHeaders.rawValue, userInfo: ["headers":headers]))
            }
            
            
        }
        else {
            self.stateMachine.state = .Error(NSError(domain: StreamHandlerErrorDomain, code: ParsingErrors.InvalidResponceCode.rawValue, userInfo: ["headers":headers]))
        }
    }
    
    func parseMessageData(message: String) {
        
        let messageArray : [String] = message.componentsSeparatedByString(String(data: HTTPLineEnd, encoding: NSUTF8StringEncoding)!)
        
        if(messageArray.count == 2) {
        
            let messageLength : Int! = Int(messageArray[0], radix: 16)
        
            print("Message: \(messageLength) -> |\(messageArray[1])|")
        }
        else {
            print("Invalid chunk.")
        }
        //Error if message length does not equal `messageLength`
    }
}

// MARK: Drain data container
internal class StreamedDataContainer {
    
    private var internalStringStorage = String()
    
    init() {
        
    }
    
    var startIndex: String.Index {
        get {
            return internalStringStorage.startIndex
        }
    }
    
    var endIndex: String.Index {
        get {
            return internalStringStorage.endIndex
        }
    }
    
    func append(data: [UInt8], length: Int) {
        
        let data = NSData(bytes: data, length: length)
    
        if let string = String(data: data, encoding: NSUTF8StringEncoding) {
            self.append(string)
        }
    }
    
    func append(data: String) {
        
        internalStringStorage += data //TODO: Thread safe?
        
        //print("------------\n\(data)\n------------")
    }
    
    var length: Int {
        
        get {
            return internalStringStorage.characters.count
        }
    }
    
    func chunk(fromIndex index: String.Index) -> String {
        
        let range = Range<String.Index>(start: index, end: internalStringStorage.endIndex)
        
        //print("\tchunk :: \(range) -> internalStringStorage")
        
        return internalStringStorage.substringWithRange(range)
    }
    
    func trim(fromIndex index: String.Index) {
        
        let trimmedString = chunk(fromIndex: index)
        internalStringStorage = trimmedString
    }
}