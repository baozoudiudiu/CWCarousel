//
//  CWCarouselProtocol.h
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#ifndef CWCarouselProtocol_h
#define CWCarouselProtocol_h

@class CWCarousel;
@protocol CWCarouselDelegate<NSObject>
/**
 轮播图点击代理

 @param carousel 轮播图实例对象
 @param index 被点击的下标
 */
- (void)CWCarousel:(CWCarousel *)carousel didSelectedAtIndex:(NSInteger)index;
@end

@protocol CWCarouselDatasource<NSObject>
/**
 轮播图数量

 @return 轮播图展示个数
 */
- (NSInteger)numbersForCarousel;
/**
 自定义每个轮播图视图

 @param carousel 轮播图控件
 @param indexPath 轮播图cell实际下标
 @param index 业务逻辑需要的下标
 @return 自定义视图
 */
- (UICollectionViewCell *)viewForCarousel:(CWCarousel *)carousel indexPath:(NSIndexPath *)indexPath index:(NSInteger)index;
@end


@protocol CWCarouselPageControlProtocol<NSObject>
@required
/**
 总页数
 */
@property (nonatomic, assign) NSInteger         pageNumbers;
/**
 当前页
 */
@property (nonatomic, assign) NSInteger         currentPage;

- (void)setCurrentPage:(NSInteger)currentPage;
- (void)setPageNumbers:(NSInteger)pageNumbers;
@end
#endif /* CWCarouselProtocol_h */


