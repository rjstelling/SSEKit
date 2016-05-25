//: Playground - noun: a place where people can play

import UIKit
import SSEKit
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

print("SSEKit: \(NSDate())")

let config = EventSourceConfiguration(withHost: "192.168.103.36", port: 15081, endpoint: "/notify", timeout: 300, events: nil)
let manager = SSEManager(sources: [config])


