import Foundation

internal enum PollResult : BooleanType {
    case Success, Failure, Timeout

    var boolValue : Bool {
        return self == .Success
    }
}

internal class RunPromise {
    var token: dispatch_once_t = 0
    var didFinish = false
    var didFail = false

    init() {}

    func succeed() {
        dispatch_once(&self.token) {
            self.didFinish = false
        }
    }

    func fail(block: () -> Void) {
        dispatch_once(&self.token) {
            self.didFail = true
            block()
        }
    }
}

internal func stopRunLoop(runLoop: NSRunLoop, delay: NSTimeInterval) -> RunPromise {
    var promise = RunPromise()
    var killQueue = dispatch_queue_create("nimble.waitUntil.queue", DISPATCH_QUEUE_SERIAL)
    let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
    let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
    dispatch_after(killTime, killQueue) {
        promise.fail {
            CFRunLoopStop(runLoop.getCFRunLoop())
        }
    }
    return promise
}

internal func pollBlock(#pollInterval: NSTimeInterval, #timeoutInterval: NSTimeInterval, expression: () -> Bool) -> PollResult {
    let runLoop = NSRunLoop.mainRunLoop()

    var promise = stopRunLoop(runLoop, min(timeoutInterval, 0.2))

    let startDate = NSDate()

    // trigger run loop to make sure enqueued tasks don't block our assertion polling
    // the stop run loop task above will abort us if necessary
    runLoop.runUntilDate(startDate)
    promise.succeed()

    if promise.didFail {
        return .Timeout
    }

    var pass: Bool = false
    do {
        pass = expression()
        if pass {
            break
        }

        let runDate = NSDate().dateByAddingTimeInterval(pollInterval) as NSDate
        runLoop.runUntilDate(runDate)
    } while(NSDate().timeIntervalSinceDate(startDate) < timeoutInterval);

    return pass ? .Success : .Failure
}
