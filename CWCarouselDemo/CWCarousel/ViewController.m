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
@property (nonatomic, assign) BOOL openCustomPageControl;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic, strong) NSArray   *dataArr;
@property (weak, nonatomic) IBOutlet UISegmentedControl *styleSegment;
@property (weak, nonatomic) IBOutlet UISwitch   *endlessSwitch;
@property (weak, nonatomic) IBOutlet UISwitch   *autoSwitch;
@property (weak, nonatomic) IBOutlet UILabel    *spaceLab;
@property (weak, nonatomic) IBOutlet UIStepper  *spaceSteper;
@property (weak, nonatomic) IBOutlet UISwitch   *cusPageControlSwitch;
@end

@implementation ViewController
- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"demo";
    [self configureUI:0];
}

- (void)configureUI:(NSInteger)tag {
    self.dataArr = nil;
    CATransition *tr = [CATransition animation];
    tr.type = @"cube";
    tr.subtype = kCATransitionFromRight;
    tr.duration = 0.25;
    [self.contentView.layer addAnimation:tr forKey:nil];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if(self.carousel) {
        [self.carousel releaseTimer];
        [self.carousel removeFromSuperview];
        self.carousel = nil;
    }
    
    CWFlowLayout *flowLayout = [[CWFlowLayout alloc] initWithStyle:[self styleFromTag:tag]];
    flowLayout.itemSpace_H = 0;
    self.spaceLab.text = @"0";
    self.spaceSteper.value = 0;
    if (flowLayout.style == CWCarouselStyle_H_3) {
        flowLayout.itemSpace_H = -10;
        self.spaceLab.text = @"-10";
        self.spaceSteper.value = -10;
    }
    // 使用layout创建视图(使用masonry 或者 系统api)
    CWCarousel *carousel = [[CWCarousel alloc] initWithFrame:CGRectZero
                                                    delegate:self
                                                  datasource:self
                                                  flowLayout:flowLayout];
    carousel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:carousel];
    NSDictionary *dic = @{@"view" : carousel};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
                                                                               options:kNilOptions
                                                                               metrics:nil
                                                                                 views:dic]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
                                                                               options:kNilOptions
                                                                               metrics:nil
                                                                                 views:dic]];
    carousel.isAuto = self.autoSwitch.isOn;
    carousel.autoTimInterval = 2;
    carousel.endless = self.endlessSwitch.isOn;
    carousel.backgroundColor = [UIColor whiteColor];
    [carousel registerViewClass:[UICollectionViewCell class] identifier:@"cellId"];
    self.carousel = carousel;
    
    if (self.cusPageControlSwitch.isOn) {
        [self setPageControl];
    }
    
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


#pragma mark - < 事件响应 >
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

- (IBAction)styleChanged:(UISegmentedControl *)sender {
    [self configureUI:sender.selectedSegmentIndex];
}

- (IBAction)endlessChanged:(UISwitch *)sender {
    self.carousel.endless = sender.isOn;
    [self.carousel freshCarousel];
}

- (IBAction)autoChanged:(UISwitch *)sender {
    self.carousel.isAuto = sender.isOn;
    [self.carousel freshCarousel];
}

- (IBAction)spaceChanged:(UIStepper *)sender {
    self.carousel.flowLayout.itemSpace_H = sender.value;
    self.spaceLab.text = [NSString stringWithFormat:@"%.0f", sender.value];
    [self.carousel freshCarousel];
}

- (IBAction)customPageControlChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [self setPageControl];
    }else {
        self.carousel.customPageControl = nil;
    }
    [self.carousel freshCarousel];
}

- (void)setPageControl {
    CGFloat width = [CWPageControl widthFromNumber:self.dataArr.count];
    CWPageControl *pageC = [[CWPageControl alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    pageC.translatesAutoresizingMaskIntoConstraints = NO;
    [[pageC.widthAnchor constraintEqualToConstant:width] setActive:YES];
    /**
     这里我自己给了宽度, 所以就不再自定义布局代理:
        - (void)CWCarousel:(CWCarousel *)carousel addPageControl:(UIView *)pageControl;
     */
    self.carousel.customPageControl = pageC;
}

- (IBAction)buttonClick {
    [self.carousel scrollTo:2 animation:YES];
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
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        [cell.contentView addSubview:imgView];
        cell.layer.masksToBounds = YES;
        cell.layer.cornerRadius = 8;
    }
//    https://www.google.com/url?sa=i&rct=j&q=&esrc=s&source=images&cd=&cad=rja&uact=8&ved=2ahUKEwio8MyTp-DdAhWKM94KHUmEDcAQjRx6BAgBEAU&url=http%3A%2F%2F699pic.com%2Ftupian%2Fchuan.html&psig=AOvVaw20gpsPpW4JcNm0mJi9dYrb&ust=1538313533814128
    
    NSString *name = self.dataArr[index];
    UIImage *img = [UIImage imageNamed:name];
    if(!img) {
        NSLog(@"%@", name);
    }
    [imgView setImage:img];
    return cell;
}

- (void)CWCarousel:(CWCarousel *)carousel didSelectedAtIndex:(NSInteger)index {
    NSLog(@"did selected at index %ld", index);
}


- (void)CWCarousel:(CWCarousel *)carousel didStartScrollAtIndex:(NSInteger)index indexPathRow:(NSInteger)indexPathRow {
    
}


- (void)CWCarousel:(CWCarousel *)carousel didEndScrollAtIndex:(NSInteger)index indexPathRow:(NSInteger)indexPathRow {
    
}


#pragma mark - Setter && Getter
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
