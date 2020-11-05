//
//  CWBanner.swift
//  CWCarousel
//
//  Created by chenwang on 2018/7/18.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

import UIKit

protocol CWBannerDelegate: AnyObject {
    func bannerNumbers() -> Int
    func bannerView(banner: CWBanner, index: Int, indexPath: IndexPath) -> UICollectionViewCell
    func didSelected(banner: CWBanner, index: Int, indexPath: IndexPath)
    func didStartScroll(banner: CWBanner, index: Int, indexPath: IndexPath)
    func didEndScroll(banner: CWBanner, index: Int, indexPath: IndexPath)
}

protocol CWBannerPageControl where Self: UIView {
    /// 当前下标
    var currentPage: Int? {set get}
    /// 总数
    var numberOfPages: Int? {get set}
    /// 设置当前下标,可以在这里处理一些动画效果
    func setCurrentPage(_ page: Int) -> Void
    /// 设置总数,可以在这里处理视图的创建
    func setNumberOfPages(_ number: Int) -> Void
}

class CWBanner: UIView {
    //MARK: - 构造方法
    init(frame: CGRect, flowLayout: CWSwiftFlowLayout, delegate: CWBannerDelegate) {
        self.flowLayout = flowLayout
        self.delegate = delegate
        var rect = frame
        rect.size.height = frame.height + flowLayout.addHeight(frame.height)
        super.init(frame: rect)
        self.configureBanner()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.autoPlay
        {
            self.resumePlay()
        }
    }
    
    deinit {
        NSLog("[%@ -- %@]",NSStringFromClass(self.classForCoder), #function);
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.flowLayout = CWSwiftFlowLayout.init(style: .unknown)
        super.init(coder: aDecoder)
    }
    
    //MARK: - Property
    /// 自定义layout
    let flowLayout: CWSwiftFlowLayout
    /// collectionView
    lazy var banner: UICollectionView = {
//        let rect = self.bounds
        let b = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: self.flowLayout)
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
        return b
    }()
    /// 外部代理委托
    weak var delegate: CWBannerDelegate?
    /// 当前居中展示的cell的下标
    var currentIndexPath: IndexPath = IndexPath.init(row: 0, section: 0) {
        didSet {
            let current = self.caculateIndex(indexPath: self.currentIndexPath)
            if self.customPageControl == nil {
                self.pageControl.currentPage = current
            }else {
                self.customPageControl?.setCurrentPage(current)
            }
        }
    }
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
            if let custom = newValue
            {
                if custom.superview == nil
                {
                    self.addSubview(custom);
                    self.bringSubviewToFront(custom);
                    self.pageControl.removeFromSuperview();
                }
            }
        }
    }
    
    /// 控件版本号
    var version: String {
        get{
            return "1.1.7";
        }
    }
    
    /// 是否无限轮播 true:无限衔接下去; false: 到最后一张后就没有了
    var endless: Bool = true
}

// MARK: - OPEN METHOD
extension CWBanner {
    /// 刷新数据
    func freshBanner() {
        self.banner.reloadData()
        self.banner.layoutIfNeeded()
        self.scrollToIndexPathNoAnimated(self.originIndexPath())
        if self.autoPlay {
            self.play()
        }
    }
    
    fileprivate func play() {
        if self.timer == nil {
            if #available(iOS 10.0, *) {
                self.timer = Timer.scheduledTimer(withTimeInterval: self.timeInterval, repeats: true, block: {[weak self] (timer) in
                    self?.nextCell()
                })
            } else {
                self.timer = Timer.scheduledTimer(timeInterval: self.timeInterval, target: self, selector: #selector(nextCell), userInfo: nil, repeats: true)
            }
        }
        self.timer?.fireDate = Date.init(timeIntervalSinceNow: self.timeInterval)
    }
    
    @objc fileprivate func nextCell() {
        if self.endless
        {
            // 这里不用考虑下标越界的问题,其他地方做了保护
            self.currentIndexPath = self.currentIndexPath + 1;
        }
        else
        {
            let lastIndex = self.flowLayout.style == .normal ? self.numbers - 1 : self.factNumbers - 2
            if self.currentIndexPath.row == lastIndex
            {
                let row = self.flowLayout.style == .normal ? 0 : 1
                self.currentIndexPath = IndexPath.init(row: row, section: 0)
            }
            else
            {
                self.currentIndexPath = self.currentIndexPath + 1;
            }
        }
        self.scrollViewWillBeginDecelerating(self.banner)
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
    
    /// 停止滚动(释放timer资源,防止内存泄漏)
    func stop() {
        self.pause()
        self.releaseTimer()
    }
    
    /// 释放timer资源,防止内存泄漏
    fileprivate func releaseTimer() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    /// banner所处控制器WillAppear方法中调用
    func bannerWillAppear() {
        if(self.autoPlay) {
            self.resumePlay()
        }
        self.adjustErrorCell(isScroll: true)
    }
    
    /// banner所处控制器WillDisAppear方法中调用
    func bannerWillDisAppear() {
        if(self.autoPlay) {
            self.pause()
        }
        self.adjustErrorCell(isScroll: true)
    }
}

// MARK: - LOGIC HELPER
extension CWBanner {
    /// 代码层下标换算成业务层下标
    ///
    /// - Parameter IndexPath: 代码层cell对应的下标
    /// - Returns: 业务层对应的下标
    fileprivate func caculateIndex(indexPath: IndexPath) -> Int {
        guard self.numbers > 0 else
        {
            return 0
        }
        
        var row = indexPath.row % self.numbers
        if !self.endless && self.flowLayout.style != .normal
        {
            row = indexPath.row % self.factNumbers - 1
        }
        return row
    }
    
    /// 第一次加载时,会从中间开始展示
    ///
    /// - Returns: 返回对应的indexPath
    fileprivate func originIndexPath() -> IndexPath {
        if endless
        {
            // 判断一共可以分成多少组
            let centerIndex = self.factNumbers / self.numbers
            if centerIndex <= 1 {
                // 小于或者只有一组
                self.currentIndexPath = IndexPath.init(row: self.numbers, section: 0)
            }else {
                // 取最中间的一组开始展示
                self.currentIndexPath = IndexPath.init(row: centerIndex / 2 * self.numbers, section: 0)
            }
            
        }
        else
        {
            let row = self.flowLayout.style == .normal ? 0 : 1
            self.currentIndexPath = IndexPath.init(row: row, section: 0)
        }
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
        self.banner.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    fileprivate func scrollToIndexPathNoAnimated(_ indexPath: IndexPath) {
        self.banner.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
    
    /// cell错位检测和调整
    fileprivate func adjustErrorCell(isScroll: Bool)
    {
        let indexPaths = self.banner.indexPathsForVisibleItems
        var attriArr = [UICollectionViewLayoutAttributes?]()
        for indexPath in indexPaths
        {
            let attri = self.banner.layoutAttributesForItem(at: indexPath)
            attriArr.append(attri)
        }
        let centerX: CGFloat = self.banner.contentOffset.x + self.banner.frame.width * 0.5
        var minSpace = CGFloat(MAXFLOAT)
//        var shouldSet = true
//        if self.flowLayout.style != .normal && indexPaths.count <= 2
//        {
//            shouldSet = false
//        }
        for atr in attriArr
        {
            if let obj = atr
            {
                obj.zIndex = 0;
                if(abs(minSpace) > abs(obj.center.x - centerX))
                {
                    minSpace = obj.center.x - centerX;
                    self.currentIndexPath = obj.indexPath;
                }
            }
        }
        if isScroll
        {
            self.scrollViewWillBeginDecelerating(self.banner)
        }
    }
    
    @objc fileprivate func appActive(_ notify: Notification) {
        self.adjustErrorCell(isScroll: true)
    }
    
    @objc fileprivate func appInactive(_ notify: Notification) {
        self.adjustErrorCell(isScroll: true)
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
        if self.autoPlay {
            self.pause()
        }
        self.delegate?.didStartScroll(banner: self, index: self.caculateIndex(indexPath: self.currentIndexPath), indexPath: self.currentIndexPath)
    }
    
    /// 将要结束拖拽
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if (!self.endless)
        {
            var maxIndex = self.numbers - 1
            var minIndex = 0
            if self.flowLayout.style != .normal
            {
                maxIndex = self.factNumbers - 2
                minIndex = 1
            }
            
            if velocity.x >= 0 && self.currentIndexPath.row == maxIndex
            {
                return
            }
            
            if velocity.x <= 0 && self.currentIndexPath.row == minIndex
            {
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
        
        guard self.currentIndexPath.row >= 0,
            self.currentIndexPath.row < self.factNumbers else {
            // 越界保护
            return
        }
        
        if !self.endless
        {
            if self.currentIndexPath.row == 0 && self.flowLayout.style != .normal
            {
                self.currentIndexPath = IndexPath.init(row: 1, section: 0)
            }
            else if self.currentIndexPath.row == self.factNumbers - 1 && self.flowLayout.style != .normal
            {
                self.currentIndexPath = IndexPath.init(row: self.factNumbers - 2, section: 0)
            }
        }
        
        // 在这里将需要显示的cell置为居中
        self.scrollToIndexPathAnimated(self.currentIndexPath)
    }
    
    /// 结束减速
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.banner.isPagingEnabled = false
    }
    
    /// 滚动动画完成
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.banner.isPagingEnabled = false
        // 边缘检测,是否滑到了最边缘
        if self.endless
        {
            self.checkOutOfBounds()
        }
       
        if self.autoPlay {
            self.resumePlay()
        }
        self.delegate?.didEndScroll(banner: self, index: self.caculateIndex(indexPath: self.currentIndexPath), indexPath: self.currentIndexPath)
    }
    
    /// 滚动中
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.autoPlay {
            self.pause()
        }
    }
}

 // MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension CWBanner: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if !self.endless
            && self.flowLayout.style != .normal
            && (indexPath.row == 0 || indexPath.row == self.factNumbers - 1)
        {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "tempCell", for: indexPath)
        }
        return self.delegate?.bannerView(banner: self,
                                         index: self.caculateIndex(indexPath: indexPath),
                                         indexPath: indexPath) ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.factNumbers
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.didSelected(banner: self,
                                   index: self.caculateIndex(indexPath: indexPath),
                                   indexPath: indexPath)
        // 处于动画中时,点击cell,可能会出现cell不居中问题.这里处理下
        // 将里中心点最近的那个cell居中
        self.adjustErrorCell(isScroll: true)
    }
}

// MARK: - Category
extension CWBanner {
    /// 背地里实际返回的cell个数
    fileprivate var factNumbers: Int {
        guard self.numbers > 0 else
        {
            return 0;
        }
        
        if endless
        {
            return 100
        }
        else if self.flowLayout.style != .normal
        {
            return self.numbers + 2
        }
        
        return self.numbers
    }
    
    /// 业务层实际需要展示的cell个数
    fileprivate var numbers: Int {
        return self.delegate?.bannerNumbers() ?? 0
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
