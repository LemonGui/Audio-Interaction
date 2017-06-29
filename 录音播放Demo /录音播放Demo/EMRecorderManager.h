//
//  EMRecorderManager.h
//  录音播放Demo
//
//  Created by Lemon on 16/9/2.
//  Copyright © 2016年 Lemon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "INTERFACE.h"
@interface EMRecorderManager : NSObject
@property (nonatomic,copy) void (^playFinishBlock)();
@property (nonatomic,copy) void (^hasErrorBlock)(NSError *error);//解码错误执行的动作
@property (nonatomic,copy) void (^finishMP3DataBlock)(NSData * data);

SB_ARC_SINGLETON_DEFINE(EMRecorderManager)

-(void)recordStart;
-(void)recordStop;

-(void)playStart;
-(void)playPause;
-(void)playStop;

- (NSData *)convertToMP3;

@end
