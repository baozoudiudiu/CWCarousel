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
#define kCount 0

@interface ViewController ()<CWCarouselDatasource, CWCarouselDelegate>

@property (nonatomic, strong) CWCarousel *carousel;
@property (nonatomic, strong) UIView *animationView;
@property (nonatomic, assign) BOOL openCustomPageControl;
@property (nonatomic, weak) IBOutlet UISwitch *cusSwitch;

/// 数据源
@property (nonatomic, strong) NSArray   *dataArr;
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
    self.dataArr = nil;
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
    flowLayout.itemSpace_H = 30;
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
    self.animationView.clipsToBounds = YES;
    
    carousel.isAuto = NO;
    carousel.autoTimInterval = 2;
    carousel.endless = YES;
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
    self.carousel = carousel;
    [self requestNetworkData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.carousel controllerWillAppear];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.carousel controllerWillDisAppear];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.carousel scrollTo:4 animation:NO];
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
    if (self.carousel)
    {
        [self configureUI:self.carousel.flowLayout.style - 1];
    }
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
            button.frame = CGRectMake(0, height * index + [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height + 10, CGRectGetWidth(self.view.frame), height);
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

#pragma mark - 网络层
- (void)requestNetworkData {
    // 模拟网络请求
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *arr = [NSMutableArray array];
        NSString *imgName = @"";
        for (int i = 0; i < 5; i++) {
            imgName = [NSString stringWithFormat:@"%02d.jpg", i + 1];
            [arr addObject:imgName];
        }
        self.dataArr = arr;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.carousel freshCarousel];
        });
    });
}

#pragma mark - Delegate
- (NSInteger)numbersForCarousel {
//    return kCount;
    return self.dataArr.count;
}

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
    
//    NSString *name = [NSString stringWithFormat:@"%02ld.jpg", index + 1];
    NSString *name = self.dataArr[index];
    UIImage *img = [UIImage imageNamed:name];
    if(!img) {
        NSLog(@"%@", name);
    }
    [imgView setImage:img];
    return cell;
}

- (void)CWCarousel:(CWCarousel *)carousel didSelectedAtIndex:(NSInteger)index {
    
}


- (void)CWCarousel:(CWCarousel *)carousel didStartScrollAtIndex:(NSInteger)index indexPathRow:(NSInteger)indexPathRow {
    
}


- (void)CWCarousel:(CWCarousel *)carousel didEndScrollAtIndex:(NSInteger)index indexPathRow:(NSInteger)indexPathRow {
    
}


#pragma mark - Setter && Getter
- (UIView *)animationView{
    if(!_animationView) {
        self.animationView = [[UIView alloc] initWithFrame:CGRectMake(0, 250, CGRectGetWidth(self.view.frame), 230)];
    }
    return _animationView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
