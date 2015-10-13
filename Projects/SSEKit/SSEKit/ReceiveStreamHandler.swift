//
//  ReceiveStreamHandler.swift
//  SSEKit
//
//  Created by Richard Stelling on 12/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation
import State

internal class ReceiveStreamHandler : StreamHandler, StateDelegate, NSStreamDelegate {
    
    var totalBytesRead = 0
    var buffer : NSMutableData!
    
    let initialBufferSize = 4096
    let maxReadSize = 512 //2048
    
    private lazy var stateMachine : State<ReceiveStreamHandler> = State<ReceiveStreamHandler>(initialState: ReadSocketState.Idle, delegate: self)

    let HTTPLineEnd = NSData(bytes: [0x0D, 0x0A] as [UInt8], length: 2)
    let HTTPBlankLine = NSData(bytes: [0x0D, 0x0A, 0x0D, 0x0A] as [UInt8], length: 4)
    
    private var lastSequanceOffset = 0
    internal var headers : Dictionary<String, String>?
    
    var workingLocation : Int = 0
    
    let operationQueue = NSOperationQueue(qualityOfService: .Utility, maxConcurrentOperationCount: 1)
    
    override init(delegate: HTTPStreamHandlerDelegate) {
        
        buffer = NSMutableData(capacity: initialBufferSize)
        
        super.init(delegate: delegate)
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        let myStream = aStream as! NSInputStream
        
        if eventCode == NSStreamEvent.HasBytesAvailable {
            let bytesRead = readBuffer(myStream, readSize: maxReadSize)
            totalBytesRead += bytesRead
            
            self.delegate.bytesReceived(bytesRead) //TODO: move to background queue?
        }
        
        switch(eventCode, stateMachine.state) {
        
        case(NSStreamEvent.OpenCompleted, .Idle):
            self.stateMachine.state = .HeaderParsing
            break
            
        case(NSStreamEvent.HasBytesAvailable, .HeaderParsing):
            
            let workingData = buffer.copy() as! NSData
            
            let operation = NSBlockOperation {
                
                self.scanData(workingData, block: { (data) in
                    self.parseHeaderData(data)
                })
                
//                var workingRange = NSMakeRange(self.workingLocation, 0)
//                var sequenceRange : NSRange = NSMakeRange(NSNotFound, 0)
//                
//                repeat {
//                    workingRange.length += 32 //TODO: is this optimum for headers?
//                    
//                    if NSMaxRange(workingRange) > workingData.length {
//                        sequenceRange = NSMakeRange(NSNotFound, 0)
//                        break
//                    }
//                    sequenceRange = workingData.rangeOfData(self.HTTPBlankLine, options: NSDataSearchOptions(rawValue: 0), range:workingRange)
//                } while NSEqualRanges(sequenceRange, NSMakeRange(NSNotFound, 0))
//
//                if(!NSEqualRanges(sequenceRange, NSMakeRange(NSNotFound, 0))) { //if we have a valid range for all headers
//                
//                    //1. Copy teh header data for processing later
//                    let headerData = workingData.subdataWithRange(NSMakeRange(self.workingLocation, sequenceRange.location))
//                    
//                    //2. Set the workingLocation in the main buffer to the end of the header feilds
//                    self.workingLocation = NSMaxRange(sequenceRange)
//                    
//                    //3. Process headers
//                    self.parseHeaderData(headerData)
//                }
            }
            
            operationQueue.addOperations([operation], waitUntilFinished: true)
            
            break
            
        case(NSStreamEvent.HasBytesAvailable, .MessageParsing):
            
            let workingData = buffer.copy() as! NSData
            
            let operation = NSBlockOperation {
                
                self.scanData(workingData, block: { (data) in
                    self.parseMessageData(data)
                })
            }
            
            operationQueue.addOperations([operation], waitUntilFinished: true)
            
//            let bytesRead = readBuffer(myStream, readSize: maxReadSize)
//            totalBytesRead += bytesRead
//            
//            self.delegate.bytesReceived(bytesRead)
//            
//            let searchRange = NSMakeRange(self.lastSequanceOffset, (self.buffer.length - self.lastSequanceOffset))
//            let bufferSnapShot = buffer.copy()
//            let offsetSnapShot = lastSequanceOffset
//            
//            let operation = NSBlockOperation {
//                
//                let sequenceRange = bufferSnapShot.rangeOfData(self.HTTPBlankLine, options: NSDataSearchOptions(rawValue: 0), range:searchRange)
//                
//                if !NSEqualRanges(sequenceRange, NSMakeRange(NSNotFound, 0)) { //End of SSE message
//                    let sequenceData = bufferSnapShot.subdataWithRange(NSMakeRange(offsetSnapShot, sequenceRange.location-offsetSnapShot))
//                    self.lastSequanceOffset = sequenceRange.location + sequenceRange.length
//                    
//                    self.parseMessageData(sequenceData)
//                }
//            }
//            
//            operationQueue.addOperations([operation], waitUntilFinished: true)
            
            break
            
        case(NSStreamEvent.EndEncountered, _):
            let message = String(data: self.buffer, encoding: NSUTF8StringEncoding)!
            print("*********************\n\(message)\n*********************")
            connectionEnded()
            break
            
        default:
            break
        }
    }
    
    func readBuffer(stream: NSInputStream, readSize: Int) -> Int {
        var buf = [UInt8](count: readSize, repeatedValue: 0)
        let readBytes = stream.read(&buf, maxLength: readSize)
        buffer.appendBytes(&buf, length: readBytes)
        //bytesRead += readBytes
        
        return readBytes
    }
    
    func scanData(workingData: NSData, block: (data: NSData) -> Void) {
        
        var workingRange = NSMakeRange(self.workingLocation, 0)
        var sequenceRange : NSRange = NSMakeRange(NSNotFound, 0)
        
        repeat {
            workingRange.length += 32 //TODO: is this optimum for headers?
            
            if NSMaxRange(workingRange) > workingData.length {
                sequenceRange = NSMakeRange(NSNotFound, 0)
                break
            }
            sequenceRange = workingData.rangeOfData(self.HTTPBlankLine, options: NSDataSearchOptions(rawValue: 0), range:workingRange)
        } while NSEqualRanges(sequenceRange, NSMakeRange(NSNotFound, 0))
        
        if(!NSEqualRanges(sequenceRange, NSMakeRange(NSNotFound, 0))) { //if we have a valid range for all headers
            
            //1. Copy the header data for processing later
            let dataRange = NSMakeRange(workingRange.location, sequenceRange.location-workingRange.location)
            print("dataRange: \(dataRange)")
            let data = workingData.subdataWithRange(dataRange)
            
            //2. Set the workingLocation in the main buffer to the end of the header feilds
            self.workingLocation = NSMaxRange(sequenceRange)
            
            //3. Pass data back to block
            block(data: data)
            //self.parseHeaderData(headerData)
        }
        else {
            print("Working Range: \(workingRange)")
            print("SEQ Range: \(sequenceRange)")
        }
        
    }
    
    func parseHeaderData(headerData: NSData) {
        
        let headers = String(data: headerData, encoding: NSUTF8StringEncoding)!
        
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
            print("Headers: \(self.headers!)")
            
            if( self.headers!["Connection"] == Connection.KeepAlive.rawValue &&
                self.headers!["Content-Type"] == ContentType.TextEventStream.rawValue &&
                self.headers!["Transfer-Encoding"] == TransferEncoding.Chunked.rawValue) {
                self.stateMachine.state = .MessageParsing
            }
            else {
                self.stateMachine.state = .Error(nil)
            }
            
            
        } else {
            self.stateMachine.state = .Error(nil)
        }
    }
    
    func parseMessageData(headerData: NSData) {
        
        let message = String(data: headerData, encoding: NSUTF8StringEncoding)!
        
        let messageArray : [String] = message.componentsSeparatedByString(String(data: HTTPLineEnd, encoding: NSUTF8StringEncoding)!)
        let messageLength : Int! = Int(messageArray[0], radix: 16)

        print("Message: \(messageLength) -> |\(messageArray[1])|")
        
        //Error if message length does not equal `messageLength`
    }
    
    func connectionEnded() {
        
        drainBuffer()
        
        self.stateMachine.state = .ConnectionClosed
        
        print("Connection was ended.")
    }
    
    func drainBuffer() {
        
        print("// +*+*+*+*+ //")
        
        if workingLocation < buffer.length {
            
            scanData(buffer, block: { (data) -> Void in
                self.parseMessageData(data)
                
                self.drainBuffer()
            })
            
        }
    }
    
    // MARK: StateDelegate
    
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
            break;
            
        default:
            return
        }
    }
    
    func failedTransitionFrom(from:StateType, to:StateType) {
        
    }
}

extension NSOperationQueue {
    
    convenience init(qualityOfService: NSQualityOfService, maxConcurrentOperationCount: Int = 1) {
        self.init()
        
        self.qualityOfService = qualityOfService
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
    
}