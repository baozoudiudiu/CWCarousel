//
//  CWCarousel.h
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CWCarouselProtocol.h"
#import "CWFlowLayout.h"

@interface CWCarousel : UIView
#pragma mark - < 相关属性 >
/**
 相关代理
 */
@property (nonatomic, assign) id <CWCarouselDelegate> _Nullable delegate;
/**
 相关数据源
 */
@property (nonatomic, assign) id <CWCarouselDatasource> _Nullable datasource;

/**
 布局自定义layout
 */
@property (nonatomic, strong, readonly) CWFlowLayout    * _Nonnull flowLayout;

/**
 样式风格
 */
@property (nonatomic, assign, readonly) CWCarouselStyle   style;

/**
 实际的示轮播图内容的视图(其实就是基于collectionView实现的)
 */
@property (nonatomic, strong, readonly) UICollectionView    * _Nonnull carouselView;

#pragma mark - < 相关方法 >
/**
 创建实例构造方法

 @param frame 尺寸大小
 @param delegate 代理
 @param datasource 数据源
 @param flowLayout 自定义flowlayout
 @return 实例对象
 */
- (instancetype _Nullable )initWithFrame:(CGRect)frame
                        delegate:(id<CWCarouselDelegate> _Nullable)delegate
                        datasource:(id<CWCarouselDatasource> _Nullable)datasource
                       flowLayout:(nonnull CWFlowLayout *)flowLayout;

/**
 注册自定视图

 @param viewClass 自定义视图类名
 @param identifier 重用唯一标识符
 */
- (void)registerViewClass:(Class _Nullable )viewClass identifier:(NSString *_Nullable)identifier;

/**
 注册自定义视图

 @param nibName 自定义视图xib相关文件名
 @param identifier 重用唯一标识符
 */
- (void)registerNibView:(NSString *_Nullable)nibName identifier:(NSString *_Nullable)identifier;


/**
 刷新轮播图
 */
- (void)freshCarousel;
@end
