//
//  ViewController.m
//  录音播放Demo
//
//  Created by Lemon on 16/9/1.
//  Copyright © 2016年 Lemon. All rights reserved.
//

#import "ViewController.h"
#import "EMRecorderManager.h"
#import "WebViewController.h"

@interface ViewController ()
@property (nonatomic,strong) EMRecorderManager * recordManager;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLab;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic,strong) NSTimer* timer;;
@property (nonatomic,assign) NSInteger recordTime;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.playBtn.hidden = YES;
    
    self.recordManager = [EMRecorderManager sharedEMRecorderManager];
    __weak typeof(self) __weakMe = self;
    _recordManager.playFinishBlock = ^(){
        __weakMe.playBtn.selected = NO;
        [__weakMe resetData];
    };
    _recordManager.playFinishBlock = ^(){
        [__weakMe resetData];
        __weakMe.playBtn.selected = NO;
    };

}

- (IBAction)record:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [_recordManager recordStart];
        _recordTime =0;
        [self recordTimeStart];
        self.playBtn.hidden = YES;
    }
    else{
        [_recordManager recordStop];
        [self resetData];
        [_recordManager convertToMP3];
        self.playBtn.hidden = NO;
    }
}

- (IBAction)play:(UIButton *)sender {
    if (sender.selected) {
        [_recordManager playPause];
        [_timer invalidate];
    }else{
        [self resetData];
        [self recordTimeStart];
        [_recordManager playStart];
    }
    sender.selected = !sender.selected;
}

- (void)recordTimeStart {
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(recordTimeTick) userInfo:nil repeats:YES];
}

-(void)recordTimeTick{
    _recordTime += 1;
    self.progressView.progress = _recordTime/30.0;

    if (_recordTime == 30) {
        [self resetData];
        if (self.recordBtn.selected) {
            [self record:self.recordBtn];
        }
        return;
    }

    int minute =(int)_recordTime/60.0;
    int second =(int)_recordTime-minute*60;
    [_timeLab setText:[NSString stringWithFormat:@"%02d:%02d",minute,second]];
}

-(void)resetData{
    _recordTime =0;
    self.progressView.progress = 0;
    _timeLab.text = @"00:00";
    [_timer invalidate];
    _timer = nil;
}

- (IBAction)btnCilck:(id)sender {
    WebViewController * vc = [[WebViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
