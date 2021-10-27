//
//  CWCarousel.m
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import "CWCarousel.h"

@interface CWCarouselCollectionView()
@property (nonatomic, copy)  void (^ _Nullable tapCallback) (void);
@end


@implementation CWCarouselCollectionView
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    if(self = [super initWithFrame:frame collectionViewLayout:layout]) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
        tap.delegate = self;
    }
    return self;
}

- (void)tapAction:(UITapGestureRecognizer *)tap {
    if (!self.tapCallback) {
        return;
    }
    self.tapCallback();
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] == NO) {
        return YES;
    }
    
    if ([[touch view] isKindOfClass:[UICollectionView class]]) {
        return YES;
    }
    
    return NO;
}

- (void)dealloc {
    NSLog(@"[CWCarouselCollectionView dealloc]");
}
@end


@interface CWTempleteCell: UICollectionViewCell
@end

@implementation CWTempleteCell
@end


@interface MyProxy : NSProxy
@property (nonatomic, weak) id _Nullable target;
- (instancetype)init:(id)target;
@end

@implementation MyProxy
- (instancetype)init:(id)target {
    self.target = target;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}

@end


@interface CWCarousel ()<UICollectionViewDelegate, UICollectionViewDataSource> {
    
}
/// collectionView
@property (nonatomic, strong) CWCarouselCollectionView *carouselView;
/// 轮播总数
@property (nonatomic, assign) NSInteger        numbers;
/// 当前居中的业务逻辑下标
@property (nonatomic, assign) NSInteger        currentIndex;
/// 当前居中的实际下标
@property (nonatomic, assign) NSInteger        infactIndex;
/// (已经废弃)
@property (nonatomic, assign) CGFloat          addHeight;
/**
 自动播放是否暂停
 */
@property (nonatomic, assign) BOOL             isPause;

/**
 当前展示在中间的cell下标
 */
@property (nonatomic, strong) NSIndexPath      *currentIndexPath;

@property (nonatomic, strong) MyProxy          *timerProxy;
@property (nonatomic, strong) NSTimer          *timer;

@end
@implementation CWCarousel
@synthesize carouselView = _carouselView;


- (instancetype)initWithFrame:(CGRect)frame delegate:(id<CWCarouselDelegate>)delegate datasource:(id<CWCarouselDatasource>)datasource flowLayout:(CWFlowLayout *)flowLayout {
    CGFloat addHeight = 0;
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
        [self addNotify];
    }
    NSAssert(self != nil, @"CWCarousel 初始化失败!");
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
    [self addNotify];
    [self adjustErrorCell:YES];
}

- (void)controllerWillDisAppear {
    if(self.isAuto) {
        [self pause];
    }
    [self removeNotify];
    [self adjustErrorCell:YES];
}

- (void)addNotify {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeInactive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)removeNotify {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)dealloc {
    NSLog(@"[CWCarousel dealloc]");
    [self removeNotify];
    [self releaseTimer];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (nil == self.customPageControl && nil == self.pageControl.superview) {
        [self configurePageControl];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (nil == self.customPageControl && nil == self.pageControl.superview) {
        [self configurePageControl];
    }
}

- (void)registerViewClass:(Class)viewClass identifier:(NSString *)identifier {
    [self.carouselView registerClass:viewClass forCellWithReuseIdentifier:identifier];
}

- (void)registerNibView:(NSString *)nibName identifier:(NSString *)identifier {
    [self.carouselView registerNib:[UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]]
        forCellWithReuseIdentifier:identifier];
}

- (void)freshCarousel {
    
    if([self numbers] < 0) {
        return;
    }
    
    [self.carouselView reloadData];
    [self layoutIfNeeded];
    
    if (self.endless)
        [self.carouselView scrollToItemAtIndexPath:[self originIndexPath] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    else {
        if(self.flowLayout.style == CWCarouselStyle_Normal) {
            [self.carouselView scrollToItemAtIndexPath:self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
        else {
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
    if (@available(iOS 14.0, *)) {
        scrollView.pagingEnabled = NO;
    } else {
        scrollView.pagingEnabled = YES;
    }
    if (self.isAuto) {
        [self stop];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(CWCarousel:didStartScrollAtIndex:indexPathRow:)]) {
        [self.delegate CWCarousel:self didStartScrollAtIndex:[self caculateIndex:self.currentIndexPath.row] indexPathRow:self.currentIndexPath.row];
    }
}

/// 将要结束拖拽
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    NSInteger num = [self numbers];
    
    if (num <= 0) {
        return;
    }
    
    if (self.endless == NO)
    {
        // 非无限轮播
        NSInteger maxIndex = num - 1;
        NSInteger minIndex = 0;
        if(self.flowLayout.style != CWCarouselStyle_Normal)
        {
            // 后面有一个占位cell, 所以减2, 不是减1
            maxIndex = [self infactNumbers] - 2;
            // 前面有一个占位cell, 所以下标是从1开始
            minIndex = 1;
        }
        if (velocity.x == 0) {
            [self velocityZero];
            return;
        }
        
        if (velocity.x >= 0 && self.currentIndexPath.row == maxIndex) {
            // 已经是最后一张了
            return;
        }
        
        if (velocity.x <= 0 && self.currentIndexPath.row == minIndex) {
            // 已经是第一张了
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
        [self velocityZero];
    }
}

/// 开始减速
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self cusScrollViewWillBeginDecelerating:YES scroll:scrollView];
}

- (void)cusScrollViewWillBeginDecelerating:(BOOL)animation scroll:(UIScrollView *)scrollView{
    
    if (self.currentIndexPath == nil) {
        return;
    }
    
    if (self.currentIndexPath.row >= [self infactNumbers]) {
        return;
    }
    
    if (self.currentIndexPath.row < 0) {
        return;
    }
    
    // 中间一张轮播,居中显示
    if (self.endless == NO)
    {
        // 非无限轮播, 非CWCarouselStyle_Normal样式下, 前后有两张占位cell, 这里需要处理一下.
        if (self.currentIndexPath.row == 0 && self.style != CWCarouselStyle_Normal) {
            
            self.currentIndexPath = [NSIndexPath indexPathForRow:1 inSection:self.currentIndexPath.section];
            
        }else if (self.currentIndexPath.row == [self infactNumbers] - 1 && self.style != CWCarouselStyle_Normal) {
            
            self.currentIndexPath = [NSIndexPath indexPathForRow:[self infactNumbers] - 2 inSection:self.currentIndexPath.section];
            
        }
    }
    
    [self.carouselView scrollToItemAtIndexPath:self.currentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animation];
    
    if (animation == NO) {
        [self cusScrollAnimationEnd:scrollView];
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
    
    [self cusScrollAnimationEnd:scrollView];
}

- (void)cusScrollAnimationEnd:(UIScrollView *)scrollView {
    // 滚动完成,打开交互,关掉pagingEnabled
    // 为什么要关掉pagingEnabled呢,因为切换控制器的时候会有系统级bug,不信你试试.
    scrollView.userInteractionEnabled = YES;
    scrollView.pagingEnabled = NO;
    
    if(self.isAuto) {
        [self play];
    }
    
    if (self.endless) {
        [self checkOutofBounds];
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(CWCarousel:didEndScrollAtIndex:indexPathRow:)]) {
        [self.delegate CWCarousel:self didEndScrollAtIndex:[self caculateIndex:self.currentIndexPath.row] indexPathRow:self.currentIndexPath.row];
    }
}

// 滚动中
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

#pragma mark - < Logic Helper >
- (NSIndexPath *)originIndexPath {
    
    NSInteger num = [self numbers];
    if (num <= 0) {
        return [[NSIndexPath alloc] initWithIndex:0];
    }
    
    if (self.endless == NO) {
        NSInteger row = self.flowLayout.style == CWCarouselStyle_Normal ? 0 : 1;
        self.currentIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
        return self.currentIndexPath;
    }
    
    NSInteger centerIndex = [self infactNumbers] / num; //一共有多少组
    
    if (centerIndex == 0) {
        // 异常, 一组都没有
        NSAssert(true, @"计算起始下标异常, 分组不足一组.");
        return self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    if (centerIndex == 1) {
        return self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
        
    // 取中间一组展示
    self.currentIndexPath = [NSIndexPath indexPathForRow:centerIndex / 2 * num inSection:0];
    return self.currentIndexPath;
}

// 检测是否到了边界
- (void)checkOutofBounds {
    if ([self numbers] <= 0) {return;}
    
    BOOL scroll = NO;
    NSInteger index = self.currentIndex;
    
    // 越界检查
    if(self.currentIndexPath.row == [self infactNumbers] - 1) {
        index = [self caculateIndex:self.currentIndexPath.row] - 1; //最后一张
        scroll = YES;
    }else if(self.currentIndexPath.row == 0) {
        index = [self caculateIndex:self.currentIndexPath.row]; //第一张
        scroll = YES;
    }
    
    self.carouselView.userInteractionEnabled = YES;
    if (scroll == NO) {
        return;
    }
    
    NSIndexPath *origin = [self originIndexPath];
    self.currentIndexPath = [NSIndexPath indexPathForRow:origin.row + index inSection:origin.section];
    [self.carouselView scrollToItemAtIndexPath:self.currentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

/**
 实际下标转换成业务需求下标

 @param factIndex 实际下标
 @return 业务需求下标
 */
- (NSInteger)caculateIndex:(NSInteger)factIndex {
    NSInteger num = [self numbers];
    if (num <= 0) {
        return 0;
    }
    NSInteger row = factIndex % num;
    if(self.endless == NO && self.flowLayout.style != CWCarouselStyle_Normal) {
        // 这种情况有占位cell
        row = factIndex % [self infactNumbers] - 1;
    }
    return row;
}

- (void)adjustErrorCell:(BOOL)isScroll {
    NSArray <NSIndexPath *> *indexPaths = [self.carouselView indexPathsForVisibleItems];
    CGFloat centerX = self.carouselView.contentOffset.x + CGRectGetWidth(self.carouselView.frame) * 0.5;
    __block CGFloat minSpace = MAXFLOAT;
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UICollectionViewLayoutAttributes *attri = [self.carouselView layoutAttributesForItemAtIndexPath:obj];
        attri.zIndex = 0;
        if(ABS(minSpace) > ABS(attri.center.x - centerX)) {
            minSpace = attri.center.x - centerX;
            self.currentIndexPath = attri.indexPath;
        }
    }];
    if(isScroll) {
        [self scrollViewWillBeginDecelerating:self.carouselView];
    }
}

/// velocity == 0时的处理
- (void)velocityZero {
    // 还有一种情况,当滑动后手指按住不放,然后松开,此时的加速度其实是为0的
    [self adjustErrorCell:NO];
    if (@available(iOS 14.0, *)) {
        // iOS14以前,就算加速度为0,后续系统会还是会走scrollViewWillBeginDecelerating:回调
        // 但是iOS14以后,加速度为0时,不会在后续执行回调.这里手动触发一下
        [self scrollViewWillBeginDecelerating:self.carouselView];
    }
}

- (void)play {
    if(self.isPause) {
        return;
    }
    
    if (NO == self.isAuto) {
        return;
    }
    
    if (self.timer) {
        [self resumePlay];
        return;
    }
    self.timer = [NSTimer timerWithTimeInterval:self.autoTimInterval target:self.timerProxy selector:@selector(nextCell) userInfo:nil repeats:YES];
    [self.timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.autoTimInterval]];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)nextCell {
    
    if([self numbers] <= 0) {
        return;
    }
    
    if (!self.isAuto) {
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
}

- (void)stop {
    if (!self.timer) {
        return;
    }
    [self.timer setFireDate:[NSDate distantFuture]];
}

- (void)resumePlay {
    self.isPause = NO;
    if (self.timer) {
        [self.timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.autoTimInterval]];
        return;
    }
    [self play];
}

- (void)pause {
    self.isPause = YES;
    [self stop];
}

- (void)releaseTimer {
//    [self stop];
    if (!self.timer) {
        return;
    }
    [self.timer setFireDate:[NSDate distantFuture]];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)scrollTo:(NSInteger)index animation:(BOOL)animation {
    
    if (index < 0 || index >= [self numbers]) {
        // 防止越界
        return;
    }
    
    [self stop];

    if (index == self.currentIndex) {
        [self play];
        return;
    }
    
    self.currentIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + (index - self.currentIndex) inSection:0];
    [self cusScrollViewWillBeginDecelerating:animation scroll:self.carouselView];
}

- (void)configurePageControl {
    UIView *control = self.customPageControl;
    BOOL isDefault = NO;
    
    if (nil == control || NO == [control isKindOfClass:[UIView class]]) {
        control = self.pageControl;
        isDefault = YES;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(CWCarousel:addPageControl:isDefault:)]) {
        [self.delegate CWCarousel:self addPageControl:control isDefault:isDefault];
        return;
    }
    
    [self addSubview:control];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[control(20)]-0-|"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:@{@"control" : control}]];
    [[control.centerXAnchor constraintEqualToAnchor:self.centerXAnchor] setActive:YES];
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
        
    __weak __typeof(&*self) weakSelf = self;
    
    UICollectionViewCell* (^returnCell)(NSIndexPath *) = ^UICollectionViewCell* (NSIndexPath *idx) {
        if (self.datasource && [self.datasource respondsToSelector:@selector(viewForCarousel:indexPath:index:)]) {
            UICollectionViewCell *cell = [weakSelf.datasource viewForCarousel:weakSelf indexPath:indexPath index:[weakSelf caculateIndex:indexPath.row]];
            return cell;
        }
        return nil;
    };
    
    
    if (self.endless) {
        return returnCell(indexPath);
    }
    
    if (self.flowLayout.style != CWCarouselStyle_Normal
        && (indexPath.row == 0 || indexPath.row == [self infactNumbers] - 1)) {
        // 非无限轮播情况下, "第一个"和"最后一个"是占位cell
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"tempCell" forIndexPath:indexPath];
        cell.contentView.backgroundColor = [UIColor clearColor];
        return cell;
    }
    
    return returnCell(indexPath);
    
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self infactNumbers];
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
    
    if (_currentIndexPath) {
        self.currentIndex = [self caculateIndex:_currentIndexPath.row];
    }

    if(self.customPageControl == nil)
        self.pageControl.currentPage = [self caculateIndex:currentIndexPath.row];
    else
        self.customPageControl.currentPage = [self caculateIndex:currentIndexPath.row];
}

- (void)setEndless:(BOOL)endless {
    if(_endless != endless) {
        _endless = endless;
    }
}

- (void)setCustomPageControl:(UIView<CWCarouselPageControlProtocol> *)customPageControl {
    
    if (_customPageControl == customPageControl) {
        return;
    }
    
    if (_customPageControl) {
        [_customPageControl removeFromSuperview];
    }
    
    _customPageControl = customPageControl;
    if (customPageControl && self.pageControl) {
        [self.pageControl removeFromSuperview];
        self.pageControl = nil;
    }
    
    [self configurePageControl];
}

#pragma mark - < getter >
- (UICollectionView *)carouselView {
    if(!_carouselView) {
        self.carouselView = [[CWCarouselCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
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
        
        __weak __typeof(&*self) weakSelf = self;
        [_carouselView setTapCallback:^{
            [weakSelf adjustErrorCell:YES];
        }];
    }
    return _carouselView;
}


- (CWCarouselStyle)style {
    if(self.flowLayout) {
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
        NSInteger num = [self.datasource numbersForCarousel];
        if (self.pageControl) {
            self.pageControl.numberOfPages = num;
        }
        if (self.customPageControl) {
            self.customPageControl.pageNumbers = num;
        }
        return num;
    }
    return 0;
}

/**
 轮播图实际加载视图个数

 @return 轮播图实际加载视图个数
 */
- (NSInteger)infactNumbers {
    
    NSInteger num = [self numbers];
    
    if ( num <= 0) {
        return 0;
    }

    [self.carouselView setScrollEnabled:YES];
    
    if (self.endless) {
        // 无限轮播
        if (num == 1) {
            // 只有一张, 不让滚动
            [self.carouselView setScrollEnabled:NO];
            return num;
        }
        // 不止一张, 默认加载300个 (cell有复用机制, 不用担心)
        return 300;
    }
    
    // 非无限轮播, 除了第一种样式, 其他的样式要加2个占位空cell
    if(self.flowLayout.style == CWCarouselStyle_Normal) {
        return num;
    }
    
    if (num == 1) {
        [self.carouselView setScrollEnabled:NO];
    }
    // 前后2个占位cell,所以+2
    return num + 2;
}

- (UIPageControl *)pageControl {
    if(!_pageControl) {
        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
        _pageControl.pageIndicatorTintColor = [UIColor blackColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageControl.userInteractionEnabled = NO;
    }
    return _pageControl;
}

- (MyProxy *)timerProxy {
    if (!_timerProxy) {
        self.timerProxy = [[MyProxy alloc] init:self];
    }
    return _timerProxy;
}

- (NSString *)version {
    return @"1.1.9";
}
@end




