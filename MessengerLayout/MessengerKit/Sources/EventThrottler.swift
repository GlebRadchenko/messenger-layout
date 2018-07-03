//
//  EventThrottler.swift
//  MessengerLayout
//
//  Created by Gleb Radchenko on 7/3/18.
//  Copyright © 2018 Gleb Radchenko. All rights reserved.
//

import Foundation

open class EventThrottler<E> {
    public fileprivate(set) var queue = DispatchQueue(label: "throttle-queue")
    fileprivate var _elements: [E] = []
    
    fileprivate let runningLock = NSLock()
    fileprivate var _isRunning = false
    var isRunning: Bool {
        get {
            runningLock.lock(); defer { runningLock.unlock() }
            let isRunning = _isRunning
            return isRunning
        }
        
        set {
            runningLock.lock()
            _isRunning = newValue
            runningLock.unlock()
        }
    }
    
    fileprivate var timer: Timer!
    fileprivate var lastDispatchTime: TimeInterval = 0
    
    public fileprivate(set) var onDispatch: ([E]) -> Void
    public let threshold: TimeInterval
    public fileprivate(set) var dispatchQueue: DispatchQueue
    
    deinit {
        stopTimer()
    }
    
    public init(threshold: TimeInterval, queue: DispatchQueue = .global(), f: @escaping ([E]) -> Void) {
        self.onDispatch = f
        self.threshold = threshold
        self.dispatchQueue = queue
        
        addTimer()
    }
    
    public func append(_ element: E) {
        append([element])
    }
    
    public func append(_ elements: [E]) {
        queue.sync {
            _elements.append(contentsOf: elements)
        }
        
        launchDispatcherIfNeeded()
    }
    
    fileprivate func addTimer(shouldFire: Bool = false) {
        timer = nil
        DispatchQueue.main.async { [weak self] in
            guard let wSelf = self else { return }
            wSelf.timer = Timer.scheduledTimer(withTimeInterval: wSelf.threshold, repeats: true) { (timer) in
                wSelf.dispatchElements()
                wSelf.lastDispatchTime = Date.timeIntervalSinceReferenceDate
                
                DispatchQueue.global().asyncAfter(deadline: .now() + wSelf.threshold) {
                    wSelf.stopTimerIfNeeded()
                }
            }
            
            if shouldFire { wSelf.timer.fire() }
        }
    }
    
    fileprivate func stopTimerIfNeeded() {
        queue.sync {
            guard _elements.isEmpty else { return }
            stopTimer()
        }
    }
    
    fileprivate func stopTimer() {
        timer?.invalidate()
        isRunning = false
    }
    
    fileprivate func launchDispatcherIfNeeded() {
        guard !isRunning else { return }
        guard let timer = timer else { return }
        
        let currentTime = Date.timeIntervalSinceReferenceDate
        
        if abs(currentTime - lastDispatchTime) >= threshold {
            isRunning = true
            timer.isValid ? timer.fire() : addTimer(shouldFire: true)
        }
    }
    
    fileprivate func dispatchElements() {
        queue.sync {
            guard !_elements.isEmpty else { return }
            
            let elementsToDispatch = _elements
            _elements.removeAll()
            
            dispatchQueue.async { [weak self] in
                guard let wSelf = self else { return }
                wSelf.onDispatch(elementsToDispatch)
            }
        }
    }
}
