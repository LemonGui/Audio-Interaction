//
//  EMRecorderManager.m
//  录音播放Demo
//
//  Created by Lemon on 16/9/2.
//  Copyright © 2016年 Lemon. All rights reserved.
//

#import "EMRecorderManager.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"
#define BasePath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
#define PcmNmae [NSString stringWithFormat:@"%d.caf",(int)[NSDate date].timeIntervalSince1970]
#define Mp3Name [NSString stringWithFormat:@"%d.mp3",(int)[NSDate date].timeIntervalSince1970]
#define PcmFullPath [BasePath stringByAppendingPathComponent:PcmNmae]
#define Mp3FullPath [BasePath stringByAppendingPathComponent:Mp3Name]

@interface EMRecorderManager ()<AVAudioPlayerDelegate>
@property (nonatomic,strong) AVAudioRecorder * audioRecorder;
@property (nonatomic,strong) AVAudioPlayer * audioPlayer;
@property (nonatomic,strong) AVAudioSession * audioSession;
@property (nonatomic,strong) NSURL * recordUrl;
@property (nonatomic,strong) NSURL * mp3FileUrl;
@property (nonatomic,strong) NSURL * audioFileSavePath;
@property (nonatomic,strong) NSDictionary * recordSetting;
@end

@implementation EMRecorderManager
SB_ARC_SINGLETON_IMPLEMENT(EMRecorderManager)

-(NSDictionary *)recordSetting{
    if (!_recordSetting) {
        _recordSetting = [[NSMutableDictionary alloc] init];
        //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM  
        [_recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）, 采样率必须要设为11025才能使转化成mp3格式后不会失真
        [_recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
        //录音通道数  1 或 2 ，要转换成mp3格式必须为双通道
        [_recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        //线性采样位数  8、16、24、32
        [_recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        //录音的质量
        [_recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    }
    return _recordSetting;
}

//开始录音
-(void)recordStart{
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_recordUrl.absoluteString]) {
        NSError * error;
        [fileManager removeItemAtPath:_recordUrl.absoluteString error:&error];
        if (error) {
            NSLog(@"error:%@",error);
        }else{
            NSLog(@"删除pcm成功-%@",_recordUrl.absoluteString);
        }
    }

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];//设置类别,表示该应用同时支持播放和录音
    [[AVAudioSession sharedInstance] setActive:YES error:nil];//启动音频会话管理,此时会阻断后台音乐的播放.
    _recordUrl = [NSURL URLWithString:PcmFullPath];
    
    NSLog(@"%@",PcmFullPath);
    //初始化
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:_recordUrl settings:self.recordSetting error:nil];
    //开启音量检测
    _audioRecorder.meteringEnabled = YES;
    [self.audioRecorder prepareToRecord];
    [self.audioRecorder peakPowerForChannel:0.0];
    [self.audioRecorder record];
}

//停止录音
-(void)recordStop{
    [self.audioRecorder stop];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];//一定要在录音停止以后再关闭音频会话管理（否则会报错），此时会延续后台音乐播放
}

//播放
-(void)playStart{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    NSError * playerError;
    if (_mp3FileUrl != nil) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_mp3FileUrl error:&playerError];
    }else{
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_recordUrl error:&playerError];
    }
    
    self.audioPlayer.delegate = self;
    NSLog(@"音频时长为：%i", (int)self.audioPlayer.duration);
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

//暂停播放
-(void)playPause{
    [self.audioPlayer pause];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

//停止播放
-(void)playStop{
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    }
}

-(NSData *)convertToMP3
{
        NSString * mp3Path = [_recordUrl.absoluteString stringByReplacingOccurrencesOfString:@".caf" withString:@".mp3"];
        _mp3FileUrl = [NSURL URLWithString:mp3Path];
        @try {
            int read, write;
            
            FILE *pcm = fopen([[_recordUrl absoluteString] cStringUsingEncoding:NSASCIIStringEncoding], "rb");   //source 被转换的音频文件位置
            fseek(pcm, 4*1024, SEEK_CUR); //skip file header
            FILE *mp3 = fopen([[_mp3FileUrl absoluteString] cStringUsingEncoding:NSASCIIStringEncoding], "wb"); //output 输出生成的Mp3文件位置
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*2];
            unsigned char mp3_buffer[MP3_SIZE];
            
            lame_t lame = lame_init();
            lame_set_in_samplerate(lame, 11025.0);
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            
            do {
                read =(int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
                if (read == 0)
                    write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                else
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                
                fwrite(mp3_buffer, write, 1, mp3);
                
            } while (read != 0);
            
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
        }
        @catch (NSException *exception) {
            NSLog(@"转换mp3异常:%@",[exception description]);
        }
        @finally {
            _audioFileSavePath = _mp3FileUrl;
            NSLog(@"MP3生成成功:%@",_audioFileSavePath.absoluteString);
            
            NSData * data = [NSData dataWithContentsOfFile:_audioFileSavePath.absoluteString];
            NSLog(@"mp3文件大小--%ld KB,",data.length/1000);
            
            if (self.finishMP3DataBlock) {
                self.finishMP3DataBlock(data);
            }
            return data;
        }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self.audioPlayer stop];
    [self.audioPlayer prepareToPlay];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    if (flag) {
        if (self.playFinishBlock) {
            self.playFinishBlock();
        }
    }
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    if (self.hasErrorBlock) {
        self.hasErrorBlock(error);
    }
}

@end
