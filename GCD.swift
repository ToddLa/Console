//
//  GCD.swift
//  SwiftTool
//
//  Created by Todd Laney on 6/8/16.
//  Copyright © 2016 Todd Laney. All rights reserved.
//

import Darwin
import Dispatch

typealias dispatch_block_t = () -> Void

private var active_sources = [DispatchSourceProtocol]()  // keep ref to source to keep alive via ARC
private var signals = [Int32:(queue:DispatchQueue,handler:dispatch_block_t)]()

func dispatch_signal(_ sig:Int32, queue:DispatchQueue = DispatchQueue.main, handler:@escaping dispatch_block_t) {
    // hack for SIGINT, dispatch_source does not appear to support it.
    // Bug ID 26810149
    if sig < NSIG {
        signals[sig] = (queue, handler)
        signal(sig) {code in
            if let signal = signals[code] {
                (signal.queue).async(execute: signal.handler)
            }
        }
    }
    else {
        let signal_source = DispatchSource.makeSignalSource(signal:sig, queue:queue)
        signal_source.setEventHandler(handler:handler)
        signal_source.resume()
        active_sources.append(signal_source)
    }
}

func dispatch_timer(start:DispatchTime=DispatchTime.now(),interval:Double,queue:DispatchQueue = DispatchQueue.main,handler:@escaping dispatch_block_t) -> DispatchSourceTimer {
    let timer_source = DispatchSource.makeTimerSource(flags:[], queue:queue)
    timer_source.schedule(deadline:start, repeating:interval)
    timer_source.setEventHandler(handler: handler)
    timer_source.resume()
    active_sources.append(timer_source)
    return timer_source
}
func dispatch_timer_cancel(_ timer_source:DispatchSource) {
    if let idx = active_sources.firstIndex(where: {$0.hash == timer_source.hash}) {
        active_sources.remove(at: idx)
    }
    timer_source.cancel()
}
func dispatch_read(_ fd:Int32, queue:DispatchQueue = DispatchQueue.main, handler:@escaping dispatch_block_t) {
    let read_source = DispatchSource.makeReadSource(fileDescriptor:fd, queue:queue)
    read_source.setEventHandler(handler: handler)
    read_source.resume()
    active_sources.append(read_source)
}

func dispatch_read_cancel(_ fd:Int) {
}
