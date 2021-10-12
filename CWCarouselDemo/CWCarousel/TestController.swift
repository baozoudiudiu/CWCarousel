//
//  TestController.swift
//  CWCarousel
//
//  Created by 陈旺 on 2021/10/8.
//  Copyright © 2021 ChenWang. All rights reserved.
//

import UIKit

class TestController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .cyan
        
        let width = self.view.frame.size.width
        let height: CGFloat = 400
        
        
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.frame = CGRect(x: 0, y: 100, width: width, height: 400)
        scrollView.backgroundColor = UIColor.white
        self.view.addSubview(scrollView)
        
        var view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        view.backgroundColor = .red
        scrollView.addSubview(view)
        
        view = UIView()
        view.frame = CGRect(x: width, y: 0, width: width, height: height)
        view.backgroundColor = .orange
        scrollView.addSubview(view)
        
        scrollView.contentSize = CGSize(width: width * 2, height: height)
    }
}

extension TestController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("will begin dragging")
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        print("will end dragging")
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("did end dragging")
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        print("will begin decelerating")
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("did end decelerating")
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("did end scrolling animation")
    }
}
