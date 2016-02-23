//: Playground - noun: a place where people can play

import XCPlayground
import SSEKit

/*
TESTS REQUIRED: Check for 5xx
*/

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

let sseVersion = EventSource.packageVersion
let sse = EventSource(host: "lamp.private", path: "/sse.php", port: 8080)

//let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
//dispatch_after(delayTime, dispatch_get_main_queue()) {
//    var dataIO = sse.dataTransfer()
//    print("Data in: \(dataIO.0)")
//    print("Data out: \(dataIO.1)")
//}

//let del = "/r/r/r"
//let scanner = NSScanner(string: "Hello world\(del)message1\(del)message two!\(del)")
//scanner.charactersToBeSkipped = NSCharacterSet(charactersInString: del)
//var stringBuffer: NSString? = nil
//
//while(!scanner.atEnd) {
//
//    if scanner.scanUpToString(del, intoString: &stringBuffer) {
//        print("Found String: \(stringBuffer!) |")
//    }
//}

/*
            state machine not updating and
*/