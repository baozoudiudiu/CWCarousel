//
//  CWFlowLayout.m
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import "CWFlowLayout.h"

@implementation CWFlowLayout

- (instancetype)initWithStyle:(CWCarouselStyle)style {
    if(self = [super init]) {
        self.style = style;
        [self initial];
    }
    return self;
}

- (void)initial {
    self.itemSpace_H = 1;
    self.itemSpace_V = 1;
}

- (void)prepareLayout {
    switch (self.style) {
        case CWCarouselStyle_Normal:
            {
                CGFloat width = CGRectGetWidth(self.collectionView.frame);
                CGFloat height = CGRectGetHeight(self.collectionView.frame);
                self.itemSize = CGSizeMake(width, height);
                self.minimumLineSpacing = self.itemSpace_H;
                self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            }
            break;
        case CWCarouselStyle_H_1: {
            CGFloat width = CGRectGetWidth(self.collectionView.frame) * 0.75;
            CGFloat height = CGRectGetHeight(self.collectionView.frame);
            self.itemSize = CGSizeMake(width, height);
            self.minimumLineSpacing = self.itemSpace_H;
            self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
            break;
        case CWCarouselStyle_H_2: {
            CGFloat width = CGRectGetWidth(self.collectionView.frame) * 0.75;
            CGFloat height = CGRectGetHeight(self.collectionView.frame);
            self.itemSize = CGSizeMake(width, height);
            self.minimumLineSpacing = self.itemSpace_H;
            self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
            break;
        case CWCarouselStyle_H_3: {
            CGFloat width = CGRectGetWidth(self.collectionView.frame) * 0.75;
            CGFloat height = CGRectGetHeight(self.collectionView.frame);
            self.itemSize = CGSizeMake(width, height);
            self.minimumLineSpacing = self.itemSpace_H;
            self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
            break;
        default:
            break;
    }
    
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    if(self.style != CWCarouselStyle_Normal &&
       self.style != CWCarouselStyle_Unknow &&
       self.style != CWCarouselStyle_H_1) {
        NSArray<UICollectionViewLayoutAttributes *> *arr = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
        CGFloat centerX = self.collectionView.contentOffset.x + CGRectGetWidth(self.collectionView.frame) * 0.5;
        CGFloat width = CGRectGetWidth(self.collectionView.frame) * 0.75;
        __block CGFloat maxScale = 0;
        __block UICollectionViewLayoutAttributes *attri = nil;
        [arr enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat space = ABS(obj.center.x - centerX);
            if(space > 0) {
                CGFloat scale = 1;
                if (self.style == CWCarouselStyle_H_2) {
                    scale = -(0.2 / (0.9 * width)) * space + 1;
                }else {
                    scale = -(0.3 / width) * space + 1.2;
                }
                obj.transform = CGAffineTransformMakeScale(scale, scale);
                if(maxScale < scale) {
                    maxScale = scale;
                    attri = obj;
                }
            }
            obj.zIndex = 0;
        }];
        if (attri) {
            attri.zIndex = 1;
        }
        return arr;
    }else {
        return [super layoutAttributesForElementsInRect:rect];
    }
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGRect rect;
    _adjustIndexPath = nil;
    rect.origin.x = proposedContentOffset.x;
    rect.origin.y = 0;
    rect.size.width = CGRectGetWidth(self.collectionView.frame);
    rect.size.height = CGRectGetHeight(self.collectionView.frame);

    CGFloat centerX = proposedContentOffset.x + CGRectGetWidth(self.collectionView.frame) * 0.5;
    NSArray <UICollectionViewLayoutAttributes *>  *tempArr = [super layoutAttributesForElementsInRect:rect];
    __block CGFloat minSpace = MAXFLOAT;
    __block UICollectionViewLayoutAttributes *attributes = nil;
    [tempArr enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.zIndex = 0;
        if(ABS(minSpace) > ABS(obj.center.x - centerX)) {
            minSpace = obj.center.x - centerX;
            attributes = obj;
        }
    }];
    attributes.zIndex = 1;
    _currentAttri = attributes;
    if(velocity.x == 0) {
        proposedContentOffset.x += minSpace;
        _adjustIndexPath = nil;
    }else if(attributes) {
        if(ABS(minSpace) >= attributes.size.width * 0.15) {
            NSInteger der = attributes.indexPath.row;
            if(velocity.x > 0) {
                der = (minSpace < 0 && velocity.x > 0) ? 1 : 0;
            }else {
                der = (minSpace > 0 && velocity.x < 0) ? -1 : 0;
            }
            _adjustIndexPath = [NSIndexPath indexPathForRow:attributes.indexPath.row + der inSection:attributes.indexPath.section];
        }else {
            _adjustIndexPath = attributes.indexPath;
        }
    }
    return proposedContentOffset;
}
@end
