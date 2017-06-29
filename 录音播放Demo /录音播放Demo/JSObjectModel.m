//
//  JSObjectModel.m
//  录音播放Demo
//
//  Created by Lemon on 16/9/6.
//  Copyright © 2016年 Lemon. All rights reserved.
//

#import "JSObjectModel.h"

@interface JSObjectModel ()
@property (nonatomic, weak) EMRecorderManager * recordManager;
@property (nonatomic, weak) NSThread * thread;
@end

@implementation JSObjectModel

-(instancetype)init{
    if (self = [super init]) {
        __weak typeof(self) __weakMe = self;
        _recordManager = [EMRecorderManager sharedEMRecorderManager];
        _recordManager.hasErrorBlock = ^(NSError *error){
            JSValue *jsCallback = __weakMe.jsContext[@"onRecordFailed"];
            [jsCallback callWithArguments:nil];
        };
    }
    return self;
}

-(void)startRecord{
    NSLog(@"开始录音");
    [_recordManager recordStart];
}

-(void)stopRecord{
    NSLog(@"结束录音");
    [_recordManager recordStop];
    _thread = [NSThread currentThread];
    NSLog(@"stopRecord 线程 %@--",[NSThread currentThread]);
    
    __weak typeof(self) __weakMe = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [__weakMe.recordManager convertToMP3];
        NSLog(@"转mp3返回的数据----%ld---",data.length);
        NSString * base64 = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        NSLog(@"--base64  %ld",base64.length);
        [__weakMe performSelector:@selector(sendData:) onThread:__weakMe.thread withObject:base64 waitUntilDone:YES];
    });
}


- (void)startPlay{
    NSLog(@"开始播放");
    [_recordManager playStart];
    __weak typeof(self) __weakMe = self;
    _recordManager.playFinishBlock = ^(){
        JSValue *jsCallback = __weakMe.jsContext[@"onRecordPlayFinished"];
        [jsCallback callWithArguments:nil];
    };

}

- (void)stopPlay{
    NSLog(@"结束播放");
    [_recordManager playStop];
}

-(void)sendData:(NSString *)data{
    NSLog(@"sendData 线程 %@",[NSThread currentThread]);
    JSValue *jsCallback = self.jsContext[@"getRecordData"];
    [jsCallback callWithArguments:@[data]];
}

-(void)dealloc{
    
}

@end
