//
//  CWFlowLayout.h
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CWCarouselStyle) {
    CWCarouselStyle_Unknow = 0,     ///<未知样式
    CWCarouselStyle_Normal,         ///<普通样式,一张图占用整个屏幕宽度
    CWCarouselStyle_H_1,            ///<自定义样式一, 中间一张居中,前后2张图有部分内容在屏幕内可以预览到
    CWCarouselStyle_H_2,            ///<自定义样式二, 中间一张居中,前后2张图有部分内容在屏幕内可以预览到,并且中间一张图正常大小,前后2张图会缩放
    CWCarouselStyle_H_3,            ///<自定义样式三, 中间一张居中,前后2张图有部分内容在屏幕内可以预览到,中间一张有放大效果,前后2张正常大小
};

@interface CWFlowLayout : UICollectionViewFlowLayout
/**
 影响轮播图风格
 */
@property (nonatomic, assign) CWCarouselStyle style;

/**
 * 横向滚动时,每张轮播图之间的间距
 * CWCarouselStyle_H_3 样式时设置无效
 */
@property (nonatomic, assign) CGFloat itemSpace_H;

/**
 * 横向滚动时,每张轮播图的宽度
 * style = CWCarouselStyle_Normal 时设置无效
 */
@property (nonatomic, assign) CGFloat itemWidth;

/**
 * style = CWCarouselStyle_H_2 有效
 * 前后2张图的缩小比例 (0.0 ~ 1.0)
 * 默认: 0.8
 */
@property (nonatomic, assign) CGFloat minScale;

/**
 * style = CWCarouselStyle_H_3 有效
 * 中间一张图放大比例
 * 默认: 1.2
 * 1.1.0版本后,无论设置多少,中间一张的cell的比例始终是原始size, 这个比例是相对两边cell的size的相对比例
    也就是说,该值越大,那么两边的cell就会相对越小.反之越大.
 */
@property (nonatomic, assign) CGFloat maxScale;

/**
 纵向滚动时,每张轮播图之间的间距(暂未实现)
 */
@property (nonatomic, assign) CGFloat itemSpace_V;


/**
 构造方法

 @param style 轮播图风格
 @return 实例对象
 */
- (instancetype)initWithStyle:(CWCarouselStyle)style;
@end
