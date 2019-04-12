//
//  CWCarousel.m
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import "CWCarousel.h"

@interface CWTempleteCell: UICollectionViewCell
@end

@implementation CWTempleteCell
@end



@interface CWCarousel ()<UICollectionViewDelegate, UICollectionViewDataSource> {
    
}
@property (nonatomic, strong) UICollectionView *carouselView;
@property (nonatomic, assign) NSInteger        numbers;
@property (nonatomic, assign) NSInteger        currentIndex;
@property (nonatomic, assign) NSInteger        infactIndex;
@property (nonatomic, assign) CGFloat          addHeight;
/**
 自动播放是否暂停
 */
@property (nonatomic, assign) BOOL             isPause;

/**
 当前展示在中间的cell下标
 */
@property (nonatomic, strong) NSIndexPath      *currentIndexPath;

@end
@implementation CWCarousel
@synthesize carouselView = _carouselView;


- (instancetype)initWithFrame:(CGRect)frame delegate:(id<CWCarouselDelegate>)delegate datasource:(id<CWCarouselDatasource>)datasource flowLayout:(CWFlowLayout *)flowLayout {
    CGFloat addHeight = 0;
//    if(flowLayout.style == CWCarouselStyle_H_3) {
//        /* 如果是CWCarouselStyle_H_3, 因为中间一张图片放大的原因,需要扩充一下frame的高度,所以会和实际的传入的frame
//         的高度有部分偏差
//         */
//        addHeight = (flowLayout.maxScale - 1) * CGRectGetHeight(frame);
//    }
    frame.size.height += addHeight;
    self.addHeight = addHeight;
    if(self = [super initWithFrame:frame]) {
        _flowLayout = flowLayout;
        self.delegate = delegate;
        self.datasource = datasource;
        self.isAuto = NO;
        self.autoTimInterval = 3;
        self.endless = YES;
        [self configureView];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeInactive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    return self;
}

- (void)appBecomeInactive:(NSNotification *)notification {
    [self adjustErrorCell:YES];
}

- (void)appBecomeActive:(NSNotification *)notification {
    [self adjustErrorCell:YES];
}

- (void)controllerWillAppear {
    if(self.isAuto) {
        [self resumePlay];
    }
    [self adjustErrorCell:YES];
}

- (void)controllerWillDisAppear {
    if(self.isAuto) {
        [self pause];
    }
    [self adjustErrorCell:YES];
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    newSuperview.clipsToBounds = NO;
    if(self.customPageControl == nil && self.pageControl.superview == nil) {
        [self addSubview:self.pageControl];
        self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[control]-0-|"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:@{@"control" : self.pageControl}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[control(30)]-0-|"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:@{@"control" : self.pageControl}]];
    }else if(self.customPageControl || self.customPageControl.superview == nil) {
        [self addSubview:self.customPageControl];
    }
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
    if([self numbers] <= 0) {
        return;
    }
    [self.carouselView reloadData];
    [self.carouselView layoutIfNeeded];
    if (self.endless)
        [self.carouselView scrollToItemAtIndexPath:[self originIndexPath] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    else
    {
        if(self.flowLayout.style == CWCarouselStyle_Normal)
        {
            [self.carouselView scrollToItemAtIndexPath:self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
        else
        {
            [self.carouselView scrollToItemAtIndexPath:self.currentIndexPath = [NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
    }
    
    
    self.carouselView.userInteractionEnabled = YES;
    if (self.isAuto) {
        [self play];
    }
}
#pragma mark - < Scroll Delegate >
/// 开始拖拽
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 防止拖动加速度太大,一次跳过多张图片,这里设置一下
    scrollView.pagingEnabled = YES;
    if (self.isAuto) {
        [self stop];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(CWCarousel:didStartScrollAtIndex:indexPathRow:)]) {
        [self.delegate CWCarousel:self didStartScrollAtIndex:[self caculateIndex:self.currentIndexPath.row] indexPathRow:self.currentIndexPath.row];
    }
}

/// 将要结束拖拽
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (!self.endless)
    {
        NSInteger maxIndex = [self numbers] - 1;
        NSInteger minIndex = 0;
        if(self.flowLayout.style != CWCarouselStyle_Normal)
        {
            maxIndex = [self infactNumbers] - 2;
            minIndex = 1;
        }
        if (velocity.x >= 0 && self.currentIndexPath.row == maxIndex)
        {
            return;
        }
        if (velocity.x <= 0 && self.currentIndexPath.row == minIndex)
        {
            return;
        }
    }
    
    if(velocity.x > 0) {
        //左滑,下一张
        self.currentIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + 1 inSection:self.currentIndexPath.section];
    }else if (velocity.x < 0) {
        //右滑,上一张
        self.currentIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row - 1 inSection:self.currentIndexPath.section];
    }else if (velocity.x == 0) {
        //还有一种情况,当滑动后手指按住不放,然后松开,此时的加速度其实是为0的
        [self adjustErrorCell:NO];
    }
}

/// 开始减速
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if(self.currentIndexPath != nil &&
       self.currentIndexPath.row < [self infactNumbers] &&
       self.currentIndexPath.row >= 0) {
        // 中间一张轮播,居中显示
        if (!self.endless)
        {
            if (self.currentIndexPath.row == 0 && self.style != CWCarouselStyle_Normal)
            {
                self.currentIndexPath = [NSIndexPath indexPathForRow:1 inSection:self.currentIndexPath.section];
            }
            else if (self.currentIndexPath.row == [self infactNumbers] - 1 && self.style != CWCarouselStyle_Normal)
            {
                self.currentIndexPath = [NSIndexPath indexPathForRow:[self infactNumbers] - 2 inSection:self.currentIndexPath.section];
            }
        }
        [self.carouselView scrollToItemAtIndexPath:self.currentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

/// 减速完成
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 打开交互
    scrollView.pagingEnabled = NO;
    if(self.isAuto) {
        [self play];
    }
}

/// 滚动动画完成
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    // 滚动完成,打开交互,关掉pagingEnabled
    // 为什么要关掉pagingEnabled呢,因为切换控制器的时候会有系统级bug,不信你试试.
    scrollView.userInteractionEnabled = YES;
    scrollView.pagingEnabled = NO;
    if(self.isAuto) {
        [self play];
    }
    if (self.endless)
        [self checkOutofBounds];
    
//    if(!self.endless)
//    {
//        CGFloat space = self.flowLayout.itemSpace_H + self.flowLayout.itemWidth * (1 - self.flowLayout.minScale) * 0.5;
//        if(self.currentIndexPath.row == 0)
//            self.carouselView.contentInset = UIEdgeInsetsMake(0, space, 0, 0);
//        else if(self.currentIndexPath.row == [self numbers] - 1)
//            self.carouselView.contentInset = UIEdgeInsetsMake(0, 0, 0, space);
//        else
//            self.carouselView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
//    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(CWCarousel:didEndScrollAtIndex:indexPathRow:)]) {
        [self.delegate CWCarousel:self didEndScrollAtIndex:[self caculateIndex:self.currentIndexPath.row] indexPathRow:self.currentIndexPath.row];
    }
}

// 滚动中
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 滚动过程中关闭交互
//    scrollView.userInteractionEnabled = NO;
}
#pragma mark - < Logic Helper >
- (NSIndexPath *)originIndexPath {
    NSInteger centerIndex = [self infactNumbers] / [self numbers];
    if(centerIndex <= 1) {
        self.currentIndexPath = [NSIndexPath indexPathForRow:self.numbers inSection:0];
    }else {
        self.currentIndexPath = [NSIndexPath indexPathForRow:centerIndex / 2 * [self numbers] inSection:0];
    }
    return self.currentIndexPath;
}

- (void)checkOutofBounds {
    // 越界检查
    if(self.currentIndexPath.row == [self infactNumbers] - 1) {
        //最后一张
        NSIndexPath *origin = [self originIndexPath];
        NSInteger index = [self caculateIndex:self.currentIndexPath.row] - 1;
        self.currentIndexPath = [NSIndexPath indexPathForRow:origin.row + index inSection:origin.section];
        [self.carouselView scrollToItemAtIndexPath:self.currentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        self.carouselView.userInteractionEnabled = YES;
    }else if(self.currentIndexPath.row == 0) {
        //第一张
        NSIndexPath *origin = [self originIndexPath];
        NSInteger index = [self caculateIndex:self.currentIndexPath.row];
        self.currentIndexPath = [NSIndexPath indexPathForRow:origin.row + index inSection:origin.section];
        [self.carouselView scrollToItemAtIndexPath:self.currentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        self.carouselView.userInteractionEnabled = YES;
    }
}

- (void)pageControlClick:(UIPageControl *)sender {
    if (![sender isKindOfClass:[UIPageControl class]]) {
        return;
    }
    NSInteger page = sender.currentPage;
    NSInteger prePage = [self caculateIndex:self.currentIndexPath.row];
    if(page == prePage) {
        return;
    }
    NSIndexPath *indexPath = nil;
    if(prePage - page == [self numbers] - 1) {
        //最后一张跳到第一张
        indexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + 1 inSection:0];
    }else if(page - prePage == [self numbers] - 1) {
        //第一张跳到最后一张
        indexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row - 1 inSection:0];
    }else {
        indexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + page - prePage inSection:0];
    }
    [self.carouselView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    self.currentIndexPath = indexPath;
}

/**
 实际下标转换成业务需求下标

 @param factIndex 实际下标
 @return 业务需求下标
 */
- (NSInteger)caculateIndex:(NSInteger)factIndex {
    if (self.numbers <= 0) {
        return 0;
    }
    NSInteger row = factIndex % [self numbers];
    if(!self.endless && self.flowLayout.style != CWCarouselStyle_Normal)
    {
        row = factIndex % [self infactNumbers] - 1;
    }
    return row;
}

- (void)adjustErrorCell:(BOOL)isScroll {
    NSArray <NSIndexPath *> *indexPaths = [self.carouselView indexPathsForVisibleItems];
    NSMutableArray <UICollectionViewLayoutAttributes *> *attriArr = [NSMutableArray arrayWithCapacity:indexPaths.count];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UICollectionViewLayoutAttributes *attri = [self.carouselView layoutAttributesForItemAtIndexPath:obj];
        [attriArr addObject:attri];
    }];
    CGFloat centerX = self.carouselView.contentOffset.x + CGRectGetWidth(self.carouselView.frame) * 0.5;
    __block CGFloat minSpace = MAXFLOAT;
    BOOL shouldSet = YES;
    if (self.flowLayout.style != CWCarouselStyle_Normal && indexPaths.count <= 2)
    {
        shouldSet = NO;
    }
    [attriArr enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.zIndex = 0;
        if(ABS(minSpace) > ABS(obj.center.x - centerX) && shouldSet) {
            minSpace = obj.center.x - centerX;
            self.currentIndexPath = obj.indexPath;
        }
    }];
    if(isScroll) {
        [self scrollViewWillBeginDecelerating:self.carouselView];
    }
}

- (void)play {
    [self stop];
    if(self.isPause) {
        return;
    }
    [self performSelector:@selector(nextCell) withObject:nil afterDelay:self.autoTimInterval];
}

- (void)nextCell {
    if([self numbers] <= 0) {
        return;
    }
    NSInteger maxIndex = 1;
    if(!self.endless && self.flowLayout.style != CWCarouselStyle_Normal)
    {
        maxIndex = 2;
    }
    if(self.currentIndexPath.row < [self infactNumbers] - maxIndex)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + 1 inSection:self.currentIndexPath.section];
        [self.carouselView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        self.currentIndexPath = indexPath;
    }
    else if(!self.endless)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:maxIndex - 1 inSection:self.currentIndexPath.section];
        [self.carouselView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        self.currentIndexPath = indexPath;
    }
    [self performSelector:@selector(nextCell) withObject:nil afterDelay:self.autoTimInterval];
}

- (void)stop {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(nextCell) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)resumePlay {
    self.isPause = NO;
    [self play];
}

- (void)pause {
    self.isPause = YES;
    [self stop];
}

- (void)releaseTimer {
    [self stop];
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
    if(!self.endless
       && self.flowLayout.style != CWCarouselStyle_Normal
       && (indexPath.row == 0 || indexPath.row == [self infactNumbers] - 1))
    {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"tempCell" forIndexPath:indexPath];
        cell.contentView.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else
    {
        if(self.datasource &&
           [self.datasource respondsToSelector:@selector(viewForCarousel:indexPath:index:)])
        {
            UICollectionViewCell *cell = [self.datasource viewForCarousel:self indexPath:indexPath index:[self caculateIndex:indexPath.row]];
            return cell;
        }
        return nil;
    }
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if([self numbers] > 0)
        return [self infactNumbers];
    else
        return 0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(CWCarousel:didSelectedAtIndex:)]) {
        [self.delegate CWCarousel:self didSelectedAtIndex:[self caculateIndex:indexPath.row]];
    }
    // 处于动画中时,点击cell,可能会出现cell不居中问题.这里处理下
    // 将里中心点最近的那个cell居中
    [self adjustErrorCell:YES];
}

#pragma mark - <setter>
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.carouselView.backgroundColor = backgroundColor;
    [super setBackgroundColor:backgroundColor];
}
- (void)setCurrentIndexPath:(NSIndexPath *)currentIndexPath {
    _currentIndexPath = currentIndexPath;
    if(self.customPageControl == nil)
        self.pageControl.currentPage = [self caculateIndex:currentIndexPath.row];
    else
        self.customPageControl.currentPage = [self caculateIndex:currentIndexPath.row];
}

- (void)setEndless:(BOOL)endless {
    if(_endless != endless)
    {
        _endless = endless;
    }
}

#pragma mark - < getter >
- (UICollectionView *)carouselView {
    if(!_carouselView) {
//        self.carouselView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.addHeight * 0.5, self.frame.size.width, self.frame.size.height - self.addHeight) collectionViewLayout:self.flowLayout];
        self.carouselView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        _carouselView.clipsToBounds = NO;
        _carouselView.delegate = self;
        _carouselView.dataSource = self;
        _carouselView.translatesAutoresizingMaskIntoConstraints = NO;
        [_carouselView registerClass:[CWTempleteCell class] forCellWithReuseIdentifier:@"tempCell"];
        [self addSubview:_carouselView];
        
        NSDictionary *views = @{@"view" : self.carouselView};
        NSDictionary *margins = @{@"top" : @(self.addHeight * 0.5),
                                  @"bottom" : @(self.addHeight * 0.5)
                                  };
        NSString *str = @"H:|-0-[view]-0-|";
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:str
                                                                     options:kNilOptions
                                                                     metrics:margins
                                                                       views:views]];
        str = @"V:|-top-[view]-top-|";
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:str
                                                                     options:kNilOptions
                                                                     metrics:margins
                                                                       views:views]];
    }
    return _carouselView;
}


- (CWCarouselStyle)style {
    if(self.flowLayout)
    {
        return self.flowLayout.style;
    }
    return CWCarouselStyle_Unknow;
}


/**
 Description

 @return 业务需求需要展示轮播图个数
 */
- (NSInteger)numbers {
    if(self.datasource &&
       [self.datasource respondsToSelector:@selector(numbersForCarousel)]) {
        self.pageControl.numberOfPages = [self.datasource numbersForCarousel];
        return self.pageControl.numberOfPages;
    }
    return 0;
}

/**
 轮播图实际加载视图个数

 @return 轮播图实际加载视图个数
 */
- (NSInteger)infactNumbers {
    if (self.endless)
    {
        return 300;
    }
    else
    {
        if(self.flowLayout.style == CWCarouselStyle_Normal)
        {
            return [self numbers];
        }
        else
        {
            // 前后2个占位cell,所以+2
            return [self numbers] + 2;
        }
    }
}

- (UIPageControl *)pageControl {
    if(!_pageControl) {
        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
        CGPoint center = self.center;
        center.y = CGRectGetHeight(self.frame) - 30 * 0.5;
        _pageControl.pageIndicatorTintColor = [UIColor blackColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageControl.userInteractionEnabled = NO;
        [_pageControl addTarget:self action:@selector(pageControlClick:) forControlEvents:UIControlEventTouchUpInside];
        _pageControl.center = center;
    }
    return _pageControl;
}

- (NSString *)version {
    return @"1.1.5";
}

#pragma mark - Setter
- (void)setCustomPageControl:(UIView<CWCarouselPageControlProtocol> *)customPageControl {
    _customPageControl = customPageControl;
    if(_customPageControl && _customPageControl.superview == nil)
    {
        [self addSubview:_customPageControl];
        [self bringSubviewToFront:_customPageControl];
        if(self.pageControl.superview == _customPageControl.superview)
        {
            [self.pageControl removeFromSuperview];
        }
    }
}
@end


