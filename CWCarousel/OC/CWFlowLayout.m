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
            }
        }];
        return arr;
    }else {
        return [super layoutAttributesForElementsInRect:rect];
    }
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGRect rect;
    rect.origin.x = proposedContentOffset.x;
    rect.origin.y = 0;
    rect.size.width = CGRectGetWidth(self.collectionView.frame);
    rect.size.height = CGRectGetHeight(self.collectionView.frame);
    
    CGFloat centerX = proposedContentOffset.x + CGRectGetWidth(self.collectionView.frame) * 0.5;
    NSArray <UICollectionViewLayoutAttributes *>  *tempArr = [super layoutAttributesForElementsInRect:rect];
    __block CGFloat minSpace = MAXFLOAT;
    __block NSInteger index = 0;
    [tempArr enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(ABS(minSpace) > ABS(obj.center.x - centerX)) {
            minSpace = obj.center.x - centerX;
            index = idx;
        }
        obj.zIndex = 0;
    }];
    proposedContentOffset.x += minSpace;
    [tempArr objectAtIndex:index].zIndex = 1;
    return proposedContentOffset;
}

@end
