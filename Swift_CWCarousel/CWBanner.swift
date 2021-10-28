//
//  CWBanner.swift
//  CWCarousel
//
//  Created by chenwang on 2018/7/18.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

import UIKit

class CWCollectionView: UICollectionView, UIGestureRecognizerDelegate {
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.panGestureRecognizer.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

protocol CWBannerDelegate: AnyObject {
    /// 视图数量
    func bannerNumbers() -> Int
    
    /// 加载cell
    /// - Parameters:
    ///   - banner: 控件对象
    ///   - index: 当前需要加载index
    ///   - indexPath: 当前需要加载indexPath
    func bannerView(banner: CWBanner, index: Int, indexPath: IndexPath) -> UICollectionViewCell
    
    /// 点击
    /// - Parameters:
    ///   - banner: 控件对象
    ///   - index: 触发点击事件的index
    ///   - indexPath: 触发点击事件的indexPath
    func didSelected(banner: CWBanner, index: Int, indexPath: IndexPath)
    
    /// 开始滚动
    /// - Parameters:
    ///   - banner: 控件对象
    ///   - index: 开始时的index
    ///   - indexPath: 开始时的indexPath
    func didStartScroll(banner: CWBanner, index: Int, indexPath: IndexPath)
    
    /// 结束滚动
    /// - Parameters:
    ///   - banner: 控件对象
    ///   - index: 结束后居中的index
    ///   - indexPath: 居中后结束的indexPath
    func didEndScroll(banner: CWBanner, index: Int, indexPath: IndexPath)
}

protocol CWBannerPageControl where Self: UIView {
    /// 当前下标
    var currentPage: Int? {set get}
    /// 总数
    var numberOfPages: Int? {get set}
    /// 自定义pageControl被添加到控件上后会调此方法, 在这里可以设置pageControl的布局
    func setupLayoutWhenMoveToBannerView(_ banner: CWBanner) -> Void
}

class CWBanner: UIView {
    //MARK: - 构造方法
    init(frame: CGRect, flowLayout: CWSwiftFlowLayout, delegate: CWBannerDelegate) {
        self.flowLayout = flowLayout
        self.delegate = delegate
        super.init(frame: frame)
        self.configureBanner()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.resumePlay()
    }
    
    deinit {
        NSLog("[%@ -- %@]",NSStringFromClass(self.classForCoder), #function);
        self.releaseTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.flowLayout = CWSwiftFlowLayout.init(style: .unknown)
        super.init(coder: aDecoder)
    }
    
    //MARK: - Property
    fileprivate lazy var proxy: CWProxy<CWBanner> = {
        let p = CWProxy<CWBanner>(self)
        return p
    }()
    /// 是否展示PageControl 默认:true
    var showPageControl = true
    /// 没有数据时的占位图
    let emptyImgView = UIImageView.init(frame: CGRect.zero)
    /// 自定义layout
    let flowLayout: CWSwiftFlowLayout
    /// collectionView
    lazy var banner: UICollectionView = {
        let b = CWCollectionView.init(frame: CGRect.zero, collectionViewLayout: self.flowLayout)
        b.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(b)
        self.sendSubviewToBack(b)
        b.delegate = self
        b.dataSource = self
        b.showsHorizontalScrollIndicator = false
        b.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0)
        b.backgroundColor = self.backgroundColor
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|",
                                                           options: [],
                                                           metrics: nil,
                                                           views: ["view" : b]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|",
                                                           options: [],
                                                           metrics: nil,
                                                           views: ["view" : b]))
        b.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "tempCell")
        self.addSubview(self.emptyImgView)
        self.emptyImgView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[empty]|", options: [], metrics: nil, views: ["empty":emptyImgView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[empty]|", options: [], metrics: nil, views: ["empty":emptyImgView]))
        return b
    }()
    /// 外部代理委托
    weak var delegate: CWBannerDelegate?
    /// 当前居中展示的cell的下标
    var currentIndexPath: IndexPath = IndexPath.init(row: 0, section: 0) {
        didSet {
            let current = self.caculateIndex(indexPath: self.currentIndexPath)
            self.currentIndex = current
            if self.customPageControl == nil {
                self.pageControl.currentPage = current
                return
            }
            self.customPageControl?.currentPage = current
        }
    }
    fileprivate var currentIndex: Int = 0
    /// 是否开启自动滚动 (默认是关闭的)
    var autoPlay = false
    /// 定时器
    var timer: Timer?
    /// 自动滚动时间间隔,默认3s
    var timeInterval: TimeInterval = 3.0
    /// 默认的pageControl (默认位置在中下方,需要调整位置请自行设置frame)
    lazy var pageControl: UIPageControl = {
        let count = self.delegate?.bannerNumbers()
        let width = CGFloat(5) * CGFloat((count ?? 0))
        let height: CGFloat = 10
        let pageControl = UIPageControl.init(frame: CGRect.init(x: 0, y: 0, width: width, height: height))
        pageControl.center = CGPoint.init(x: self.bounds.width * 0.5, y: self.bounds.height - height * 0.5 - 8)
        pageControl.currentPage = 0
        pageControl.numberOfPages = self.delegate?.bannerNumbers() ?? 0
        pageControl.pageIndicatorTintColor = UIColor.white
        pageControl.isUserInteractionEnabled = false;
        pageControl.currentPageIndicatorTintColor = UIColor.black
        pageControl.translatesAutoresizingMaskIntoConstraints = false;
        return pageControl
    }()
    /// 自定义的pageControl
    var customPageControl: CWBannerPageControl? {
        willSet
        {
            guard let custom = newValue else {return}
            guard custom.superview == nil else {return}
            self.addSubview(custom);
            self.bringSubviewToFront(custom);
            self.pageControl.removeFromSuperview();
            newValue?.setupLayoutWhenMoveToBannerView(self)
            newValue?.numberOfPages = self.numbers
            newValue?.currentPage = self.currentIndex
        }
    }
    
    /// 控件版本号
    var version: String {
        get{
            return "1.1.9";
        }
    }
    
    /// 是否无限轮播 true:无限衔接下去; false: 到最后一张后就没有了
    var endless: Bool = true
}

// MARK: - OPEN METHOD
extension CWBanner {
    /// 刷新数据
    func freshBanner() {
        self.stop()
        self.banner.reloadData()
        self.banner.layoutIfNeeded()
        self.scrollToIndexPathNoAnimated(self.originIndexPath())
        self.play()
        if self.customPageControl != nil {
            self.customPageControl?.numberOfPages = self.delegate?.bannerNumbers() ?? 0
            self.customPageControl?.currentPage = 0
            return
        }
        self.pageControl.numberOfPages = self.delegate?.bannerNumbers() ?? 0
        self.pageControl.currentPage = 0
    }
    
    fileprivate func play() {
        guard self.numbers > 1 && self.autoPlay else {
            self.releaseTimer()
            return
        }
        
        guard self.timer == nil else {
            return
        }
        
        defer { self.timer?.fireDate = Date.init(timeIntervalSinceNow: self.timeInterval) }
        
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: self.timeInterval, repeats: true, block: { [weak self] (timer) in
                self?.nextCell()
            })
            return
        }
        
        self.timer = self.proxy.createTimer(timeInterval: self.timeInterval, { t in
            t?.nextCell()
        })
    }
    
    @objc fileprivate func nextCell() {
        
        defer {
            self.scrollViewWillBeginDecelerating(self.banner)
        }
        
        if self.endless {
            self.currentIndexPath = self.currentIndexPath + 1;
            return
        }
        
        let lastIndex = self.flowLayout.style == .normal ? self.numbers - 1 : self.factNumbers - 2
        
        if self.currentIndexPath.row == lastIndex {
            let row = self.flowLayout.style == .normal ? 0 : 1
            self.currentIndexPath = IndexPath.init(row: row, section: 0)
            return
        }
        self.currentIndexPath = self.currentIndexPath + 1
    }
    
    /// 继续滚动轮播图
    func resumePlay() {
        self.play()
    }
    
    /// 暂停自动滚动
    func pause() {
        if let timer = self.timer {
            timer.fireDate = Date.distantFuture
        }
    }
    
    /// 停止滚动
    func stop() {
        self.pause()
    }
    
    /// 释放timer资源,防止内存泄漏
    fileprivate func releaseTimer() {
        guard let timer = self.timer else {
            return
        }
        timer.fireDate = Date.distantFuture
        timer.invalidate()
        self.timer = nil
    }
    
    /// banner所处控制器WillAppear方法中调用
    func bannerWillAppear() {
        self.play()
        self.adjustErrorCell(isScroll: true, animation: false)
    }
    
    /// banner所处控制器WillDisAppear方法中调用
    func bannerWillDisAppear() {
        self.pause()
        self.adjustErrorCell(isScroll: true, animation: false)
    }
    
    func scroll(to index: Int, animated: Bool = true) {
        let numbers = self.numbers
        
        guard numbers >= 0 && index < numbers else {
            return
        }
        
        guard index != self.currentIndex else {
            return
        }
        
        self.currentIndexPath = self.currentIndexPath + (index - self.currentIndex)
        if (animated) {
            self.scrollToIndexPathAnimated(self.currentIndexPath)
            return
        }
        self.scrollToIndexPathNoAnimated(self.currentIndexPath)
    }
}

// MARK: - LOGIC HELPER
extension CWBanner {
    /// 代码层下标换算成业务层下标
    ///
    /// - Parameter IndexPath: 代码层cell对应的下标
    /// - Returns: 业务层对应的下标
    fileprivate func caculateIndex(indexPath: IndexPath) -> Int {
        guard self.numbers > 0 else {
            return 0
        }
        var row = indexPath.row % self.numbers
        if self.endless == false, self.flowLayout.style != .normal {
            row = indexPath.row % self.factNumbers - 1
        }
        return row
    }
    
    /// 第一次加载时,会从中间开始展示
    ///
    /// - Returns: 返回对应的indexPath
    fileprivate func originIndexPath() -> IndexPath {
        
        let numbers = self.numbers
        
        guard numbers > 0 else {
            return IndexPath.init(index: 0)
        }
        
        guard endless else {
            let row = self.flowLayout.style == .normal ? 0 : 1
            self.currentIndexPath = IndexPath.init(row: row, section: 0)
            return self.currentIndexPath
        }
        
        let centerIndex = self.factNumbers / numbers
        self.currentIndexPath = centerIndex == 1 ? IndexPath.init(row: 0, section: 0) : IndexPath.init(row: centerIndex / 2 * numbers, section: 0)
        
        return self.currentIndexPath
    }

    /// 边缘检测, 如果将要滑到边缘,调整位置
    fileprivate func checkOutOfBounds() {
        let row = self.currentIndexPath.row
        if row == self.factNumbers - 2
            || row == 1 {
            let originIndexPath = self.originIndexPath()
            var index = self.caculateIndex(indexPath: self.currentIndexPath)
            index = row == 1 ? index + 1 : index - 2
            self.currentIndexPath = originIndexPath + index
            self.scrollToIndexPathNoAnimated(self.currentIndexPath)
        }
    }
    
    fileprivate func scrollToIndexPathAnimated(_ indexPath: IndexPath) {
        guard self.numbers > 0 else {
            return
        }
        self.banner.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    fileprivate func scrollToIndexPathNoAnimated(_ indexPath: IndexPath) {
        guard self.numbers > 0 else {
            return
        }
        self.banner.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        self.delegate?.didEndScroll(banner: self, index: self.currentIndex, indexPath: self.currentIndexPath)
    }
    
    /// cell错位检测和调整
    func adjustErrorCell(isScroll: Bool, animation: Bool = true) {
        let indexPaths = self.banner.indexPathsForVisibleItems
        let centerX: CGFloat = self.banner.contentOffset.x + self.banner.frame.width * 0.5
        var minSpace = CGFloat(MAXFLOAT)
        var newIndexPath: IndexPath = self.currentIndexPath
        indexPaths.forEach({ (idx) in
            if let atr = self.banner.layoutAttributesForItem(at: idx) {
                atr.zIndex = 0
                let diff = abs(atr.center.x - centerX)
                if abs(minSpace) > diff {
                    minSpace = diff
                    newIndexPath = atr.indexPath
                }
            }
        })
        /// 正常情况下 newIndexPath 和 currentIndexPath 不会相差超过 2, 如果超过4明显不正常,就不做处理
        if abs(newIndexPath.row - self.currentIndexPath.row) < 4 {
            self.currentIndexPath = newIndexPath
        }
        
        if isScroll {
            self.cw_scrollViewWillBeginDecelerating(self.banner, animation: animation)
        }
    }
    
    @objc fileprivate func appActive(_ notify: Notification) {
        self.adjustErrorCell(isScroll: true, animation: false)
        self.play()
    }
    
    @objc fileprivate func appInactive(_ notify: Notification) {
        self.pause()
        self.adjustErrorCell(isScroll: true, animation: false)
    }
}

// MARK: - UI
extension CWBanner {
    fileprivate func configureBanner() {
        
        if self.customPageControl == nil {
            self.addSubview(self.pageControl)
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[control]-0-|",
                                                               options: [],
                                                               metrics: nil,
                                                               views: ["control" : self.pageControl]))
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[control(30)]-0-|",
                                                               options: [],
                                                               metrics: nil,
                                                               views: ["control" : self.pageControl]))
        }else {
            self.addSubview(self.customPageControl!)
            
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appActive(_:)), name: UIApplication.didBecomeActiveNotification ,
                                               object:nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appInactive(_:)),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }
}

// MARK: - UIScrollViewDelegate
extension CWBanner {
    
    /// 开始拖拽
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 14.0, *) {
            self.banner.isPagingEnabled = false
        } else {
            self.banner.isPagingEnabled = true
        }
       
        self.pause()
        self.delegate?.didStartScroll(banner: self,
                                      index: self.currentIndex,
                                      indexPath: self.currentIndexPath)
    }
    
    /// 将要结束拖拽
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if (self.endless == false) {
            
            var maxIndex = self.numbers - 1
            var minIndex = 0
            
            if self.flowLayout.style != .normal {
                maxIndex = self.factNumbers - 2
                minIndex = 1
            }
            
            if velocity.x >= 0 && self.currentIndexPath.row == maxIndex {
                self.adjustErrorCell(isScroll: true)
                return
            }
            
            if velocity.x <= 0 && self.currentIndexPath.row == minIndex {
                self.adjustErrorCell(isScroll: true)
                return
            }
        }
        
        // 这里不用考虑越界问题,其他地方做了保护
        if velocity.x > 0 {
            //左滑,下一张
            self.currentIndexPath = self.currentIndexPath + 1
        }else if velocity.x < 0 {
            //右滑, 上一张
            self.currentIndexPath = self.currentIndexPath - 1
        }else if velocity.x == 0 {
            self.adjustErrorCell(isScroll: false)
            if #available(iOS 14.0, *) {
                self.scrollViewWillBeginDecelerating(self.banner);
            }
        }
    }
    
    /// 将要开始减速
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.cw_scrollViewWillBeginDecelerating(scrollView, animation: true)
    }
    
    func cw_scrollViewWillBeginDecelerating(_ scrollView: UIScrollView, animation: Bool = true) {
        
        let factNumbers = self.factNumbers
        
        guard self.currentIndexPath.row >= 0,
            self.currentIndexPath.row < factNumbers else {
            // 越界保护
            return
        }
        
        if self.endless == false {
            if self.currentIndexPath.row == 0 && self.flowLayout.style != .normal {
                self.currentIndexPath = IndexPath.init(row: 1, section: 0)
            } else if self.currentIndexPath.row == factNumbers - 1 && self.flowLayout.style != .normal {
                self.currentIndexPath = IndexPath.init(row: factNumbers - 2, section: 0)
            }
        }
        
        // 在这里将需要显示的cell置为居中
        if animation {
            self.scrollToIndexPathAnimated(self.currentIndexPath)
            return
        }
        
        self.scrollToIndexPathNoAnimated(self.currentIndexPath)
    }
    
    /// 结束减速
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.banner.isPagingEnabled = false
    }
    
    /// 滚动动画完成
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.banner.isPagingEnabled = false
        if self.endless {
            self.checkOutOfBounds()
        }
        self.resumePlay()
        self.delegate?.didEndScroll(banner: self,
                                    index: self.caculateIndex(indexPath: self.currentIndexPath),
                                    indexPath: self.currentIndexPath)
    }
    
    /// 滚动中
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
}

 // MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension CWBanner: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        func dequeueCell(_ idxPath: IndexPath) -> UICollectionViewCell {
            return self.delegate?.bannerView(banner: self,
                                             index: self.caculateIndex(indexPath: idxPath),
                                             indexPath: idxPath) ?? UICollectionViewCell()
        }
        
        if self.endless == false,
           self.flowLayout.style != .normal,
           indexPath.row == 0 || indexPath.row == self.factNumbers - 1 {
            
            return collectionView.dequeueReusableCell(withReuseIdentifier: "tempCell", for: indexPath)
        }
        
        return dequeueCell(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.factNumbers
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if self.endless == false,
           self.flowLayout.style != .normal,
           indexPath.row == 0 || indexPath.row == self.factNumbers - 1 {
            // 非无限轮播情况下, 第一个和最后一个是占位cell, 不参与外部的业务逻辑
            return
        }
        
        self.delegate?.didSelected(banner: self,
                                   index: self.caculateIndex(indexPath: indexPath),
                                   indexPath: indexPath)
        // 处于动画中时,点击cell,可能会出现cell不居中问题.这里处理下
        // 将里中心点最近的那个cell居
        self.adjustErrorCell(isScroll: true)
    }
}

// MARK: - Category
extension CWBanner {
    /// 背地里实际返回的cell个数
    fileprivate var factNumbers: Int {
            
        let numbers = self.numbers
        
        guard numbers > 0 else {
            return 0;
        }
            
        func setPagecontrol(isHidden: Bool) {
            self.pageControl.isHidden = isHidden
            self.customPageControl?.isHidden = isHidden
        }
        
        self.banner.isScrollEnabled = numbers > 1
        setPagecontrol(isHidden: !self.showPageControl || numbers == 1)
        
        if endless {
            return numbers == 1 ? numbers : 100
        }
        
        return self.flowLayout.style == .normal ? numbers : numbers + 2
    }
    
    /// 业务层实际需要展示的cell个数
    fileprivate var numbers: Int {
        let count = self.delegate?.bannerNumbers() ?? 0
        self.emptyImgView.isHidden = count <= 0
        return count > 0 ? count : 0
    }
}

extension IndexPath {
    /// 重载 + 号运算符
    static func + (left: IndexPath, right: Int) -> IndexPath {
        return IndexPath.init(row: left.row + right, section: left.section)
    }
    
    /// 重载 - 号运算符
    static func - (left: IndexPath, right: Int) -> IndexPath {
        return IndexPath.init(row: left.row - right, section: left.section)
    }
}
