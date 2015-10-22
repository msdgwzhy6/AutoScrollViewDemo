//
//  WDScrollView.m
//  AutoScrollViewDemo
//
//  Created by AD-iOS on 15/10/20.
//  Copyright © 2015年 Adinnet. All rights reserved.
//

#import "WDScrollView.h"

@interface WDScrollView ()<UIScrollViewDelegate>

@property (strong, nonatomic) NSTimer *timer;

/**
 *  承托三个按钮的view
 */
@property (strong, nonatomic) UIView *panView;

/**
 *  手势
 */
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

/**
 *  显示图片的按钮
 */
@property (strong, nonatomic) UIButton *leftButton;
@property (strong, nonatomic) UIButton *centerButton;
@property (strong, nonatomic) UIButton *rightButton;

/**
 *  当前显示的图片位于数组中的位置
 */
@property (assign, nonatomic) NSInteger currentIndex;


@property (assign, nonatomic) CGPoint prePoint;
@property (assign, nonatomic) CGPoint curPoint;

@property (assign, nonatomic) CGPoint startPoint;
@property (assign, nonatomic) CGPoint endPoint;


@end

@implementation WDScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.autoScrollTimeinterval = 2;
        [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSDefaultRunLoopMode];
        [self setupUIWithFrame:frame];
    }
    return self;
}

- (void)setupUIWithFrame:(CGRect)frame
{
    [self addSubview:self.panView];
    [self addGestureRecognizer:self.panGestureRecognizer];
    [self.panView addSubview:self.leftButton];
    [self.panView addSubview:self.centerButton];
    [self.panView addSubview:self.rightButton];
    [self setButtonFrameLeft:self.leftButton];
    [self setButtonFrameCenter:self.centerButton];
    [self setButtonFrameRight:self.rightButton];
}

- (void)panGestureValueChanged:(UIGestureRecognizer*)getsureRecognizer
{
    switch (getsureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            //手势开始时暂停定时器
            [self pauseTimer];
            //初始化所有的需要记录的点
            self.prePoint = [getsureRecognizer locationInView:self];
            self.curPoint = self.prePoint;
            self.startPoint = self.prePoint;
            self.endPoint = self.endPoint;
            break;
        case UIGestureRecognizerStateChanged:
            self.curPoint = [getsureRecognizer locationInView:self];
            [self changeFrameWithOffsetX:self.curPoint.x - self.prePoint.x];
            self.prePoint = self.curPoint;
            break;
        case UIGestureRecognizerStateEnded:
        {
            self.endPoint = [getsureRecognizer locationInView:self];
            //判断是否可以滑动到上一页或者下一页
            CGFloat movedDistance = self.endPoint.x - self.startPoint.x;
            if (fabs(movedDistance) > 150) {
                if (movedDistance > 0) {
                    //到上一页
                    [self preview];
                }else{
                    //到下一页
                    [self next];
                }
            }else{
                //恢复原位
                [self restoreFrameWithMoved:movedDistance];
            }
            //重新启动定时器
            [self restartTimer];
        }
            break;
            
        default:
            break;
    }
    
}



- (void)buttonClicked:(UIButton*)button
{
    if (self.ClickedIndexBlock) {
        self.ClickedIndexBlock(self.currentIndex);
    }
}

#pragma mark - helper

- (void)next
{
    //
    [UIView animateWithDuration:0.25 animations:^{
        [self setButtonFrameLeft:self.centerButton];
        [self setButtonFrameCenter:self.rightButton];
    }];
    [self setButtonFrameRight:self.leftButton];
    //交换指针的指向
    id temp = self.leftButton;
    self.leftButton = self.centerButton;
    self.centerButton = self.rightButton;
    self.rightButton = temp;
    
    //下一页的时候改变当前的位置数据currentIndex
    if (self.imageArr.count == 1) {
        return;
    }
    self.currentIndex++;
    //当到最后
    if (self.currentIndex >= self.imageArr.count) {
        self.currentIndex = 0;
    }
    //配置下一页的图片数据
    id nextObj = self.imageArr[(self.currentIndex + 1) % self.imageArr.count];
    //根据传入的数据不同进行配置
    [self configWithObject:nextObj andButton:self.rightButton];
}

- (void)preview
{
    [UIView animateWithDuration:1 animations:^{
        [self setButtonFrameRight:self.centerButton];
        [self setButtonFrameCenter:self.leftButton];
    }];
    [self setButtonFrameLeft:self.rightButton];
    //交换指针的指向
    id temp = self.rightButton;
    self.rightButton = self.centerButton;
    self.centerButton = self.leftButton;
    self.leftButton = temp;
    
    //下一页的时候改变当前的位置数据currentIndex
    if (self.imageArr.count == 1) {
        return;
    }
    self.currentIndex--;
    if (self.currentIndex < 0) {
        self.currentIndex = self.imageArr.count - 1;
    }
    //配置下一页的图片数据
    NSInteger preIndex = self.currentIndex - 1;
    if (preIndex < 0) {
        preIndex = self.imageArr.count - 1;
    }
    id preObj = self.imageArr[preIndex];
    [self configWithObject:preObj andButton:self.leftButton];

}

- (void)configImages
{
    self.currentIndex = 0;
    if (self.imageArr.count >= 3) {
        [self configWithObject:[self.imageArr firstObject] andButton:self.centerButton];
        [self configWithObject:self.imageArr[1] andButton:self.rightButton];
        [self configWithObject:[self.imageArr lastObject] andButton:self.leftButton];
    }else if (self.imageArr.count == 2){
        [self configWithObject:[self.imageArr firstObject] andButton:self.centerButton];
        [self configWithObject:[self.imageArr lastObject] andButton:self.rightButton];
        [self configWithObject:[self.imageArr lastObject] andButton:self.leftButton];
    }else if (self.imageArr.count == 1){
        [self configWithObject:[self.imageArr firstObject]  andButton:self.centerButton];
        [self configWithObject:[self.imageArr firstObject] andButton:self.rightButton];
        [self configWithObject:[self.imageArr firstObject] andButton:self.leftButton];
    }else{
        NSAssert(NO, @"数据源数组不能为空");
    }
}

- (void)configWithObject:(id)obj andButton:(UIButton*)button
{
    if ([obj isKindOfClass:[NSURL class]]) {
        
        [button setBackgroundImage:nil forState:UIControlStateNormal];
        [button setBackgroundImage:nil forState:UIControlStateHighlighted];
//        [self.loadingItemArr addObject:button];
//        __block WDScrollView *weakSelf = self;
        //此处最好使用SDWebImage 或者AFNetworking 进行替换，未做缓存处理
        [self imageWithURL:obj completion:^(UIImage *image, NSError *error) {
            [button setBackgroundImage:image forState:UIControlStateNormal];
            [button setBackgroundImage:image forState:UIControlStateHighlighted];
        }];
    }
    
    if ([obj isKindOfClass:[NSString class]]) {
        [button setBackgroundImage:[UIImage imageNamed:obj] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:obj] forState:UIControlStateHighlighted];
}
    if ([obj isKindOfClass:[UIImage class]]) {
        [button setBackgroundImage:obj forState:UIControlStateNormal];
        [button setBackgroundImage:obj forState:UIControlStateHighlighted];

    }
}

- (void)pauseTimer
{
    [self.timer setFireDate:[NSDate distantFuture]];
}

- (void)restartTimer
{
    [self.timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.autoScrollTimeinterval]];
}

#pragma mark - frame helper

- (void)setButtonFrameLeft:(UIButton*)button
{
    button.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}
- (void)setButtonFrameCenter:(UIButton*)button
{
    button.frame = CGRectMake(CGRectGetWidth(self.frame), 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}
- (void)setButtonFrameRight:(UIButton*)button
{
    button.frame = CGRectMake(CGRectGetWidth(self.frame) * 2, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}

- (void)changeFrameWithOffsetX:(CGFloat)offsetX
{
    //定义向左为负，向右为正
    if (offsetX > 0) {
        //移动中间和左边
        CGRect frame = self.centerButton.frame;
        frame.origin.x += offsetX;
        self.centerButton.frame = frame;
        
        frame = self.leftButton.frame;
        frame.origin.x += offsetX;
        self.leftButton.frame = frame;
    }else{
        //移动中间和右边
        CGRect frame = self.centerButton.frame;
        frame.origin.x += offsetX;
        self.centerButton.frame = frame;
        
        frame = self.rightButton.frame;
        frame.origin.x += offsetX;
        self.rightButton.frame = frame;
    }
}

- (void)restoreFrameWithMoved:(CGFloat)moved
{
    [UIView animateWithDuration:0.25 animations:^{
        [self setButtonFrameLeft:self.leftButton];
        [self setButtonFrameCenter:self.centerButton];
        [self setButtonFrameRight:self.rightButton];
        
    }];
}

#pragma mark - HTTP helper

- (void)imageWithURL:(NSURL*)url completion:(void(^)(UIImage *image, NSError *error))competion
{
    if (url == nil) {
        NSError *error = [NSError errorWithDomain:@"图片链接为空" code:-1 userInfo:nil];
        competion(nil, error);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [[NSData alloc]initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
        UIImage *image = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            competion(image, error);
        });
    });
    
}

#pragma mark - setter 

- (void)setImageArr:(NSArray *)imageArr
{
    _imageArr = [imageArr copy];
    [self configImages];
}

- (void)setAutoScrollTimeinterval:(NSInteger)autoScrollTimeinterval
{
    _autoScrollTimeinterval = autoScrollTimeinterval;
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
        [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSDefaultRunLoopMode];
    }
}

#pragma mark - getter

- (UIButton *)leftButton
{
    if (_leftButton == nil) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _leftButton.backgroundColor = [UIColor greenColor];
    }
    return _leftButton;
}

- (UIButton *)rightButton
{
    if (_rightButton == nil) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _rightButton.backgroundColor = [UIColor purpleColor];
    }
    return _rightButton;
}
- (UIButton *)centerButton
{
    if (_centerButton == nil) {
        _centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_centerButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _centerButton.backgroundColor = [UIColor orangeColor];
    }
    return _centerButton;
}

- (UIView *)panView
{
    if(_panView == nil){
        _panView = [[UIView alloc]initWithFrame:CGRectMake(-CGRectGetWidth(self.frame), 0, CGRectGetWidth(self.frame) * 3, CGRectGetHeight(self.frame))];
        _panView.backgroundColor = [UIColor clearColor];
    }
    return _panView;
}

- (UIPanGestureRecognizer *)panGestureRecognizer
{
    if (_panGestureRecognizer == nil) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureValueChanged:)];
    }
    return _panGestureRecognizer;
}

- (NSTimer *)timer
{
    if (_timer == nil) {
        _timer = [NSTimer timerWithTimeInterval:self.autoScrollTimeinterval target:self selector:@selector(next) userInfo:nil repeats:YES];
    }
    return _timer;
}

@end