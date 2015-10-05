//
//  State.swift
//  SSESwift
//
//  Created by Richard Stelling on 05/10/2015.
//  Copyright © 2015 Naim Audio Ltd. All rights reserved.
//

import Foundation

protocol StateDelegate : class {
    
    typealias StateType
    
    func shouldTransitionFrom(from:StateType, to:StateType) -> Bool
    func didTransitionFrom(from:StateType, to:StateType)
}

class State<P:StateDelegate> : Locking {
    
    private unowned let delegate:P
    
    // MARK: Getting and Setting State
    
    private var _state : P.StateType! {
        
        didSet {
            delegate.didTransitionFrom(oldValue, to:_state)
        }
    }
    
    var state:P.StateType {
        
        get {
            return _state
        }
        
        set {
            synchronise {
                    if self.delegate.shouldTransitionFrom(self._state, to:newValue) {
                        self._state = newValue
                }
            }
        }
    }

    // MARK: Init
    
    init(initialState:P.StateType, delegate:P) {
        
        self.delegate = delegate
        
        synchronise {
            self._state = initialState //set the primitive to avoid calling the delegate.
        }
    }
}