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
}

class CWBanner: UIView {
    //MARK: - 构造方法
    init(frame: CGRect, flowLayout: CWSwiftFlowLayout) {
        self.flowLayout = flowLayout
        super.init(frame: frame)
        self.configureBanner()
    }
    required init?(coder aDecoder: NSCoder) {
        self.flowLayout = CWSwiftFlowLayout.init(style: .unknown)
        super.init(coder: aDecoder)
    }
    //MARK: - Property
    let flowLayout: CWSwiftFlowLayout
    lazy var banner: UICollectionView = {
        let b = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: self.flowLayout)
        self.addSubview(b)
        
//        b.delegate = self
//        b.dataSource = self
        return b
    }()
    weak var delegate: CWBannerDelegate?
}

// MARK: - UI
extension CWBanner {
    fileprivate func configureBanner() {
        
    }
}

 /// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension CWBanner: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.delegate?.bannerView(banner: self, index: 0, indexPath: indexPath) ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.delegate?.bannerNumbers() ?? 0
    }
}
