//
//  ImageBrowse.m
//  Hospital
//
//  Created by FZX on 2018/9/27.
//  Copyright © 2018年 wangbao. All rights reserved.
//

#import "ImageBrowse.h"
typedef enum : NSInteger {
    
    kCameraMoveDirectionNone,
    
    kCameraMoveDirectionUp,
    
    kCameraMoveDirectionDown,
    
    kCameraMoveDirectionRight,
    
    kCameraMoveDirectionLeft
    
} CameraMoveDirection ;
CGFloat const gestureMinimumTranslation = 20.0 ;
@interface ImageBrowse ()<UIGestureRecognizerDelegate,UIScrollViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UIImageView *showImgView;
@property (nonatomic, strong) UIScrollView *scroller;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *images;
@end

@implementation ImageBrowse
{
    CameraMoveDirection direction;
    CGFloat lastScale;
    CGRect largeFrame;  //确定图片放大最大的程度
    NSMutableArray *oldFrameArr;
    NSMutableArray *_imageViewArr;
    BOOL flag;
}
+ (instancetype)imageBrowseWithImages:(NSArray *)images index:(NSInteger)index{
    ImageBrowse *browse = [[ImageBrowse alloc]initWithImages:images index:index];
    return browse;
}


- (instancetype)initWithImages:(NSArray *)images index:(NSInteger)index{
    self = [super init];
    if (self) {
        
        _images = images;
        _index = index;
        
        _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
        [_singleTapGestureRecognizer setNumberOfTapsRequired:1];
        _singleTapGestureRecognizer.cancelsTouchesInView = NO;
        [self.view addGestureRecognizer:_singleTapGestureRecognizer];
        
        _containerView = [UIView new];
        _containerView.backgroundColor = [UIColor blackColor];
        _containerView.alpha = 1;
        [self.view addSubview:_containerView];

        
        [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.width.height.equalTo(self.view);
        }];
        
        oldFrameArr = @[].mutableCopy;
        _imageViewArr = @[].mutableCopy;
    
        [_containerView addSubview:self.scroller];
        
        _scroller.contentSize=CGSizeMake( self.view.frame.size.width * images.count, 0 );
        for (int i = 0; i < images.count; i++) {
            CGFloat xx = _scroller.frame.size.width * i;
            UIImageView *showImageView = [[UIImageView alloc] initWithFrame:CGRectMake(xx, 0, self.view.frame.size.width, _scroller.height)];
            showImageView.tag = 100;
            showImageView.contentMode = UIViewContentModeScaleAspectFit;
            [showImageView setMultipleTouchEnabled:YES];
            [showImageView setUserInteractionEnabled:YES];
            
            id img = images[i];
            if ([img isKindOfClass:[UIImage class]]) {
                [showImageView setImage:img];
            }
            else if ([img isKindOfClass:[NSString class]]){
                [showImageView sd_setImageWithURL:[NSURL URLWithString:img]];
            }
            else if ([img isKindOfClass:[NSData class]]){
                [showImageView setImage:[UIImage imageWithData:img]];
            }
            
            
            [self addGestureRecognizerToView:showImageView];
            
            [_scroller addSubview:showImageView];
            
            [oldFrameArr addObject:[NSValue valueWithCGRect:showImageView.frame]];
            
            [_imageViewArr addObject:showImageView];
            
            largeFrame = CGRectMake(0 - AR_SCREEN_WIDTH, 0 - AR_SCREEN_HEIGHT, 3 * showImageView.frame.size.width, 3 * showImageView.frame.size.height);
        }
        
        [_scroller setContentOffset:CGPointMake(index * self.view.frame.size.width, 0) animated:NO];
        
        
        [_containerView addSubview:self.collectionView];
        
        [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_offset(55);
            make.bottom.equalTo(_containerView).offset(-25);
            make.centerX.equalTo(_containerView);
            make.width.equalTo(_containerView).offset(-30);
        }];
        
    }
    return self;
}



- (UIScrollView *)scroller{
    if (!_scroller) {
        _scroller = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, AR_SCREEN_HEIGHT -140)];
        _scroller.pagingEnabled = YES;
        _scroller.directionalLockEnabled = YES;
        _scroller.bounces = NO;
        _scroller.delegate = self;
    }
    return _scroller;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    if (scrollView == self.collectionView) {
        return;
    }
    // 得到每页宽度
    CGFloat pageWidth = scrollView.frame.size.width;
    // 根据当前的x坐标和页宽度计算出当前页数
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if (page != _index) {
        [self reLayoutImageView];
        _index = page;
        [_collectionView reloadData];
    }
    
}



- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *boothLayout = [[UICollectionViewFlowLayout alloc]init];
        boothLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        boothLayout.itemSize = CGSizeMake(70, 55);
        boothLayout.minimumLineSpacing = 5;
        boothLayout.minimumInteritemSpacing = 0;
        boothLayout.sectionInset = UIEdgeInsetsMake(0,0,0,0);
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:boothLayout];
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
    }
    return _collectionView;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    [cell removeAllSubviews];
    
    UIImageView *imageview = [[UIImageView alloc] init];
    imageview.frame = cell.bounds;
    [imageview setUserInteractionEnabled:YES];
    [cell addSubview:imageview];
    
    id img = _images[indexPath.item];
    if ([img isKindOfClass:[UIImage class]]) {
        imageview.image = img;
    }
    else if ([img isKindOfClass:[NSString class]]){
        [imageview sd_setImageWithURL:[NSURL URLWithString:img]];
    }
    else if ([img isKindOfClass:[NSData class]]){
        imageview.image = [UIImage imageWithData:img];
    }
    
    if (indexPath.item == _index) {
        cell.layer.borderColor = Theme_HighLight_Color.CGColor;
        cell.layer.borderWidth = 2;
    }
    else{
        cell.layer.borderColor = [UIColor clearColor].CGColor;
        cell.layer.borderWidth = 2;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    _index = indexPath.item;
    [collectionView reloadData];
    [self reLayoutImageView];
    [_scroller setContentOffset:CGPointMake(indexPath.item * _scroller.frame.size.width, 0) animated:YES];
}

- (void)reLayoutImageView{
    for (int i = 0; i < self.scroller.subviews.count; i++) {
        NSObject *obj = self.scroller.subviews[i];
        if ([obj isKindOfClass:[UIImageView class]]) {
            UIImageView *iv = (UIImageView *)obj;
            if (iv.tag == 100) {
                CGRect frame =  [oldFrameArr[i] CGRectValue];
                iv.frame = frame;
            }
        }
    }
}

// 添加所有的手势
- (void) addGestureRecognizerToView:(UIView *)view
{

    // 缩放手势
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [view addGestureRecognizer:pinchGestureRecognizer];
    
    // 移动手势
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [view addGestureRecognizer:panGestureRecognizer];
    [_scroller.panGestureRecognizer requireGestureRecognizerToFail:panGestureRecognizer];
    
    //双击手势
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    [view addGestureRecognizer:doubleTapGestureRecognizer];
    //这行很关键，意思是只有当没有检测到doubleTapGestureRecognizer 或者 检测doubleTapGestureRecognizer失败，singleTapGestureRecognizer才有效
    [_singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
}



// 处理缩放手势
- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    UIView *view = pinchGestureRecognizer.view;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        pinchGestureRecognizer.scale = 1;
    }
}

- (void)doubleTap:(UIGestureRecognizer *)doubleGestureRecognizer{
    UIView *view = doubleGestureRecognizer.view;
    CGRect frame = [oldFrameArr[_index] CGRectValue];
    if (view.size.width > frame.size.width) {
        view.frame = frame;
        return;
    }
   
    if (doubleGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        view.transform = CGAffineTransformScale(view.transform, 2, 2);
    }
}

// 处理拖拉手势
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGRect frame = [oldFrameArr.firstObject CGRectValue];
    UIView *view = panGestureRecognizer.view;
    
    if (view.size.width <= frame.size.width) {

        CGPoint translation = [panGestureRecognizer translationInView:self.view];
        if (panGestureRecognizer.state ==UIGestureRecognizerStateBegan){
            direction = kCameraMoveDirectionNone;
        }
        else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged && direction == kCameraMoveDirectionNone){
            direction = [self determineCameraDirectionIfNeeded:translation];
            // ok, now initiate movement in the direction indicated by the user's gesture
            switch (direction) {
                case kCameraMoveDirectionDown:
                    NSLog(@"Start moving down");
                    break;
                case kCameraMoveDirectionUp:
                    NSLog(@"Start moving up");
                    break;
                case kCameraMoveDirectionRight:
                    NSLog(@"Start moving right");
                    if (_scroller.contentOffset.x == 0) {
                        return;
                    }
                    [self reLayoutImageView];
                    [_scroller setContentOffset:CGPointMake(_scroller.contentOffset.x - _scroller.frame.size.width, 0) animated:YES];
                    int page = floor((_scroller.contentOffset.x - _scroller.frame.size.width / 2) / _scroller.frame.size.width);
                    if (page != _index) {
                        _index = page;
                        [_collectionView reloadData];
                    }

                    break;
                case kCameraMoveDirectionLeft:
                    NSLog(@"Start moving left");
                    if (_scroller.contentOffset.x >= _scroller.contentSize.width - _scroller.frame.size.width) {
                        return;
                    }
                    [self reLayoutImageView];
                    [_scroller setContentOffset:CGPointMake(_scroller.contentOffset.x + _scroller.frame.size.width, 0) animated:YES];
                    int page2 = floor((_scroller.contentOffset.x - _scroller.frame.size.width / 2) / _scroller.frame.size.width) + 1 + 1;
                    if (page2 != _index) {
                        _index = page2;
                        [_collectionView reloadData];
                    }
                    break;
                default:
                    break;
            }
        }
        else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded){
            
            NSLog(@"Stop");
        }
        return;
    }
    
    
    
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x, view.center.y + translation.y}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
}

- ( CameraMoveDirection )determineCameraDirectionIfNeeded:( CGPoint)translation{
    
    if (direction != kCameraMoveDirectionNone)
        return direction;
    // determine if horizontal swipe only if you meet some minimum velocity
    if (fabs(translation.x) > gestureMinimumTranslation){
        BOOL gestureHorizontal = NO;
        if (translation.y == 0.0 )
            gestureHorizontal = YES;
        else
            gestureHorizontal = (fabs(translation.x / translation.y) > 5.0 );
        if (gestureHorizontal){
            if (translation.x > 0.0 )
                return kCameraMoveDirectionRight;
            else
                return kCameraMoveDirectionLeft;
        }
    }
    // determine if vertical swipe only if you meet some minimum velocity
    else if (fabs(translation.y) > gestureMinimumTranslation){
        BOOL gestureVertical = NO;
        if (translation.x == 0.0 )
            gestureVertical = YES;
        else
            gestureVertical = (fabs(translation.y / translation.x) > 5.0 );
        if (gestureVertical){
            if (translation.y > 0.0 )
                return kCameraMoveDirectionDown;
            else
                return kCameraMoveDirectionUp;
        }
    }
    return direction;
}

// 点击其他区域关闭弹窗
- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded){
        CGPoint location = [sender locationInView:nil];
        if (![_collectionView pointInside:[_collectionView convertPoint:location fromView:_collectionView.superview] withEvent:nil]){
            dispatch_async(dispatch_get_main_queue(), ^{
                [_containerView.window removeGestureRecognizer:sender];
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }
}


- (ZXModallyAnimationController *)animationController {
    ZXModallyAnimationController *animation = [[ZXModallyAnimationController alloc]init];
    animation.animationStyle = WSModallyAnimationStyleAlert;
    return animation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
