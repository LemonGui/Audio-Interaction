//
//  WebViewController.m
//  录音播放Demo
//
//  Created by Lemon on 16/9/2.
//  Copyright © 2016年 Lemon. All rights reserved.
//

#import "WebViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSObjectModel.h"

@interface WebViewController ()<UIWebViewDelegate>
@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) UIWebView * webView;

@end

@implementation WebViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    UIWebView * webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    self.webView = webView;
    webView.delegate = self;
    
//http://172.16.20.25:9090/#/record?_k=i1ss7z http://172.16.86.39/fenda/build/#/record?_k=ca1cx3sdfsfdf
//    int a = arc4random();
//    NSString * testStr = [NSString stringWithFormat:@"http://172.16.20.25:9090/#/record?_k=i1ss7z%d",a];
    
    NSString * testStr = @"http://172.16.20.25:9090/#/record?_k=5vcgg9";
    NSURLRequest * requst = [NSURLRequest requestWithURL:[NSURL URLWithString:testStr]];
    [webView loadRequest:requst];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    JSObjectModel * model = [[JSObjectModel alloc] init];
    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.jsContext[@"eastmoney"] = model;
    
    model.jsContext = self.jsContext;
    model.webView = webView;
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
    };
}

-(void)dealloc{
    self.webView = nil;
    self.jsContext = nil;
}

@end
