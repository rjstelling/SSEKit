//
//  Locking.swift
//  SSESwift
//
//  Created by Richard Stelling on 05/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation

protocol Locking : class {
    
    var lockingQueueName : String { get }
    
    func synchronise(f: Void -> Void)
}

extension Locking {
    
    var lockingQueueName : String {
        
        get {
            
            var myObjectName = _stdlib_getDemangledTypeName(self).lowercaseString
            myObjectName.appendContentsOf(".queue")
            return myObjectName
        }
    }
    
    private var queue : dispatch_queue_t? {
        
        get {
            return dispatch_queue_create(lockingQueueName, nil)
        }
    }
    
    func synchronize(f: Void -> Void) {
        synchronise(f)
    }
    
    func synchronise(f: Void -> Void) {
        dispatch_sync(queue!, f)
    }
}
