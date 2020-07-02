//
//  XFRingChartLayerView.h
//  XFRingChartView
//
//  Created by xfxb on 2020/7/1.
//  Copyright © 2020 xfxb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XFRingChartLayer.h"

NS_ASSUME_NONNULL_BEGIN
@interface XFRingChartLayerView : UIView
@property (nonatomic,strong) NSString *prefixStr;
/// 加载扇形数据
/// @param radius 圆半径
/// @param circleWidth 圆环宽度
/// @param dataArr 数据数组
- (void)loadDataRadius:(CGFloat)radius CircleWidth:(CGFloat)circleWidth DataArr:(NSArray *)dataArr;
@end
NS_ASSUME_NONNULL_END
