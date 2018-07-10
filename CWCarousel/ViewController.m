//
//  ViewController.m
//  CWCarousel
//
//  Created by WangChen on 2018/4/3.
//  Copyright © 2018年 ChenWang. All rights reserved.
//

#import "ViewController.h"
#import "CWCarousel.h"

#define kViewTag 666
#define kCount 5

@interface ViewController ()<CWCarouselDatasource, CWCarouselDelegate>

@property (nonatomic, strong) CWCarousel *carousel;
@property (nonatomic, strong) UIView *animationView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createButtons];
//    [self configureUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self.carousel.isAuto) {
        [self.carousel resumePlay];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(self.carousel.isAuto) {
        [self.carousel pause];
    }
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

- (void)configureUI:(NSInteger)tag {
    CATransition *tr = [CATransition animation];
    tr.type = @"cube";
    tr.subtype = kCATransitionFromRight;
    tr.duration = 0.25;
    [self.animationView.layer addAnimation:tr forKey:nil];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if(self.carousel) {
        [self.carousel removeFromSuperview];
        self.carousel = nil;
    }
    
    self.animationView.backgroundColor = [UIColor whiteColor];
    CWFlowLayout *flowLayout = [[CWFlowLayout alloc] initWithStyle:[self styleFromTag:tag]];
    CWCarousel *carousel = [[CWCarousel alloc] initWithFrame:self.animationView.bounds
                                                    delegate:self
                                                  datasource:self
                                                  flowLayout:flowLayout];
    carousel.isAuto = YES;
    carousel.backgroundColor = [UIColor whiteColor];
    [self.animationView addSubview:carousel];
    [carousel registerViewClass:[UICollectionViewCell class] identifier:@"cellId"];
    [carousel freshCarousel];
    self.carousel = carousel;
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
    NSString *name = [NSString stringWithFormat:@"%02ld.jpg", index + 1];
    UIImage *img = [UIImage imageNamed:name];
    if(!img) {
        NSLog(@"%@", name);
    }
    [imgView setImage:img];
    return cell;
}

- (void)CWCarousel:(CWCarousel *)carousel didSelectedAtIndex:(NSInteger)index {
    NSLog(@"...%ld...", index);
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
