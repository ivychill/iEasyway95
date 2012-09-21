#import "RNSwipeBar.h"

@interface RNSwipeBar ()

//  Gesture handler for swiping
- (void)barViewWasSwiped:(UIPanGestureRecognizer*)recognizer;
//  Finishes animating the bar if not completely swiped up/down
- (void)completeAnimation:(BOOL)show;

@end

@implementation RNSwipeBar

@synthesize parentView = _parentView;
@synthesize delegate = _delegate;
@synthesize barView = _barView;
@synthesize toogleType;

#pragma mark - Init

- (id)init
{
    if (self = [super init]) {
        _isHidden = YES;
        _canMove = NO;
        _height = 88.0f;
        _padding = 0.0f;
        _animationDuration = 0.1f;
        //toogleType = 0;
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
    }
    return self;
}

- (id)initWithMainView:(UIView *)view
{
    if (self = [self init]) {
        [self setParentView:view];
        
        UIPanGestureRecognizer *swipeDown = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(barViewWasSwiped:)];
        [self addGestureRecognizer:swipeDown];        
        
        CGRect parentFrame = _parentView.frame;
        CGRect frame;
        switch (toogleType)
        {
                case 0: //底部
            {
                frame = CGRectMake(0, parentFrame.size.height, parentFrame.size.width, _height);
            }
                break;
                
                case 1: //顶
            {
                frame = CGRectMake(0, -(_height-_padding), parentFrame.size.width, _height);
            }
                break;
                
                case 2: //左
            {
                frame = CGRectMake(-(_height-_padding), 0, _height, parentFrame.size.height);

            }
                break; 
    
            case 3: //右
            {
                frame = CGRectMake(parentFrame.size.width, 0, _height, parentFrame.size.height);
                
            }
                break;
            default:
            {
                frame = CGRectMake(0, parentFrame.size.height, parentFrame.size.width, _height);
                
            }
        }
        
        [self setFrame:frame];
    }
    return self;
}

- (id)initWithMainView:(UIView *)view withType:(int)type
{
    toogleType = type;
    return [self initWithMainView:view];
}

- (id)initWithMainView:(UIView*)view barView:(UIView*)barView
{
    if (self = [self initWithMainView:view]) {
        if (toogleType == 0 || toogleType == 1)
        {
        _height = barView.frame.size.height;
        }
        else {
            _height = barView.frame.size.width;
        }
        _barView = barView;
        [self addSubview:_barView];
    }
    return [self initWithMainView:view];
}

#pragma mark - Display methods

- (void)show:(BOOL)shouldShow
{
    [self completeAnimation:shouldShow];
}

- (void)hide:(BOOL)shouldHide
{
    [self completeAnimation:(!shouldHide)];
}

- (void)toggle
{
    [self completeAnimation:_isHidden];
}

- (void)toggle: (BOOL)show
{
    //_isHidden = !show;
    [self completeAnimation:show];
}

#pragma mark - UIGestureRecognizer handlers

- (void)barViewWasSwiped:(UIPanGestureRecognizer*)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:_parentView];
    
    if (toogleType == 0)
    {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            _canMove = YES;
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(swipebarWasSwiped:)]) {
                    [self.delegate swipebarWasSwiped:self];
                }
            }
            return;
        }
        else if (recognizer.state == UIGestureRecognizerStateChanged && _canMove) {
            float maxYPosition = self.parentView.frame.size.height - self.frame.size.height;
            if (swipeLocation.y > maxYPosition) {
                CGRect frame = CGRectMake(self.frame.origin.x, swipeLocation.y, self.frame.size.width, self.frame.size.height);
                [self setFrame:frame];
            }
            return;
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded && _canMove) {
            float pivotYPosition = self.parentView.frame.size.height - self.frame.size.height / 2;
            _canMove = NO;
            [self completeAnimation:(self.frame.origin.y < pivotYPosition)];
            return;
        }
    }
    
    if (toogleType == 1)
    {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            _canMove = YES;
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(swipebarWasSwiped:)]) {
                    [self.delegate swipebarWasSwiped:self];
                }
            }
            return;
        }
        else if (recognizer.state == UIGestureRecognizerStateChanged && _canMove) {
            float maxYPosition = self.frame.size.height;
            if (swipeLocation.y < maxYPosition) {
                CGRect frame = CGRectMake(self.frame.origin.x, -(self.frame.size.height - swipeLocation.y), self.frame.size.width, self.frame.size.height);
                [self setFrame:frame];
            }
            return;
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded && _canMove) {
            float pivotYPosition = self.frame.size.height / 2;
            _canMove = NO;
            [self completeAnimation:((self.frame.origin.y+self.frame.size.height) > pivotYPosition)];
            return;
        }
    }
    
    if (toogleType == 2)
    {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            _canMove = YES;
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(swipebarWasSwiped:)]) {
                    [self.delegate swipebarWasSwiped:self];
                }
            }
            return;
        }
        else if (recognizer.state == UIGestureRecognizerStateChanged && _canMove) {
            float maxXPosition = self.frame.size.width;
            if (swipeLocation.x < maxXPosition) {
                CGRect frame = CGRectMake(-(self.frame.size.width-swipeLocation.x), self.frame.origin.y, self.frame.size.width, self.frame.size.height);
                [self setFrame:frame];
            }
            return;
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded && _canMove) {
            float pivotXPosition = self.frame.size.width / 2;
            _canMove = NO;
            [self completeAnimation:((self.frame.origin.x+self.frame.size.width) > pivotXPosition)];
            return;
        }
    }
    
    if (toogleType == 3)
    {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            _canMove = YES;
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(swipebarWasSwiped:)]) {
                    [self.delegate swipebarWasSwiped:self];
                }
            }
            return;
        }
        else if (recognizer.state == UIGestureRecognizerStateChanged && _canMove) {
            float maxXPosition = self.parentView.frame.size.width - self.frame.size.width;
            if (swipeLocation.x > maxXPosition) {
                CGRect frame = CGRectMake(swipeLocation.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
                [self setFrame:frame];
            }
            return;
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded && _canMove) {
            float pivotXPosition = self.parentView.frame.size.width - self.frame.size.width / 2;
            _canMove = NO;
            [self completeAnimation:(self.frame.origin.x < pivotXPosition)];
            return;
        }
    }
}

#pragma mark - Private methods

- (void)completeAnimation:(BOOL)show
{
    _isHidden = !show;
    CGRect parentFrame = self.parentView.frame;
    CGRect goToFrame;
    
    if (toogleType == 0)
    {
        if (show) 
        {
            goToFrame = CGRectMake(self.frame.origin.x, parentFrame.size.height - self.frame.size.height, self.frame.size.width, self.frame.size.height);
        }
        else {
            goToFrame = CGRectMake(self.frame.origin.x, parentFrame.size.height - _padding, self.frame.size.width, self.frame.size.height);
        }
    }
    
    if (toogleType == 1)
    {
        if (show) 
        {
            goToFrame = CGRectMake(self.frame.origin.x, 0, self.frame.size.width, self.frame.size.height);
        }
        else 
        {
            goToFrame = CGRectMake(self.frame.origin.x, -(self.frame.size.height - _padding), self.frame.size.width, self.frame.size.height);
        }
    }
    
    if (toogleType == 2)
    {
        if (show) 
        {
            goToFrame = CGRectMake(0, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        }
        else 
        {
            goToFrame = CGRectMake(-(self.frame.size.width - _padding), self.frame.origin.y,  self.frame.size.width, self.frame.size.height);
        }
    }
    
    if (toogleType == 3)
    {
        if (show) 
        {
            goToFrame = CGRectMake(parentFrame.size.width-self.frame.size.width, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        }
        else 
        {
            goToFrame = CGRectMake(parentFrame.size.width - _padding, self.frame.origin.y,  self.frame.size.width, self.frame.size.height);
        }
    }
    
    
    [UIView animateWithDuration:_animationDuration animations:^{
        [self setFrame:goToFrame];
    } completion:^(BOOL finished){
        if (finished && self.delegate) {
            if (show && [self.delegate respondsToSelector:@selector(swipeBarDidAppear:)]) {
                [self.delegate swipeBarDidAppear:self];
            }
            else if (!show && [self.delegate respondsToSelector:@selector(swipeBarDidDisappear:)]) {
                [self.delegate swipeBarDidDisappear:self];
            }
        }
    }];
}

#pragma mark - Getters/Setters

- (void)setBarView:(UIView *)view
{
    _barView = view;
    
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    if (toogleType == 0 || toogleType == 1)
    {
        _height = _barView.frame.size.height;
    }
    else {
        _height = _barView.frame.size.width;
    }
    
    switch (toogleType) 
    {
        case 0:
        {
            [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, _barView.frame.size.width, _barView.frame.size.height)];
        }
            break;
        case 1:
        {
            [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y-(_barView.frame.size.height-self.frame.size.height), _barView.frame.size.width, _barView.frame.size.height)];
        }
            break;
        case 2:
        {
            [self setFrame:CGRectMake(self.frame.origin.x-(_barView.frame.size.width-self.frame.size.width), self.frame.origin.y, _barView.frame.size.width, _barView.frame.size.height)];
        }
            break;
        case 3:
        {
            [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, _barView.frame.size.width, _barView.frame.size.height)];
        }

            break;
            
    }
    
    [self addSubview:_barView];
}

- (void)setPadding:(float)padding
{
    _padding = padding;
    CGRect oldFrame = self.frame;
    
    switch (toogleType) 
    {
        case 0:
        {
            float yOrigin = self.parentView.frame.size.height - padding;
            CGRect newFrame = CGRectMake(oldFrame.origin.x, yOrigin, oldFrame.size.width, oldFrame.size.height);
            [self setFrame:newFrame];
        }
            break;
            
        case 1:
        {
            float yOrigin = -(self.frame.size.height - padding);
            CGRect newFrame = CGRectMake(oldFrame.origin.x, yOrigin, oldFrame.size.width, oldFrame.size.height);
            [self setFrame:newFrame];
        }
            break;
            
        case 2:
        {
            float xOrigin = -(self.frame.size.width - padding);
            CGRect newFrame = CGRectMake(xOrigin, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height);
            [self setFrame:newFrame];
        }
            break;
            
        case 3:
        {
            float xOrigin = self.parentView.frame.size.width - padding;
            CGRect newFrame = CGRectMake(xOrigin, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height);
            [self setFrame:newFrame];
        }
            break;
            
        default:
            break;
    }
//    float yOrigin = self.parentView.frame.size.height - padding;
//    CGRect newFrame = CGRectMake(oldFrame.origin.x, yOrigin, oldFrame.size.width, oldFrame.size.height);
//    [self setFrame:newFrame];
}

@end