//
//  CWSwiftFlowLayout.swift
//  CWCarousel
//
//  Created by chenwang on 2018/7/18.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

import UIKit

/// banner风格枚举
enum CWBannerStyle {
    /// 未知样式
    case unknown
    /// 默认样式
    case normal
    /// 自定义样式一, 中间一张居中,前后2张图有部分内容在屏幕内可以预览到
    case preview_normal
}

class CWSwiftFlowLayout: UICollectionViewFlowLayout {
    //MARK: - 构造方法
    init(style: CWBannerStyle) {
        self.style = style
        super.init()
    }
    
    deinit {
        NSLog("%s", #function);
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.style = .unknown
        super.init(coder: aDecoder)
    }
    
    //MARK: - Override
    override func prepare() {
        super.prepare()
        guard self.collectionView != nil else {
            assert(self.collectionView != nil, "error")
            return
        }
        switch self.style {
        case .normal:
            self.scrollDirection = .horizontal
            let width = self.collectionView!.frame.width
            let height = self.collectionView!.frame.height
            self.itemSize = CGSize.init(width: width, height: height)
            self.minimumLineSpacing = self.itemSpace;
        case .preview_normal:
            self.scrollDirection = .horizontal
            let height = self.collectionView!.frame.height
            let width = self.collectionView!.frame.width * self.itemWidthScale
            self.itemSize = CGSize.init(width: width, height: height)
            self.minimumLineSpacing = self.itemSpace;
        default:
            ()
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if self.style == .normal {
            return super.layoutAttributesForElements(in: rect)
        }else {
            return super.layoutAttributesForElements(in: rect)
        }
    }
    
    //MARK: - Property
    /// banner风格
    let style: CWBannerStyle
    /// 每张图之间的间距, 默认为0
    var itemSpace: CGFloat = 1
    
    /*
     *   preview_normal 样式下,cell的宽度占总宽度的比例
     *   默认: 0.8
     */
    var itemWidthScale: CGFloat = 0.8
}

