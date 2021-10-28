//
//  CWProxy.swift
//  CWCarousel
//
//  Created by 陈旺 on 2021/10/28.
//  Copyright © 2021 ChenWang. All rights reserved.
//

import Foundation

class CWProxy<T: AnyObject> {
    
    typealias TimerHandler = (T?) -> Void
    
    private(set) weak var target: T?
    
    fileprivate var handler: TimerHandler?
    
    init(_ target: T?) {
        self.target = target
    }
    
    func createTimer(timeInterval: TimeInterval, _ action: TimerHandler?) -> Timer? {
        self.handler = action
        return Timer.scheduledTimer(timeInterval: timeInterval,
                                    target: self,
                                    selector: #selector(timerAction),
                                    userInfo: nil,
                                    repeats: true)
    }
    
    @objc fileprivate func timerAction() {
        self.handler?(self.target)
    }
}
