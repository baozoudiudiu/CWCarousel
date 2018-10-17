//
//  ShowViewController.swift
//  CWCarousel
//
//  Created by chenwang on 2018/7/20.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

import UIKit

let cellReuseId = "cellReuseId"
class ShowViewController: UIViewController {
    //MARK: - INITILAL
    init(style: CWBannerStyle) {
        self.bannerStyle = style
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.bannerStyle = .unknown
        super.init(coder: aDecoder)
    }
    
    deinit {
        NSLog("[%@ -- %@]", NSStringFromClass(self.classForCoder), #function)
    }
    
    //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.bannerView.bannerWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.bannerView.bannerWillDisAppear()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: - PROPERTY
    let bannerStyle: CWBannerStyle
    
    let imgNames = ["01.jpg",
                    "02.jpg",
                    "03.jpg",
                    "04.jpg",
                    "05.jpg"]
    
    lazy var bannerView: CWBanner = {
        let layout = CWSwiftFlowLayout.init(style: self.bannerStyle)
        let banner = CWBanner.init(frame: CGRect.init(x: 0, y: 100, width: UIScreen.main.bounds.width, height: 240), flowLayout: layout, delegate: self)
        self.view.addSubview(banner)
        
        banner.backgroundColor = self.view.backgroundColor
        banner.banner.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellReuseId)
        
        banner.autoPlay = true
        banner.endless = true
        banner.timeInterval = 2
        
        return banner
    }()
}

//MARK: - CWBannerDelegate
extension ShowViewController: CWBannerDelegate {
    func bannerNumbers() -> Int {
        return self.imgNames.count
    }
    
    func bannerView(banner: CWBanner, index: Int, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = banner.banner.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath)
        var imgView = cell.contentView.viewWithTag(999)
        var label = cell.contentView.viewWithTag(888)
        if imgView == nil {
            imgView = UIImageView.init(frame: cell.contentView.bounds)
            imgView?.tag = 999
            cell.contentView.addSubview(imgView!)
            imgView?.layer.cornerRadius = 4.0
            imgView?.layer.masksToBounds = true
            
            label = UILabel.init(frame: CGRect.init(x: 30, y: 0, width: 60, height: 30))
            (label as! UILabel).textColor = UIColor.white
            (label as! UILabel).font = UIFont.systemFont(ofSize: 21)
            label?.tag = 888
            cell.contentView.addSubview(label!)
        }
        (imgView as! UIImageView).image = UIImage.init(named: self.imgNames[index])
        (label as! UILabel).text = "\(index)"
        return cell
    }
    
    func didSelected(banner: CWBanner, index: Int, indexPath: IndexPath) {
        print("点击 \(index) click...")
    }
    
    func didStartScroll(banner: CWBanner, index: Int, indexPath: IndexPath) {
        print("开始滑动: \(index) ...")
    }
    
    func didEndScroll(banner: CWBanner, index: Int, indexPath: IndexPath) {
        print("结束滑动: \(index) ...")
    }
}

// MARK: - CONFIGURE UI
extension ShowViewController {
    fileprivate func configureUI() {
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "show"
        self.bannerView.freshBanner()
    }
}
