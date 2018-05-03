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
- (void)CWCarousel:(CWCarousel *)carousel didSelectedAtIndex:(NSInteger)index;
@end

@protocol CWCarouselDatasource<NSObject>
- (NSInteger)numbersForCarousel;
- (UICollectionViewCell *)viewForCarousel:(CWCarousel *)carousel indexPath:(NSIndexPath *)indexPath index:(NSInteger)index;
@end

#endif /* CWCarouselProtocol_h */
