//
//  ViewController.m
//  XFRingChartView
//
//  Created by xfxb on 2020/7/1.
//  Copyright © 2020 xfxb. All rights reserved.
//

#import "ViewController.h"
#import "XFRingChartMoreView.h"
#import "XFRingChartLayerView.h"
@interface ViewController ()

@end
#define XFRGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
    [self createUI];
}
- (void)createUI
{
    NSArray *colorArray = @[XFRGBCOLOR(117,143,237),XFRGBCOLOR(212,230,239),XFRGBCOLOR(194,228,240),
     XFRGBCOLOR(164,222,234),XFRGBCOLOR(122,214,224),XFRGBCOLOR(130,169,240),
     XFRGBCOLOR(154,192,240),XFRGBCOLOR(188,213,238),XFRGBCOLOR(227, 233, 237)];
    NSArray *dataArray = @[
        @{@"name":@"京东到家",@"proportion":@"0.45",@"number":@"100",@"color":colorArray[0]},
        @{@"name":@"微商城",@"proportion":@"0.15",@"number":@"10",@"color":colorArray[1]},
        @{@"name":@"幸福送",@"proportion":@"0.15",@"number":@"40",@"color":colorArray[2]},
        @{@"name":@"门店收银",@"proportion":@"0.05",@"number":@"200",@"color":colorArray[3]},
        @{@"name":@"小程序",@"proportion":@"0.05",@"number":@"300",@"color":colorArray[4]},
        @{@"name":@"美团",@"proportion":@"0.05",@"number":@"600",@"color":colorArray[5]},
        @{@"name":@"饿了么",@"proportion":@"0.05",@"number":@"9000",@"color":colorArray[6]},
        @{@"name":@"幸福西饼GO APP",@"proportion":@"0.05",@"number":@"100",@"color":colorArray[7]}];
    //第一个
    XFRingChartMoreView *chartView1 = [[XFRingChartMoreView alloc]initWithFrame:CGRectMake(16.0, 100, [UIScreen mainScreen].bounds.size.width - 32.0, 244.0)];
    [chartView1 loadDataRadius:65.0 CircleWidth:30.0 DataArr:dataArray];
    [self.view addSubview:chartView1];
    //第二个
    XFRingChartLayerView *chartView2 = [[XFRingChartLayerView alloc]initWithFrame:CGRectMake(16.0, 344.0 + 70, [UIScreen mainScreen].bounds.size.width - 32.0, 244.0)];
    [chartView2 loadDataRadius:65.0 CircleWidth:30.0 DataArr:dataArray];
    [self.view addSubview:chartView2];
}

@end
