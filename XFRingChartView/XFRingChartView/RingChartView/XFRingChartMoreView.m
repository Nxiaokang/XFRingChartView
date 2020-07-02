//
//  XFRingChartMoreView.m
//  XFStoreManage
//
//  Created by xfxb on 2020/6/24.
//  Copyright © 2020 xfxb. All rights reserved.
//

#import "XFRingChartMoreView.h"

@interface XFRingChartMoreView()
//饼图背景图层
@property (nonatomic,strong) CAShapeLayer *bgRingLayer;
//遮罩图层
@property (nonatomic,strong) CAShapeLayer *maskLayer;
//数据数组
@property (nonatomic,strong) NSArray *dataArr;
//百分比数组
@property (nonatomic,strong) NSArray *proportionArray;
//具体数值
@property (nonatomic,strong) NSArray *numberArr;
//文字数组
@property (nonatomic,strong) NSArray *titleArr;
//颜色数组
@property (nonatomic,strong) NSArray *colorArr;
//圆半径
@property (nonatomic,assign) CGFloat radius;
//圆环宽度
@property (nonatomic,assign) CGFloat circleWidth;
//上一个圆点位置
@property (nonatomic,assign) CGPoint oldFirstLinePoint;

@end

#define kSpace_PointToPie   10 //标示点与扇形外弧的距离
#define kSpace_LineTurning   30 //指示线线转折的距离
#define XFRGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]

@implementation XFRingChartMoreView
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.oldFirstLinePoint = CGPointMake(0, 0);
        self.backgroundColor = XFRGBCOLOR(255, 255, 255);
    }
    return self;
}
- (void)loadDataRadius:(CGFloat)radius CircleWidth:(CGFloat)circleWidth DataArr:(NSArray *)dataArr
{
    self.radius = radius;
    self.circleWidth = circleWidth;
    //如果图片路径大于弧度，显示出来的圆弧有交叉；width=radius，显示整好为实心圆；width<radius，显示的是空心圆环
    if (circleWidth > radius) {
        self.circleWidth = radius;
    }
    self.dataArr = dataArr;
    self.proportionArray = [dataArr valueForKeyPath:@"@unionOfObjects.proportion"];
    self.numberArr = [dataArr valueForKeyPath:@"@unionOfObjects.number"];
    self.titleArr = [dataArr valueForKeyPath:@"@unionOfObjects.name"];
    self.colorArr = [dataArr valueForKeyPath:@"@unionOfObjects.color"];
}
- (void)drawRect:(CGRect)rect
{
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    //绘制背景图层
    self.bgRingLayer.frame = CGRectMake(CGRectGetMidX(self.bounds) - self.radius, CGRectGetMidY(self.bounds) - self.radius, self.radius * 2, self.radius * 2);
    UIBezierPath *bgPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.bgRingLayer.bounds), CGRectGetMidY(self.bgRingLayer.bounds)) radius:self.radius startAngle:0 endAngle:2 * M_PI clockwise:NO];
    self.bgRingLayer.path = bgPath.CGPath;
    [self.layer addSublayer:self.bgRingLayer];
    //添加相应数据
    [self addAllData];
    //遮罩
    self.maskLayer.frame = self.bgRingLayer.frame;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.maskLayer.bounds), CGRectGetMidY(self.maskLayer.bounds)) radius:self.radius startAngle:0 endAngle:M_PI * 2 clockwise:NO];
    self.maskLayer.lineWidth = self.radius;
    self.maskLayer.path = maskPath.CGPath;
    [self.layer addSublayer:self.maskLayer];
    [self addAntimation];
}
- (void)addAllData
{
    CGFloat startAngle = M_PI_2 * 3;
    CGFloat endAngle = startAngle;
    NSMutableArray *layerArray = @[].mutableCopy;
    //绘制单个扇形
    for (int i = 0; i < self.proportionArray.count; i++) {
        endAngle = startAngle + [self.proportionArray[i] floatValue] * 2 * M_PI;
        //1.添加一个背景layer用于判断是否在范围内
        CAShapeLayer *subLayer = [CAShapeLayer layer];
        subLayer.strokeColor = [UIColor clearColor].CGColor;
        subLayer.fillColor = [UIColor clearColor].CGColor;
        //绘制圆弧路径
        CGPoint subCenter = CGPointMake(CGRectGetMidX(self.bgRingLayer.bounds),CGRectGetMidY(self.bgRingLayer.bounds));
        UIBezierPath *subPath = [UIBezierPath bezierPath];
        [subPath moveToPoint:subCenter];
        [subPath addArcWithCenter:subCenter radius:self.radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        subLayer.path = subPath.CGPath;
        [self.bgRingLayer addSublayer:subLayer];
        //2.绘制每一个单独的扇形
        XFRingChartLayer *subChartlayer = [XFRingChartLayer layer];
        subChartlayer.lineWidth = self.circleWidth;
        subChartlayer.fillColor = [UIColor clearColor].CGColor;
        subChartlayer.strokeColor = [self.colorArr[i] CGColor];
        subChartlayer.index = i;
        endAngle = startAngle + [self.proportionArray[i] floatValue] * 2 * M_PI;
        //绘制圆弧路径
        UIBezierPath *subChartPath = [UIBezierPath bezierPathWithArcCenter:subCenter radius:self.radius - self.circleWidth / 2 startAngle:startAngle endAngle:endAngle clockwise:YES];
        subChartlayer.startAngle = startAngle;
        subChartlayer.endAngle = endAngle;
        subChartlayer.path = subChartPath.CGPath;
        [subLayer addSublayer:subChartlayer];
        startAngle = endAngle;
        //3.绘制圆点标识
        //获取圆点位置
        double middleAngle = (subChartlayer.startAngle + subChartlayer.endAngle) / 2.0;
        CGPoint circlePosition = CGPointMake(self.bgRingLayer.position.x + (self.radius + kSpace_PointToPie) * cos(middleAngle), self.bgRingLayer.position.y + (self.radius + kSpace_PointToPie) * sin(middleAngle));
        subChartlayer.circlePoint = circlePosition;
        //绘制一个圆点
        CAShapeLayer *circlePointLayer = [CAShapeLayer layer];
        UIBezierPath *circlePointPath = [UIBezierPath bezierPathWithArcCenter:circlePosition radius:2 startAngle:0 endAngle:M_PI * 2 clockwise:NO];
        circlePointLayer.fillColor = kSpace_PointToPie == 0 ? [UIColor clearColor].CGColor : [UIColor redColor].CGColor;
        circlePointLayer.path = circlePointPath.CGPath;
        [self.layer addSublayer:circlePointLayer];
        if (i <= self.dataArr.count/2 - 1) {
            [layerArray insertObject:subChartlayer atIndex:0];
        }else{
            [layerArray addObject:subChartlayer];
        }
    }
    [self drawLineWithPointArray:layerArray];
}
- (void)drawLineWithPointArray:(NSArray *)layerArray {
    // 记录每一个指引线包括数据所占用位置的和（总体位置）
    CGRect rect = CGRectZero;
    // 用于计算指引线长度
    CGFloat width = self.bounds.size.width * 0.5;
    for (int i = 0; i < layerArray.count; i++) {
        XFRingChartLayer *subChartLayer = layerArray[i];
        CGPoint circlePosition = subChartLayer.circlePoint;
        CGFloat radianCenter = (subChartLayer.startAngle + subChartLayer.endAngle)/2.0;
        // 指引线转折点的位置
        CGFloat firstLinePointX = circlePosition.x +  kSpace_LineTurning* cos(radianCenter);
        CGFloat firstLinePointY = circlePosition.y + kSpace_LineTurning * sin(radianCenter);
        // 转折点到中心竖线的垂直长度(为什么+20, 在实际做出的效果中，有的转折线很丑，+20为了美化)
        CGFloat margin = fabs(width - firstLinePointX) + 20;
        // 指引线结束点位置
        CGFloat secondLinePointX;
        CGFloat secondLinePointY;
        //绘制文字所占位置
        CGFloat lineWidth = width - margin;
        // width使用lineWidth更好，我这么写固定值是为了达到产品要求
        CGFloat numberWidth = 80.f;
        CGFloat numberHeight = 15.f;
        CGFloat titleWidth = numberWidth;
        CGFloat titleHeight = numberHeight;
        // 绘制文字和数字时的起始位置（x, y）与上面的合并起来就是frame
        CGFloat numberX;// = breakPointX;
        CGFloat numberY = firstLinePointY - numberHeight;
        CGFloat titleX = firstLinePointX;
        CGFloat titleY = firstLinePointY + 2;
        // 文本段落属性(绘制文字和数字时需要)
        NSMutableParagraphStyle * paragraph = [[NSMutableParagraphStyle alloc]init];
        // 文字靠右
        paragraph.alignment = NSTextAlignmentRight;
        // 判断x位置，确定在指引线向左还是向右绘制
        // 根据需要变更指引线的起始位置
        // 变更文字和数字的位置
        if (circlePosition.x <= width) { // 在左边
            secondLinePointX = 10;
            secondLinePointY = firstLinePointY;
            // 文字靠左
            paragraph.alignment = NSTextAlignmentLeft;
            numberX = secondLinePointX;
            titleX = secondLinePointY;
        } else {    // 在右边
            secondLinePointX = self.bounds.size.width - 10;
            secondLinePointY = firstLinePointY;
            numberX = secondLinePointX - numberWidth;
            titleX = secondLinePointY - titleWidth;
        }
        if (i != 0) {
            // 当i!=0时，就需要计算位置总和(方法开始出的rect)与rect1(将进行绘制的位置)是否有重叠
            CGRect rect1 = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
            CGFloat margin = 0;
            if (CGRectIntersectsRect(rect, rect1)) {
                // 两个面积重叠三种情况:1.压上面 2.压下面 3.包含
                // 通过计算让面积重叠的情况消除
                if (CGRectContainsRect(rect, rect1)) {// 包含
                    if (i % layerArray.count <= layerArray.count * 0.5 - 1) {
                        // 将要绘制的位置在总位置偏上
                        margin = CGRectGetMaxY(rect1) - rect.origin.y;
                        secondLinePointY -= margin;
                    } else {
                        // 将要绘制的位置在总位置偏下
                        margin = CGRectGetMaxY(rect) - rect1.origin.y;
                        secondLinePointY += margin;
                    }
                } else {    // 相交
                    if (CGRectGetMaxY(rect1) > rect.origin.y && rect1.origin.y < rect.origin.y) { // 压在总位置上面
                        margin = CGRectGetMaxY(rect1) - rect.origin.y;
                        secondLinePointY -= margin;
                    } else if (rect1.origin.y < CGRectGetMaxY(rect) &&  CGRectGetMaxY(rect1) > CGRectGetMaxY(rect)) {  // 压总位置下面
                        margin = CGRectGetMaxY(rect) - rect1.origin.y;
                        secondLinePointY += margin;
                    }
                }
            }
            titleY = secondLinePointY + 2;
            numberY = secondLinePointY - numberHeight;
            // 通过计算得出的将要绘制的位置
            CGRect rect2 = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
            // 把新获得的rect和之前的rect合并
            if (numberX == rect.origin.x) {
                // 当两个位置在同一侧的时候才需要合并
                if (rect2.origin.y < rect.origin.y) {
                    rect = CGRectMake(rect.origin.x, rect2.origin.y, rect.size.width, rect.size.height + rect2.size.height);
                }else{
                    rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height + rect2.size.height);
                }
            }
        }else{
            rect = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
        }
        // 重新制定转折点
        if (secondLinePointX == 10) {
            firstLinePointX = secondLinePointX + lineWidth;
        } else {
            firstLinePointX = secondLinePointX - lineWidth;
        }
        firstLinePointY = secondLinePointY;
        //1.添加线条
        CAShapeLayer *lineLayer = [CAShapeLayer layer];
        lineLayer.lineCap = kCALineCapRound;
        lineLayer.lineJoin = kCALineJoinRound;
        lineLayer.strokeColor = XFRGBCOLOR(231, 231, 231).CGColor;
        lineLayer.fillColor = [UIColor clearColor].CGColor;
        lineLayer.lineWidth = 1;
        //2.绘制线条路径
        CGPoint firstLinePoint = CGPointMake(firstLinePointX, firstLinePointY);
        CGPoint secondLinePoint = CGPointMake(secondLinePointX, secondLinePointY);
        UIBezierPath *linePath = [UIBezierPath bezierPath];
        [linePath moveToPoint:CGPointMake(circlePosition.x, circlePosition.y)];
        [linePath addLineToPoint:CGPointMake(firstLinePointX, firstLinePointY)];
        [linePath addLineToPoint:CGPointMake(secondLinePointX, secondLinePointY)];
        lineLayer.path = linePath.CGPath;
        [self.layer addSublayer:lineLayer];
        //3.在线条上/下添加文字
        NSString *numStr = [NSString stringWithFormat:@"%.2f%%", [self.proportionArray[subChartLayer.index] floatValue] * 100];
        NSString *nameStr = [NSString stringWithFormat:@"%@", self.titleArr[subChartLayer.index]];
        NSString *textStr = [NSString stringWithFormat:@"%@ %@",nameStr,numStr];
        CGSize textSize = [textStr sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0]}];
        CGFloat textOrignX = firstLinePoint.x > self.bgRingLayer.position.x ? secondLinePoint.x - textSize.width : secondLinePoint.x;
        [self addTextLayerWithText:textStr Frame:CGRectMake(textOrignX,secondLinePoint.y - textSize.height - 2.0, textSize.width, textSize.height) FontSize:12.0];
    }
}
- (void)addTextLayerWithText:(NSString *)text Frame:(CGRect)frame FontSize:(CGFloat)fontSize {
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.string = text;
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.fontSize = fontSize;
    textLayer.foregroundColor = XFRGBCOLOR(102, 102, 102).CGColor;
    textLayer.frame = frame;
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.wrapped = NO;
    [self.layer addSublayer:textLayer];
}
- (void)addAntimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = 1.5f;
    animation.fromValue = [NSNumber numberWithFloat:1.f];
    animation.toValue = [NSNumber numberWithFloat:0.f];
    animation.autoreverses = NO;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.maskLayer addAnimation:animation forKey:@"strokeEnd"];
}
#pragma mark --触摸事件--
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [touches.anyObject locationInView:self];
    CGPoint newPoint = [self.bgRingLayer convertPoint:point fromLayer:self.layer];
    XFRingChartLayer *selectLayer = nil;
    for (CAShapeLayer *shapelayer in self.bgRingLayer.sublayers) {
        XFRingChartLayer *ringLayer = (XFRingChartLayer *)shapelayer.sublayers.firstObject;
        //图层位移,扇形整体开外
        if(CGPathContainsPoint(shapelayer.path, &CGAffineTransformIdentity, newPoint, 0))
        {
            selectLayer = ringLayer;
            if (!ringLayer.isSelected) {
                ringLayer.isSelected = YES;
                CGPoint position = ringLayer.position;
                double middleAngle = (ringLayer.startAngle + ringLayer.endAngle) / 2.0;
                CGPoint newPosition = CGPointMake(position.x + kSpace_PointToPie * cos(middleAngle), position.y + kSpace_PointToPie * sin(middleAngle));
                ringLayer.position = newPosition;
            }
        }else{
            ringLayer.isSelected = NO;
            ringLayer.position = CGPointMake(0, 0);
        }
    }
}
#pragma mark --懒加载--
- (CAShapeLayer *)bgRingLayer
{
    if (!_bgRingLayer) {
        _bgRingLayer = [[CAShapeLayer alloc]init];
        _bgRingLayer.fillColor = [UIColor clearColor].CGColor;
    }
    return _bgRingLayer;
}
- (CAShapeLayer *)maskLayer
{
    if (!_maskLayer) {
        _maskLayer = [CAShapeLayer layer];
        _maskLayer.fillColor = [UIColor clearColor].CGColor;
        _maskLayer.strokeColor = [UIColor whiteColor].CGColor;
        _maskLayer.strokeEnd = 0;
    }
    return _maskLayer;
}

@end
