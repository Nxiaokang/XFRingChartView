//
//  XFRingChartLayerView.m
//  XFRingChartView
//
//  Created by xfxb on 2020/7/1.
//  Copyright © 2020 xfxb. All rights reserved.
//

#import "XFRingChartLayerView.h"

@interface XFRingChartLayerView()
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

@implementation XFRingChartLayerView
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
        [layerArray insertObject:subChartlayer atIndex:0];
    }
    for (int i = 0; i < layerArray.count; i++) {
        XFRingChartLayer *layer = layerArray[i];
        [self addLineLayer:layer index:i];
    }
}
- (void)addLineLayer:(XFRingChartLayer *)layer index:(int)i
{
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.lineCap = kCALineCapRound;
    lineLayer.lineJoin = kCALineJoinRound;
    lineLayer.strokeColor = XFRGBCOLOR(231, 231, 231).CGColor;
    lineLayer.fillColor = [UIColor clearColor].CGColor;
    lineLayer.lineWidth = 1;
    //初始数据
    CGFloat lineSpace = 20.0;
    CGPoint circlePosition = layer.circlePoint;
    //绘制线条路径
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:circlePosition];
    CGPoint firstLinePoint = CGPointMake(0, 0);
    if (circlePosition.x >= self.bgRingLayer.position.x) {
        if (circlePosition.y >= self.bgRingLayer.position.y) {
            //第一象限
            firstLinePoint = CGPointMake(circlePosition.x + kSpace_LineTurning * cos(M_PI_4 / 2), circlePosition.y + kSpace_LineTurning * sin(M_PI_4 * 7 / 8));
        }else{
            //第四象限
            firstLinePoint = CGPointMake(circlePosition.x + kSpace_LineTurning * cos(M_PI_2 * 3 + M_PI_4), circlePosition.y + kSpace_LineTurning * sin(M_PI_2 * 3 + M_PI_4));
        }
    }else{
        if (circlePosition.y >= self.bgRingLayer.position.y) {
            //第二象限
            firstLinePoint = CGPointMake(circlePosition.x + kSpace_LineTurning * cos(M_PI - M_PI_4), circlePosition.y + kSpace_LineTurning * sin(M_PI - M_PI_4));
        }else{
            //第三象限
            firstLinePoint = CGPointMake(circlePosition.x + kSpace_LineTurning * cos(M_PI + M_PI_4), circlePosition.y + kSpace_LineTurning * sin(M_PI + M_PI_4));
        }
    }
    NSLog(@"当前是:%@",self.titleArr[i]);
    //两个扇形间距太小,文字重叠问题解决
    CGPoint newFirstLinePoint = firstLinePoint;
    if(circlePosition.x >= self.bgRingLayer.position.x)
    {
        //一四象限
        if (firstLinePoint.x > self.bgRingLayer.position.x) {
            newFirstLinePoint = firstLinePoint;
        }else{
            if (self.oldFirstLinePoint.y - firstLinePoint.y <= lineSpace) {
                CGFloat newFirstLinePointY = self.oldFirstLinePoint.y -lineSpace;
                newFirstLinePoint = CGPointMake(firstLinePoint.x, newFirstLinePointY);
            }
        }
    }else
    {
        if (i != 0 && firstLinePoint.y - self.oldFirstLinePoint.y <= lineSpace) {
             CGFloat newFirstLinePointY = self.oldFirstLinePoint.y +lineSpace;
             newFirstLinePoint = CGPointMake(firstLinePoint.x, newFirstLinePointY);
        }
    }
    self.oldFirstLinePoint = newFirstLinePoint;
    [linePath addLineToPoint:newFirstLinePoint];
    CGFloat x = newFirstLinePoint.x > self.bgRingLayer.position.x ? self.layer.bounds.size.width - 16.0 : 16.0;
    CGPoint secondLinePoint = CGPointMake(x, newFirstLinePoint.y);
    [linePath addLineToPoint:secondLinePoint];
    lineLayer.path = linePath.CGPath;
    [self.layer addSublayer:lineLayer];
    NSLog(@"%@,%.f,%.f",self.titleArr[i],x,newFirstLinePoint.y);
    //5.在线条上添加文字
    NSString *numStr = [NSString stringWithFormat:@"%.2f%%", [self.proportionArray[layer.index] floatValue] * 100];
    NSString *nameStr = [NSString stringWithFormat:@"%@", self.titleArr[layer.index]];
    NSString *textStr = [NSString stringWithFormat:@"%@ %@",nameStr,numStr];
    CGSize textSize = [textStr sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0]}];
    CGFloat textX = firstLinePoint.x > self.bgRingLayer.position.x ? secondLinePoint.x - textSize.width : secondLinePoint.x;
    [self addTextLayerWithText:textStr Frame:CGRectMake(textX,secondLinePoint.y - textSize.height - 5, textSize.width, textSize.height) FontSize:12.0];
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
