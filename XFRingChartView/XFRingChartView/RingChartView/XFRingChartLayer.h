//
//  XFRingChartLayer.h
//  XFRingChartView
//
//  Created by xfxb on 2020/7/1.
//  Copyright © 2020 xfxb. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface XFRingChartLayer : CAShapeLayer
@property (nonatomic,assign) CGFloat startAngle;
@property (nonatomic,assign) CGFloat endAngle;
@property (nonatomic,assign) BOOL isSelected;
@property (nonatomic,assign) NSInteger index;
@property (nonatomic,assign) CGPoint circlePoint;
@end

NS_ASSUME_NONNULL_END
