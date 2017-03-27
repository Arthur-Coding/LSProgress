
//
//  LSProgressView.m
//  BicycleSharing
//
//  Created by ArthurShuai on 2017/3/18.
//  Copyright © 2017年 qusu. All rights reserved.
//

#import "LSProgressView.h"

#define kTitleHeight 40
#define kTitleWidth CGRectGetWidth(self.frame)/self.titles.count
#define kCircleWidth 34
#define kCircleHeight 34

#define Frame_circle(idx) CGRectMake(idx*kTitleWidth+kTitleWidth/2-kCircleWidth/2, 25, kCircleWidth, kCircleHeight)
#define Frame_circle_small_left(idx) CGRectMake(idx*kTitleWidth+kTitleWidth/2-kCircleWidth/4-2, 25+kCircleHeight/2-2, 4, 4)
#define Frame_circle_small_middle(idx) CGRectMake(idx*kTitleWidth+kTitleWidth/2-2, 25+kCircleHeight/2-2, 4, 4)
#define Frame_circle_small_right(idx) CGRectMake(idx*kTitleWidth+kTitleWidth/2+kCircleWidth/4-2, 25+kCircleHeight/2-2, 4, 4)

#define Draw_circle(context,rect,color) \
        CGContextAddEllipseInRect(context, rect);\
        [color setFill];\
        CGContextFillPath(context);

#define Point_line_start(i) CGPointMake(i*kTitleWidth+kTitleWidth/2+kCircleWidth/2+5, 25+kCircleHeight/2)
#define Point_line_end(i) CGPointMake((i+1)*kTitleWidth+kTitleWidth/2-kCircleWidth/2-5, 25+kCircleHeight/2)
#define Point_line_start_back(i) CGPointMake((i)*kTitleWidth+kTitleWidth/2-kCircleWidth/2-5, 25+kCircleHeight/2)
#define Point_line_end_back(i) CGPointMake((i-1)*kTitleWidth+kTitleWidth/2+kCircleWidth/2+5, 25+kCircleHeight/2)

#define Point_line_check_start(i) CGPointMake(i*kTitleWidth+kTitleWidth/2-kCircleWidth/4, 25+kCircleHeight/2)
#define Point_line_check_middle(i) CGPointMake(i*kTitleWidth+kTitleWidth/2-2, 25+kCircleHeight*3/4-2)
#define Point_line_check_end(i) CGPointMake(i*kTitleWidth+kTitleWidth/2+kCircleWidth/4, 25+kCircleHeight/4+4)

#define Draw_line(context,point_start,point_end,color) \
        CGContextBeginPath(context);\
        CGContextMoveToPoint(context,point_start.x, point_start.y);\
        CGContextAddLineToPoint(context, point_end.x, point_end.y);\
        CGContextSetLineWidth(context, 2);\
        CGContextSetLineCap(context, kCGLineCapRound);\
        CGContextSetLineJoin(context, kCGLineJoinRound);\
        [color setStroke];\
        CGContextStrokePath(context);

#define ADD_shape_circle(shapeName,rect,color,radius,obj) \
        shapeName.frame = rect;\
        shapeName.backgroundColor = color.CGColor;\
        shapeName.cornerRadius = radius;\
        [obj.layer addSublayer:shapeName];

#define ADD_shape_line(shape,sColor,bPath,obj) \
        shape.fillColor = [UIColor clearColor].CGColor;\
        shape.lineWidth = 2;\
        shape.strokeColor = sColor.CGColor;\
        shape.lineCap = kCALineCapRound;\
        shape.lineJoin = kCALineJoinRound;\
        shape.path = bPath.CGPath;\
        [obj.layer addSublayer:shape];

#define ADD_shape_animation(shape,time,obj,key) \
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];\
        animation.duration = time;\
        animation.fromValue = @(0.0);\
        animation.toValue = @(1.0);\
        animation.delegate = obj;\
        [shape addAnimation:animation forKey:key];

@interface LSProgressView ()<LSProgressDelegate,CAAnimationDelegate>

@property (nonatomic, strong) NSArray<NSString *> *titles;

@property (nonatomic, strong) NSString *currentTitle;
@property (nonatomic) NSInteger currentIndex;

@property (nonatomic, strong) NSMutableArray<NSNumber *> *finishIndex;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *unfinishIndex;

@property (nonatomic) BOOL isBack;

@end

@implementation LSProgressView

- (instancetype)initWithFrame:(CGRect)frame andTitles:(NSArray<NSString *> *)titles beginIndex:(NSInteger)beginIndex
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, CGRectGetWidth(frame), 120)];
    if (self) {
        self.titles = titles;
        self.currentIndex = beginIndex;

        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        self.finishIndex = [NSMutableArray array];
        self.unfinishIndex = [NSMutableArray array];
    }
    return self;
}
- (void)drawRect:(CGRect)rect {
    [self drawDefaultShape];
}
- (void)drawDefaultShape
{
    // 绘制title、圆形
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:14],
                                 NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                 NSParagraphStyleAttributeName:style};
    __weak typeof(self) weakSelf = self;
    [self.titles enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // title
        [obj drawInRect:CGRectMake(idx*kTitleWidth, 75, kTitleWidth, kTitleHeight) withAttributes:attributes];

        UIColor *tintColor = idx <= weakSelf.currentIndex ? [UIColor greenColor] : [UIColor lightGrayColor];
        // 圆形
        Draw_circle(context, Frame_circle(idx), tintColor)
        if (idx >= weakSelf.currentIndex) { // 每个圆形内三个小圆点
            Draw_circle(context, Frame_circle_small_left(idx), [UIColor whiteColor])
            Draw_circle(context, Frame_circle_small_middle(idx), [UIColor whiteColor])
            Draw_circle(context, Frame_circle_small_right(idx), [UIColor whiteColor])
        }else { // 对号
            Draw_line(context, Point_line_check_start(idx), Point_line_check_middle(idx), [UIColor whiteColor])
            Draw_line(context, Point_line_check_middle(idx), Point_line_check_end(idx), [UIColor whiteColor])
            if (![weakSelf.unfinishIndex containsObject:@(idx)]) {
                [weakSelf finishProgress:idx];
            }
        }
    }];

    // 绘制每两个圆形之间的连接线
    for (int i = 0; i < self.titles.count-1; i++) {
        UIColor *tintColor = i < self.currentIndex ? [UIColor greenColor] : [UIColor lightGrayColor];
        Draw_line(context, Point_line_start(i), Point_line_end(i), tintColor)
    }
}
- (void)finishProgress:(NSInteger)index
{
    [self.finishIndex addObject:@(index)];
    [self drawCircleAndCheck:index and:self];
}
- (CAShapeLayer *)drawCircleAndCheck:(NSInteger)index and:(LSProgressView *)Self
{
    // 1.将当前圆形内的小圆点填充
    CAShapeLayer *shape = [CAShapeLayer layer];
    ADD_shape_circle(shape, Frame_circle(index), [UIColor greenColor], kCircleWidth/2,Self)
    // 2.绘制对号动画
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:Point_line_check_start(index)];
    [path addLineToPoint:Point_line_check_middle(index)];
    [path addLineToPoint:Point_line_check_end(index)];
    CAShapeLayer *shape2 = [CAShapeLayer layer];
    ADD_shape_line(shape2, [UIColor whiteColor], path, Self)
    return shape2;
}
- (void)unFinishProgress:(NSInteger)index
{
    [self.unfinishIndex addObject:@(index)];
    if ([self.finishIndex containsObject:@(index)]) {
        [self.finishIndex removeObject:@(index)];
    }
    [self drawCircleAndSmallCircle:index circleColor:[UIColor lightGrayColor] and:self];
}
- (void)drawCircleAndSmallCircle:(NSInteger)index circleColor:(UIColor *)color and:(LSProgressView *)Self
{
    // 绘制下一个圆形和小圆点
    CAShapeLayer *shape1 = [CAShapeLayer layer];
    ADD_shape_circle(shape1, Frame_circle(index), color, kCircleWidth/2, Self)

    CAShapeLayer *shape2 = [CAShapeLayer layer];
    ADD_shape_circle(shape2, Frame_circle_small_left(index), [UIColor whiteColor], 2, Self)
    CAShapeLayer *shape3 = [CAShapeLayer layer];
    ADD_shape_circle(shape3, Frame_circle_small_middle(index), [UIColor whiteColor], 2, Self)
    CAShapeLayer *shape4 = [CAShapeLayer layer];
    ADD_shape_circle(shape4, Frame_circle_small_right(index), [UIColor whiteColor], 2, Self)
}
- (void)next
{
    self.isBack = NO;
    [self finishProgress:self.currentIndex];
    if (self.currentIndex < self.titles.count) {
        CAShapeLayer *shape = [self drawCircleAndCheck:self.currentIndex and:self];
        if (self.currentIndex != self.titles.count-1) {
            ADD_shape_animation(shape, 0.2, self, @"animation1")
        }
    }
}
- (void)back
{
    self.isBack = YES;
    if (self.currentIndex < self.titles.count) {
        CAShapeLayer *shape = [self drawCircleAndCheck:self.currentIndex and:self];
        if (self.currentIndex != 0) {
            ADD_shape_animation(shape, 0.2, self, @"animation1")
        }
    }
}
- (void)animationDidStart:(CAAnimation *)anim {
    __weak typeof(self) weakSelf = self;
    [self.layer.sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj animationForKey:@"animation1"] isEqual:anim]) {
            if ([weakSelf.delegate respondsToSelector:@selector(startSwitchNextProgress:)]) {
                [weakSelf.delegate startSwitchNextProgress:weakSelf];
            }
            // 绘制直线动画
            UIBezierPath *path2 = [UIBezierPath bezierPath];
            if (!_isBack) {
                [path2 moveToPoint:Point_line_start(weakSelf.currentIndex)];
                [path2 addLineToPoint:Point_line_end(weakSelf.currentIndex)];
            }else {
                [path2 moveToPoint:Point_line_start_back(weakSelf.currentIndex)];
                [path2 addLineToPoint:Point_line_end_back(weakSelf.currentIndex)];
            }

            CAShapeLayer *shape = [CAShapeLayer layer];
            ADD_shape_line(shape, [UIColor greenColor], path2, weakSelf)
            ADD_shape_animation(shape, 0.3, weakSelf, @"animation2")
        }
    }];
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    __weak typeof(self) weakSelf = self;
    [self.layer.sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.animationKeys containsObject:@"animation2"]) {
            if (weakSelf.isBack) {
                weakSelf.currentIndex--;
            }else {
                weakSelf.currentIndex++;
            }
            if ([weakSelf.finishIndex containsObject:@(weakSelf.currentIndex)]) {
                if (weakSelf.currentIndex != weakSelf.titles.count-1 && weakSelf.currentIndex != 0) {
                    UIBezierPath *path2 = [UIBezierPath bezierPath];
                    [path2 moveToPoint:Point_line_start(weakSelf.currentIndex)];
                    [path2 addLineToPoint:Point_line_end(weakSelf.currentIndex)];

                    CAShapeLayer *shape = [CAShapeLayer layer];
                    ADD_shape_line(shape, [UIColor greenColor], path2, weakSelf)
                    ADD_shape_animation(shape, 0.3, weakSelf, @"animation2")
                }
            }else {
                [weakSelf drawCircleAndSmallCircle:weakSelf.currentIndex circleColor:[UIColor greenColor] and:weakSelf];
                
                if ([weakSelf.delegate respondsToSelector:@selector(nextProgressSwitched:)]) {
                    [weakSelf.delegate nextProgressSwitched:weakSelf];
                }
            }
        }
    }];
}

@end
