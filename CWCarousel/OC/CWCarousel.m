//
//  CWCarousel.m
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import "CWCarousel.h"

@interface CWCarousel ()<UICollectionViewDelegate, UICollectionViewDataSource> {
    
}
@property (nonatomic, strong) UICollectionView *carouselView;
@property (nonatomic, assign) NSInteger        numbers;
@property (nonatomic, assign) NSInteger        currentIndex;
@property (nonatomic, assign) NSInteger        infactIndex;
@property (nonatomic, assign) CGFloat           addHeight;
@end

@implementation CWCarousel
@synthesize carouselView = _carouselView;


- (instancetype)initWithFrame:(CGRect)frame delegate:(id<CWCarouselDelegate>)delegate datasource:(id<CWCarouselDatasource>)datasource flowLayout:(CWFlowLayout *)flowLayout {
    CGFloat addHeight = 0;
    if(flowLayout.style == CWCarouselStyle_H_3) {
        /* 如果是CWCarouselStyle_H_3, 因为中间一张图片放大的原因,需要扩充一下frame的高度,所以会和实际的传入的frame
         的高度有部分偏差
         */
        addHeight = (flowLayout.maxScale - 1) * CGRectGetHeight(frame);
    }
    frame.size.height += addHeight;
    self.addHeight = addHeight;
    if(self = [super initWithFrame:frame]) {
        _flowLayout = flowLayout;
        self.delegate = delegate;
        self.datasource = datasource;
        [self configureView];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    newSuperview.clipsToBounds = NO;
    [super willMoveToSuperview:newSuperview];
}

- (void)registerViewClass:(Class)viewClass identifier:(NSString *)identifier {
    [self.carouselView registerClass:viewClass forCellWithReuseIdentifier:identifier];
}

- (void)registerNibView:(NSString *)nibName identifier:(NSString *)identifier {
    [self.carouselView registerNib:[UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]]
        forCellWithReuseIdentifier:identifier];
}

- (void)freshCarousel {
    [self.carouselView reloadData];
    [self.carouselView scrollToItemAtIndexPath:[self originIndexPath] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}
#pragma mark - < Scroll Delegate >
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    CWFlowLayout *layout = (CWFlowLayout *)(self.carouselView.collectionViewLayout);
    if(layout.adjustIndexPath != nil) {
        [self.carouselView scrollToItemAtIndexPath:layout.adjustIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}
#pragma mark - < Logic Helper >
- (NSIndexPath *)originIndexPath {
    NSInteger centerIndex = [self infactNumbers] / [self numbers];
    if(centerIndex <= 1) {
        return [NSIndexPath indexPathForRow:self.numbers inSection:0];
    }else {
        return [NSIndexPath indexPathForRow:centerIndex / 2 * [self numbers] inSection:0];
    }
}

/**
 实际下标转换成业务需求下标

 @param factIndex 实际下标
 @return 业务需求下标
 */
- (NSInteger)caculateIndex:(NSInteger)factIndex {
    NSInteger row = factIndex % [self numbers];
    return row;
}

#pragma mark - < Configure View>
- (void)configureView {
    self.backgroundColor = [UIColor blackColor];
    self.carouselView.showsVerticalScrollIndicator = NO;
    self.carouselView.showsHorizontalScrollIndicator = NO;
    self.carouselView.decelerationRate = 0;
}

#pragma mark - < Delegate, Datasource >
- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if(self.datasource &&
       [self.datasource respondsToSelector:@selector(viewForCarousel:indexPath:index:)]) {
        return [self.datasource viewForCarousel:self indexPath:indexPath index:[self caculateIndex:indexPath.row]];
    }
    return nil;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self infactNumbers];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(CWCarousel:didSelectedAtIndex:)]) {
        [self.delegate CWCarousel:self didSelectedAtIndex:[self caculateIndex:indexPath.row]];
    }
}

#pragma mark - < getter >
- (UICollectionView *)carouselView {
    if(!_carouselView) {
        self.carouselView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.addHeight * 0.5, self.frame.size.width, self.frame.size.height - self.addHeight) collectionViewLayout:self.flowLayout];
        _carouselView.clipsToBounds = NO;
        _carouselView.delegate = self;
        _carouselView.dataSource = self;
        _carouselView.pagingEnabled = YES;
        [self addSubview:_carouselView];
    }
    return _carouselView;
}


/**
 Description

 @return 业务需求需要展示轮播图个数
 */
- (NSInteger)numbers {
    if(self.datasource &&
       [self.datasource respondsToSelector:@selector(numbersForCarousel)]) {
        return [self.datasource numbersForCarousel];
    }
    return 0;
}

/**
 轮播图实际加载视图个数

 @return 轮播图实际加载视图个数
 */
- (NSInteger)infactNumbers {
    return 500;
}
@end
