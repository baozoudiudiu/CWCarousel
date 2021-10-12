//
//  CWFlowLayout.m
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import "CWFlowLayout.h"

@interface CWFlowLayout () {
    
}
/**
 默认轮播图宽度
 */
@property (nonatomic, assign) CGFloat                   defaultItemWidth;
@property (nonatomic, assign) CGFloat                   factItemSpace;
@end

@implementation CWFlowLayout

- (instancetype)initWithStyle:(CWCarouselStyle)style {
    if(self = [super init]) {
        self.style = style;
        [self initial];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)initial {
    self.itemSpace_H = 0;
    self.itemSpace_V = 0;
    self.minScale = 0.8;
    self.maxScale = 1.2;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    
    if (self.style == CWCarouselStyle_Unknow) {
        return NO;
    }

    if (self.style == CWCarouselStyle_Normal) {
        return NO;
    }

    if (self.style == CWCarouselStyle_H_1) {
        return NO;
    }
    
    return YES;
}

- (void)prepareLayout {
    [super prepareLayout];
    switch (self.style) {
        case CWCarouselStyle_Normal: {
                CGFloat width = CGRectGetWidth(self.collectionView.frame);
                CGFloat height = CGRectGetHeight(self.collectionView.frame);
                self.itemWidth = width;
                self.itemSize = CGSizeMake(width, height);
                self.minimumLineSpacing = self.itemSpace_H;
                self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            }
            break;
        case CWCarouselStyle_H_1: {
            CGFloat width = self.itemWidth <= 0 ? self.defaultItemWidth : self.itemWidth;
            self.itemWidth = width;
            CGFloat height = CGRectGetHeight(self.collectionView.frame);
            self.itemSize = CGSizeMake(width, height);
            self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            self.minimumLineSpacing = self.itemSpace_H;
            break;
        }
        case CWCarouselStyle_H_2: {
            CGFloat width = self.itemWidth <= 0 ? self.defaultItemWidth : self.itemWidth;
            self.itemWidth = width;
            CGFloat height = CGRectGetHeight(self.collectionView.frame);
            self.itemSize = CGSizeMake(width, height);
            self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            CGFloat padding = width * (1 - self.minScale) * 0.5;
            self.factItemSpace = 0;
            self.minimumLineSpacing = self.itemSpace_H - padding;
        }
            break;
        case CWCarouselStyle_H_3: {
            CGFloat width = self.itemWidth <= 0 ? self.defaultItemWidth : self.itemWidth;
            self.itemWidth = width;
            CGFloat height = CGRectGetHeight(self.collectionView.frame);
            self.itemSize = CGSizeMake(width, height);
            self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            CGFloat padding = width * (1 - self.minScale) * 0.5;
            self.factItemSpace = 0;
//            if(width * (1 - self.minScale) * 0.5 < self.itemSpace_H) {
//                self.factItemSpace = self.itemSpace_H - width * (1 - self.minScale) * 0.5;
//            }
//            self.minimumLineSpacing = self.factItemSpace;
            self.minimumLineSpacing = self.itemSpace_H - padding;
        }
            break;
        
        default:
            break;
    }
    
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    
    if (self.style == CWCarouselStyle_Unknow ||
        self.style == CWCarouselStyle_Normal ||
        self.style == CWCarouselStyle_H_1) {
        
        return [super layoutAttributesForElementsInRect:rect];
    }
    
    NSArray<UICollectionViewLayoutAttributes *> *arr = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
    
    CGFloat centerX = self.collectionView.contentOffset.x + CGRectGetWidth(self.collectionView.frame) * 0.5;
    __block CGFloat maxScale = 0;
    __block UICollectionViewLayoutAttributes *attri = nil;
    
    [arr enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat space = ABS(obj.center.x - centerX);
        space = MIN(space, self.itemWidth + self.factItemSpace);
        obj.zIndex = 0;
        if(space >= 0) {
            CGFloat scale = 1;
            if (self.style == CWCarouselStyle_H_2 ||
                self.style == CWCarouselStyle_H_3) {
                /**
                 公式: scale = k * space + a
                    其中: k = (minScale - 1) / (itemWidth + factItemSpace)
                    其中: a = 1
                 综上所述:
                    scale = (minScale - 1) / (itemWitdh + factItemSpace) * space + 1
                 */
                scale = (self.minScale - 1) / (self.itemWidth + self.factItemSpace) * space + 1;
            }else {
//                scale = -((self.maxScale - 1) / width) * space + self.maxScale;
            }
            obj.transform = CGAffineTransformMakeScale(scale, scale);
            if(maxScale < scale) {
                maxScale = scale;
                attri = obj;
            }
        }
    }];
    
    if (attri) {
        attri.zIndex = 1;
    }
    
    return arr;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    return proposedContentOffset;
}
#pragma mark - Property
- (CGFloat)defaultItemWidth {
    switch (self.style) {
        case CWCarouselStyle_Unknow:
        case CWCarouselStyle_Normal:
            return self.collectionView.frame.size.width;
            break;
        case CWCarouselStyle_H_1:
        case CWCarouselStyle_H_2:
        case CWCarouselStyle_H_3:
            return self.collectionView.frame.size.width * 0.75;
            break;
        default:
            break;
    }
}

- (void)setMaxScale:(CGFloat)maxScale {
    _maxScale = maxScale;
    if(maxScale < 1) {
        _maxScale = 1;
    }
}

- (void)setMinScale:(CGFloat)minScale {
    _minScale = minScale;
    if(minScale < 0) {
        _minScale = 0.1;
    }
    if (minScale >= 1) {
        _minScale = 1;
    }
}
@end
