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
    /// 自定义样式二, 中间一张居中,前后2张图有部分内容在屏幕内可以预览到,并且中间一张图正常大小,前后2张图会缩放
    case preview_zoom
    /// 自定义样式三, 中间一张居中,前后2张图有部分内容在屏幕内可以预览到,中间一张有放大效果,前后2张正常大小
    case preview_big
}

class CWSwiftFlowLayout: UICollectionViewFlowLayout {
    //MARK: - 构造方法
    init(style: CWBannerStyle) {
        self.style = style
        super.init()
    }
    
    deinit {
        NSLog("[%@ -- %@]",NSStringFromClass(self.classForCoder) ,#function);
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
            self.initialNormalStyle()
        case .preview_normal:
            self.initialPreview_normalStyle()
        case .preview_zoom:
            self.initialPreview_zoomStyle()
        case .preview_big:
            self.initialPreview_bigStyle()
        default:
            ()
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var arr: [UICollectionViewLayoutAttributes]? = nil;
        switch self.style {
        case .normal: ()
            fallthrough
        case .preview_normal:
            arr = super.layoutAttributesForElements(in: rect)
        case .preview_zoom: ()
            arr = self.caculateScale(rect: rect, block: { (width, space) -> CGFloat in
                var faceItemSpace = self.itemSpace
                if(width * (1 - self.minScale) * 0.5 < self.itemSpace) {
                    faceItemSpace = self.itemSpace - width * (1 - self.minScale) * 0.5;
                }
                return (self.minScale - 1.0) / (width + faceItemSpace) * space + 1.0
            })
        case .preview_big:
            arr = self.caculateScale(rect: rect, block: { (width, space) -> CGFloat in
                return -((self.maxScale - 1) / width) * space + self.maxScale;
            })
        default:
            ()
        }
        return arr
    }
    
    //MARK: - Property
    /// banner风格
    let style: CWBannerStyle
    /// 每张图之间的间距, 默认为0
    var itemSpace: CGFloat = 1
    
    /*
     *   cell的宽度占总宽度的比例
     *   默认: 0.75
     *   normal 样式下无效
     */
    var itemWidthScale: CGFloat = 0.75
    
    /**
     * style = preview_zoom 有效
     * 前后2张图的缩小比例 (0.0 ~ 1.0)
     * 默认: 0.8
     */
    var minScale: CGFloat = 0.8
    
    /**
     * style = preview_big 有效
     * 中间一张图放大比例
     * 默认: 1.2
     1.1.0版本后,无论设置多少,中间一张的cell的比例始终是原始size, 这个比例是相对两边cell的size的相对比例
     也就是说,该值越大,那么两边的cell就会相对越小.反之越大.
     */
    var maxScale: CGFloat = 1.2
}


// MARK: - Logic Helper
extension CWSwiftFlowLayout {
    
    /// 计算样式为preview_big,需要扩展的高度
    ///
    /// - Parameter height: 轮播图的高度
    /// - Returns: 比实际轮播图要高出的高度
    func addHeight(_ height: CGFloat) -> CGFloat {
//        if self.style == .preview_big {
//            return (self.maxScale - 1.0) * height
//        }
        return 0
    }
    
    /// 计算cell缩放公式
    ///
    /// - Parameters:
    ///   - rect: rect
    ///   - block: 计算方法闭包
    /// - Returns:
    fileprivate func caculateScale(rect: CGRect, block: (CGFloat, CGFloat) -> CGFloat) -> [UICollectionViewLayoutAttributes]? {
        let arr = super.layoutAttributesForElements(in: rect)?.map({ return $0.copy() }) as! [UICollectionViewLayoutAttributes]?
        let centerX = self.collectionView!.contentOffset.x + self.collectionView!.frame.width * 0.5
        let width = self.collectionView!.frame.width * self.itemWidthScale
        var maxScale: CGFloat = 0
        var attri: UICollectionViewLayoutAttributes? = nil
        arr?.forEach({ (element) in
            let space = CGFloat(abs(element.center.x - centerX))
            if space >= 0 {
                var scale: CGFloat = 1.0
                scale = block(width, space)
                element.transform = CGAffineTransform.init(scaleX: scale, y: scale)
                if maxScale < scale {
                    maxScale = scale
                    attri = element
                }
            }
            element.zIndex = 0
        })
        if attri != nil {
            attri?.zIndex = 1
        }
        return arr
    }
    
    /// 设置默认样式
    fileprivate func initialNormalStyle() {
        self.scrollDirection = .horizontal
        let width = self.collectionView!.frame.width
        let height = self.collectionView!.frame.height
        self.itemSize = CGSize.init(width: width, height: height)
        self.minimumLineSpacing = self.itemSpace;
    }
    
    /// 设置preview_默认样式
    fileprivate func initialPreview_normalStyle() {
        self.scrollDirection = .horizontal
        let height = self.collectionView!.frame.height
        let width = self.collectionView!.frame.width * self.itemWidthScale
        self.itemSize = CGSize.init(width: width, height: height)
        self.minimumLineSpacing = self.itemSpace;
    }
    
    /// 设置preiview_zoom样式
    fileprivate func initialPreview_zoomStyle() {
        self.scrollDirection = .horizontal
        let height = self.collectionView!.frame.height
        let width = self.collectionView!.frame.width * self.itemWidthScale
        self.itemSize = CGSize.init(width: width, height: height)
        self.minimumLineSpacing = self.itemSpace;
    }
    
    /// 设置preiview_big样式
    fileprivate func initialPreview_bigStyle() {
        self.scrollDirection = .horizontal
        let height = self.collectionView!.frame.height - self.addHeight(self.collectionView!.frame.height)
        let width = self.collectionView!.frame.width * self.itemWidthScale
        self.itemSize = CGSize.init(width: width, height: height / self.maxScale)
        self.minimumLineSpacing = self.itemSpace;
        self.sectionInset = UIEdgeInsets.init(top: self.addHeight(self.collectionView!.frame.height) * 0.5, left: 0, bottom: 0, right: 0)
    }
}

