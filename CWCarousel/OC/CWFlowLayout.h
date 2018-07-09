//
//  CWFlowLayout.h
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CWCarouselStyle) {
    CWCarouselStyle_Unknow = 0,
    CWCarouselStyle_Normal,
    CWCarouselStyle_H_1,
    CWCarouselStyle_H_2,
    CWCarouselStyle_H_3,
};

@interface CWFlowLayout : UICollectionViewFlowLayout
/**
 影响轮播图风格
 */
@property (nonatomic, assign) CWCarouselStyle style;

/**
 横向滚动时,每张轮播图之间的间距
 */
@property (nonatomic, assign) CGFloat itemSpace_H;

/**
 纵向滚动时,每张轮播图之间的间距(暂未实现)
 */
@property (nonatomic, assign) CGFloat itemSpace_V;

@property (nonatomic, strong, readonly) NSIndexPath *adjustIndexPath;
@property (nonatomic, strong, readonly) UICollectionViewLayoutAttributes *currentAttri;
- (instancetype)initWithStyle:(CWCarouselStyle)style;
@end
