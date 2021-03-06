//
//  GSShareView.m
//  SocialSDKDemo
//
//  Created by lijunjie on 17/12/2016.
//  Copyright © 2016 GagSquad. All rights reserved.
//

#import "GSShareView.h"
#import "GSLogger.h"
#import "GSCollectionViewHorizontalLayout.h"
#import "GSCollectionViewCell.h"
#import "GSShareManager.h"
#import "GSPlatformParamConfigManager.h"
#import "GSPlatformParamConfigProtocol.h"

@interface GSShareView () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSArray<NSNumber *>* _channels;
    
    GSShareViewCompletionBlock _completionBlock;
    
    BOOL _isUninstall;//标记是否有不支持的平台
}

@property (nonatomic, strong) UIWindow *window;

@end

@implementation GSShareView

- (void)dealloc
{
    GSLogger(@"GSShareView 释放了");
}

+ (void)showShareViewWithChannels:(NSArray *)channels completionBlock:(GSShareViewCompletionBlock)completionBlock;
{
    GSShareView *w = [[GSShareView alloc] initWithChannels:channels completionBlock:completionBlock];
    [w makeKeyAndVisible];
    w.window = w;
}

- (instancetype)initWithChannels:(NSArray<NSNumber *> *)channels completionBlock:(GSShareViewCompletionBlock)completionBlock
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        _isUninstall = NO;
        [self setWindowLevel:UIWindowLevelAlert + 100];
        self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.3];
        self.userInteractionEnabled = YES;
        NSMutableArray<NSNumber *> *temp = [NSMutableArray array];
        for (NSNumber *number in channels) {
            GSShareChannelType type = [number unsignedIntegerValue];
            id<GSPlatformParamConfigProtocol> config = [[GSPlatformParamConfigManager share] getConfigProtocolWithPlatformType:[GSShareManager getPlatformTypeWithShareChannelType:type]];
            if (type == GSShareChannelTypeSina) {
                [temp addObject:@(type)];
            } else {
                if (config && [[config class] isInstalled]) {
                    [temp addObject:@(type)];
                } else {
                    _isUninstall = YES;
                    GSLogger(@"不支持分享渠道GSShareChannelType = %ld", type);
                }
            }
        }
        _channels = [temp copy];
        _completionBlock = completionBlock;
        [self createView];
    }
    return self;
}

- (void)createView
{
    CGFloat height = 260.f;
    
    CGSize size = self.frame.size;
    UIView *shareBGView = [[UIView alloc] initWithFrame:CGRectMake(0, size.height, size.width, height)];
    shareBGView.backgroundColor = [UIColor colorWithRed:233/255.f green:239/255.f blue:242/255.f alpha:1.0];
    [self addSubview:shareBGView];
    
    CGFloat hfHeight = 40.f;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, hfHeight)];
    UILabel *title = [[UILabel alloc] initWithFrame:headerView.bounds];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [UIColor colorWithRed:143/255.f green:143/255.f blue:143/255.f alpha:1.0];
    title.font = [UIFont systemFontOfSize:16.f];
    title.text = @"请选择分享平台";
    [headerView addSubview:title];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, headerView.frame.size.height + headerView.frame.origin.y, size.width, height - hfHeight * 2)];
    contentView.backgroundColor = [UIColor clearColor];
    
    GSCollectionViewHorizontalLayout *layout =[[GSCollectionViewHorizontalLayout alloc] init];
    layout.itemCountPerRow = 4;
    layout.rowCount = 2;
    
    CGFloat wh = contentView.frame.size.height / 2;
    layout.itemSize = CGSizeMake([UIScreen mainScreen].bounds.size.width/4, wh);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    layout.headerReferenceSize = CGSizeMake(0, 0);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView =[[UICollectionView alloc] initWithFrame:contentView.bounds collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.pagingEnabled = YES;
    [collectionView registerClass:[GSCollectionViewCell class] forCellWithReuseIdentifier:@"GSCollectionViewCell"];
    [contentView addSubview:collectionView];
    
    UIView *fooderView = [[UIView alloc] initWithFrame:CGRectMake(0, contentView.frame.size.height + contentView.frame.origin.y, size.width, hfHeight)];
    fooderView.backgroundColor = [UIColor orangeColor];
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.exclusiveTouch = YES;
    cancelBtn.frame = fooderView.bounds;
    [cancelBtn setTitleColor:[UIColor colorWithRed:90/255.f green:90/255.f blue:90/255.f alpha:1.0] forState:UIControlStateNormal];
    [cancelBtn setBackgroundColor:[UIColor colorWithRed:246/255.f green:250/255.f blue:252/255.f alpha:1.0]];
    [cancelBtn setTitle:@"取消分享" forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [fooderView addSubview:cancelBtn];
    //246 250 252
    [shareBGView addSubview:headerView];
    [shareBGView addSubview:contentView];
    [shareBGView addSubview:fooderView];
    
    [UIView animateWithDuration:0.3 animations:^{
        shareBGView.frame = CGRectMake(0, size.height - height, size.width, height);
    }];
    
#if TARGET_IPHONE_SIMULATOR
    if (_isUninstall) {
        UILabel *error = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, 16)];
        error.backgroundColor = [UIColor redColor];
        error.numberOfLines = 0;
        error.text = @"由于部分分享平台不支持，所以隐藏了相关平台的图标，此消息只在模拟器提示";
        [error sizeToFit];
        [self addSubview:error];
    }
#endif
}

- (void)cancelAction:(id)sender
{
    GSLogger(@"cancel");
    [self removeIsCancel:YES channelType:GSShareChannelTypeNone];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self removeIsCancel:YES channelType:GSShareChannelTypeNone];
}

- (void)removeIsCancel:(BOOL)isCancel channelType:(GSShareChannelType)channelType;
{
    if (_completionBlock) {
        _completionBlock(isCancel,channelType);
    }
    [self resignKeyWindow];
    _window = nil;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger res = 0;
    GSCollectionViewHorizontalLayout *layout = (GSCollectionViewHorizontalLayout *)collectionView.collectionViewLayout;
    NSInteger count = _channels.count;
    NSInteger pageCount = layout.itemCountPerRow * layout.rowCount;
    NSUInteger t = 0;
    if (pageCount != 0) {
        t = count / pageCount;
    }
    if (count % pageCount != 0) {
        res = pageCount * (t + 1);
    } else {
        res = count;
    }
    return res;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifierCell = @"GSCollectionViewCell";
    GSCollectionViewCell *cell = nil;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifierCell forIndexPath:indexPath];
    if (indexPath.item < [_channels count]) {
        [cell updateUI:[_channels[indexPath.row] unsignedIntegerValue]];
    }
    cell.hidden = (indexPath.item >= [_channels count]);
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    [self removeIsCancel:NO channelType:[_channels[row] unsignedIntegerValue]];
}

@end
