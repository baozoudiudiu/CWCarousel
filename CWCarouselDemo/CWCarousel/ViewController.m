//
//  ViewController.m
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import "ViewController.h"
#import "CWCarousel.h"
#import "CWPageControl.h"

#define kViewTag 666
#define kCount 5

@interface ViewController ()<CWCarouselDatasource, CWCarouselDelegate>

@property (nonatomic, strong) CWCarousel *carousel;
@property (nonatomic, strong) UIView *animationView;
@property (nonatomic, assign) BOOL openCustomPageControl;
@property (nonatomic, weak) IBOutlet UISwitch *cusSwitch;
@end

@implementation ViewController
- (void)dealloc {
    NSLog(@"%s", __func__);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self createButtons];
    [self.cusSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
}
- (void)configureUI:(NSInteger)tag {
    CATransition *tr = [CATransition animation];
    tr.type = @"cube";
    tr.subtype = kCATransitionFromRight;
    tr.duration = 0.25;
    [self.animationView.layer addAnimation:tr forKey:nil];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if(self.carousel) {
        [self.carousel releaseTimer];
        [self.carousel removeFromSuperview];
        self.carousel = nil;
    }
    
    self.animationView.backgroundColor = [UIColor whiteColor];
    CWFlowLayout *flowLayout = [[CWFlowLayout alloc] initWithStyle:[self styleFromTag:tag]];
    
//    /*
//     使用frame创建视图
//     */
//    CWCarousel *carousel = [[CWCarousel alloc] initWithFrame:self.animationView.bounds
//                                                    delegate:self
//                                                  datasource:self
//                                                  flowLayout:flowLayout];
//    [self.animationView addSubview:carousel];
    
    // 使用layout创建视图(使用masonry 或者 系统api)
    CWCarousel *carousel = [[CWCarousel alloc] initWithFrame:CGRectZero
                                                    delegate:self
                                                  datasource:self
                                                  flowLayout:flowLayout];
    carousel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.animationView addSubview:carousel];
    NSDictionary *dic = @{@"view" : carousel};
    [self.animationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
                                                                               options:kNilOptions
                                                                               metrics:nil
                                                                                 views:dic]];
    [self.animationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
                                                                               options:kNilOptions
                                                                               metrics:nil
                                                                                 views:dic]];
    
    
    carousel.isAuto = NO;
    carousel.autoTimInterval = 2;
    carousel.endless = NO;
    carousel.backgroundColor = [UIColor whiteColor];
    
    /* 自定pageControl */
    
    CGRect frame = self.animationView.bounds;
    if(self.openCustomPageControl) {
        CWPageControl *control = [[CWPageControl alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
        control.center = CGPointMake(CGRectGetWidth(frame) * 0.5, CGRectGetHeight(frame) - 10);
        control.pageNumbers = 5;
        control.currentPage = 0;
        carousel.customPageControl = control;
    }
    [carousel registerViewClass:[UICollectionViewCell class] identifier:@"cellId"];
    [carousel freshCarousel];
    self.carousel = carousel;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.carousel controllerWillAppear];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.carousel controllerWillDisAppear];
}
#pragma mark - < 事件响应 >
- (void)buttonClick:(UIButton *)sender {
    static NSInteger tag = -1;
    if(tag == sender.tag) {
        return;
    }
    tag = sender.tag;
    [self configureUI:tag];
}
- (void)switchChanged:(UISwitch *)switchSender {
    self.openCustomPageControl = switchSender.on;
}
- (void)createButtons {
    NSArray *titles = @[@"正常样式", @"横向滑动两边留白", @"横向滑动两边留白渐变效果", @"两边被遮挡效果"];
    CGFloat height = 40;
    dispatch_apply(4, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view addSubview:button];
            [button setTitle:titles[index] forState:UIControlStateNormal];
            button.tag = index;
            button.frame = CGRectMake(0, height * index + 60, CGRectGetWidth(self.view.frame), height);
            [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        });
    });
    [self.view addSubview:self.animationView];
}

- (CWCarouselStyle)styleFromTag:(NSInteger)tag {
    switch (tag) {
        case 0:
            return CWCarouselStyle_Normal;
            break;
        case 1:
            return CWCarouselStyle_H_1;
            break;
        case 2:
            return CWCarouselStyle_H_2;
            break;
        case 3:
            return CWCarouselStyle_H_3;
            break;
        default:
            return CWCarouselStyle_Unknow;
            break;
    }
}

- (NSInteger)numbersForCarousel {
    return kCount;
}

#pragma mark - Delegate
- (UICollectionViewCell *)viewForCarousel:(CWCarousel *)carousel indexPath:(NSIndexPath *)indexPath index:(NSInteger)index{
    UICollectionViewCell *cell = [carousel.carouselView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor cyanColor];
    UIImageView *imgView = [cell.contentView viewWithTag:kViewTag];
    if(!imgView) {
        imgView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
        imgView.tag = kViewTag;
        imgView.backgroundColor = [UIColor redColor];
        [cell.contentView addSubview:imgView];
        cell.layer.masksToBounds = YES;
        cell.layer.cornerRadius = 8;
    }
//    https://www.google.com/url?sa=i&rct=j&q=&esrc=s&source=images&cd=&cad=rja&uact=8&ved=2ahUKEwio8MyTp-DdAhWKM94KHUmEDcAQjRx6BAgBEAU&url=http%3A%2F%2F699pic.com%2Ftupian%2Fchuan.html&psig=AOvVaw20gpsPpW4JcNm0mJi9dYrb&ust=1538313533814128
    
    NSString *name = [NSString stringWithFormat:@"%02ld.jpg", index + 1];
    UIImage *img = [UIImage imageNamed:name];
    if(!img) {
        NSLog(@"%@", name);
    }
    [imgView setImage:img];
    return cell;
}

- (void)CWCarousel:(CWCarousel *)carousel didSelectedAtIndex:(NSInteger)index {
    NSLog(@"...%ld...", (long)index);
}

- (UIView *)animationView{
    if(!_animationView) {
        self.animationView = [[UIView alloc] initWithFrame:CGRectMake(0, 240, CGRectGetWidth(self.view.frame), 230)];
    }
    return _animationView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
