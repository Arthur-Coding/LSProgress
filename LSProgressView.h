//
//  LSProgressView.h
//  BicycleSharing
//
//  Created by ArthurShuai on 2017/3/18.
//  Copyright © 2017年 qusu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LSProgressView;
@protocol LSProgressDelegate <NSObject>

@optional
- (void)startSwitchNextProgress:(LSProgressView *)progess;
- (void)nextProgressSwitched:(LSProgressView *)progess;

@end

@interface LSProgressView : UIView

/**
 * 当前进度的标题
 */
@property (nonatomic, strong, readonly) NSString *currentTitle;
/**
 * 当前进度的索引
 */
@property (nonatomic, assign, readonly) NSInteger currentIndex;

@property (nonatomic) id<LSProgressDelegate> delegate;

/**
 init

 @param frame frame
 @param titles 提示标题数组,最多5个
 @param beginIndex 开始读进度处的索引
 @return progress view
 */
- (instancetype)initWithFrame:(CGRect)frame andTitles:(NSArray<NSString *> *)titles beginIndex:(NSInteger)beginIndex;

/**
 * 切换下一个未完成的进度
 * 若已是最后一个进度，将不起作用
 */
- (void)next;
/**
 * 切换上一个未完成的进度
 * 若已是第一个进度，将不起作用
 */
- (void)back;

/**
 * 将某一进度标记为完成
 * 默认小于当前进度索引的进度都是已完成，反正未完成
 @param index 进度所在索引
 */
- (void)finishProgress:(NSInteger)index;
/**
 * 将某一进度标记为未完成
 * 默认小于当前进度索引的进度都是已完成，反正未完成
 @param index 进度所在索引
 */
- (void)unFinishProgress:(NSInteger)index;

@end
