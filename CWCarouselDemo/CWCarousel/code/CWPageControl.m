//
//  CWPageControl.m
//  CWCarousel
//
//  Created by chenwang on 2018/7/16.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import "CWPageControl.h"
@interface CWPageControl () {
    
}
@property (nonatomic, assign) NSInteger myPageNumbers;
@property (nonatomic, assign) NSInteger myCurrentPage;

@property (nonatomic, strong) NSArray<UIView *> *indicatorArr;
@property (nonatomic, strong) UIView    *currentIndicator;
@end
@implementation CWPageControl
@synthesize currentPage;
@synthesize pageNumbers;
#pragma mark - INITIAL
- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self configureView];
    }
    return self;
}
#pragma mark - PROPERTY
- (void)setCurrentPage:(NSInteger)currentPage {
    self.myCurrentPage = currentPage;
    if (currentPage >= self.indicatorArr.count) {
        return;
    }
    UIView *indicator = self.indicatorArr[currentPage];
    [UIView animateWithDuration:0.25 animations:^{
        self.currentIndicator.frame = indicator.frame;
    }];
    
}
- (void)setPageNumbers:(NSInteger)pageNumbers {
    self.myPageNumbers = pageNumbers;
    [self createIndicator];
}
- (NSInteger)currentPage {
    return self.currentPage;
}
- (NSInteger)pageNumbers {
    return self.myPageNumbers;
}
#pragma mark - LOGIC HELPER
- (void)configureView {
    
}

- (void)createIndicator {
    CGFloat width = 25;
    CGFloat height = 7;
    CGFloat space = 2;
    CGFloat containerWidth = (width + space) * self.pageNumbers - space;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.frame) - containerWidth) * 0.5, 0, containerWidth, CGRectGetHeight(self.frame))];
    [self addSubview:container];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:self.pageNumbers];
    for(int i = 0; i < self.pageNumbers; i ++) {
        CGFloat y = (CGRectGetHeight(self.frame) - height) * 0.5;
        CGFloat x = (width + space) * i;
        UIView *indictor = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        [container addSubview:indictor];
        indictor.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [arr addObject:indictor];
        if(i == 0) {
            self.currentIndicator = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
            [container addSubview:self.currentIndicator];
            self.currentIndicator.backgroundColor = [UIColor redColor];
            self.currentIndicator.layer.zPosition = 999;
        }
    }
    self.indicatorArr = [NSArray arrayWithArray:arr];
}
@end
