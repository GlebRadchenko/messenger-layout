//
//  Wrappers.swift
//  MessengerLayout
//
//  Created by Gleb Radchenko on 7/3/18.
//  Copyright © 2018 Gleb Radchenko. All rights reserved.
//

import Foundation

public func throttle(delay: TimeInterval, f: @escaping () -> Void) -> () -> Void {
    var timer: Timer?
    var timestamp: TimeInterval = 0
    
    return {
        let execute = {
            f()
            timestamp = Date.timeIntervalSinceReferenceDate
            timer?.invalidate()
            timer = nil
        }
        
        let sinceLastTimestamp = {
            return Date.timeIntervalSinceReferenceDate - timestamp
        }
        
        DispatchQueue.main.async {
            guard timer == nil else { return }
            let past = sinceLastTimestamp()
            
            if past < delay {
                timer = Timer.scheduledTimer(withTimeInterval: delay - past, repeats: false) { _ in execute() }
            } else {
                execute()
            }
        }
    }
}

public func debounce(delay: TimeInterval, f: @escaping () -> Void) -> () -> Void {
    var timer: Timer?
    var timestamp: TimeInterval = 0
    
    return {
        timestamp = Date.timeIntervalSinceReferenceDate
        
        let execute = {
            f()
            timer?.invalidate()
            timer = nil
        }
        
        let sinceLastTimestamp = {
            return Date.timeIntervalSinceReferenceDate - timestamp
        }
        
        let delayed = {
            let past = sinceLastTimestamp()
            if past < delay {
                timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in execute() }
            } else {
                execute()
            }
        }
        
        DispatchQueue.main.async {
            guard timer == nil else { return }
            timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in delayed() }
        }
    }
}
