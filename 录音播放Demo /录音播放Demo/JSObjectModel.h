//
//  JSObjectModel.h
//  录音播放Demo
//
//  Created by Lemon on 16/9/6.
//  Copyright © 2016年 Lemon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "EMRecorderManager.h"

@protocol JSObjcDelegate <JSExport>
- (void)startRecord;
- (void)stopRecord;
- (void)startPlay;
- (void)stopPlay;
@end

@interface JSObjectModel : NSObject <JSObjcDelegate>
@property (nonatomic, weak) JSContext *jsContext;
@property (nonatomic, weak) UIWebView *webView;
@end
