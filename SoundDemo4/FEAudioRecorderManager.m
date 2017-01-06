//
//  TKAudioRecorder.m
//  IPad_TalkmateGame
//
//  Created by FlyElephant on 16/11/9.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import "FEAudioRecorderManager.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const TempAudioFileName     = @"talkmateRecordingmodule";
static NSString *const SaveAudioFormat       = @"wav";

@interface FEAudioRecorderManager()<AVAudioRecorderDelegate>

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
//@property (strong, nonatomic) AVPlayer *avPlayer;

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

//录音时间控制
@property (assign,nonatomic) NSTimeInterval minimumRecordDuration;
@property (assign,nonatomic) NSTimeInterval maximumRecordDuration;
@property (assign, nonatomic) NSTimeInterval     recordDuration;

@end

@implementation FEAudioRecorderManager

#pragma mark - LifeCycle

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static TKAudioRecorderManager *recorderManager = nil;
    dispatch_once(&onceToken, ^{
        recorderManager = [TKAudioRecorderManager new];
        recorderManager.maximumRecordDuration = 10.0f;
        recorderManager.minimumRecordDuration = 1;
    });
    return recorderManager;
}

- (void)dealloc {
    NSLog(@"♻️ Dealloc %@", NSStringFromClass([self class]));
}

#pragma mark - Accessors

- (CGFloat)averagePower {
    [self.audioRecorder updateMeters];//更新测量值
    CGFloat power = [self.audioRecorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围为-160到0之间
    return (power + 160.0);
}

- (CGFloat)recordProgress {
    return self.averagePower/160.0;
}

//- (AVPlayer *)avPlayer {
//    if (!_avPlayer) {
//        _avPlayer = [AVPlayer new];
//        _avPlayer.volume = 1.0;
//    }
//    return _avPlayer;
//}

#pragma mark - Public

- (void)record {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    NSString *soundFilePath = [self audioRecordPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:soundFilePath isDirectory:&isDir]) {
        [fileManager removeItemAtPath:soundFilePath error:nil];
    }
    if (self.audioRecorder == nil) {
        NSError *error   = nil;
        NSURL   *fileUrl = [NSURL URLWithString:soundFilePath];
        self.audioRecorder                 = [[ AVAudioRecorder alloc] initWithURL:fileUrl settings:[self audioRecordingSettings] error:&error];
        self.audioRecorder.meteringEnabled = YES;
        self.audioRecorder.delegate        = self;
        [self.audioRecorder recordForDuration:self.maximumRecordDuration];
    }
    if ([self.audioRecorder prepareToRecord]) {
        [self.audioRecorder record];
    }
}

- (void)stopRecord {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
//    self.recordDuration               = self.audioRecorder.currentTime;
//    if (self.recordDuration < self.minimumRecordDuration) {
//        [self.audioRecorder stop];
//        if ([self.delegate respondsToSelector:@selector(recordManagerError:recordDuration:)]) {
//            [self.delegate recordManagerError:[NSURL fileURLWithPath:[self audioRecordPath]] recordDuration:self.recordDuration];
//        }
//        return;
//    }
    [self.audioRecorder stop];
}

- (void)play {
//    NSURL *recordUrl = [NSURL fileURLWithPath:[self audioRecordPath]];
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:recordUrl];
//    [self.avPlayer replaceCurrentItemWithPlayerItem:item];
//    self.avPlayer.volume = 1.0f;
//    [self.avPlayer play];
    
    NSError *sessionError;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [session setActive:YES error:nil];
    if (sessionError) {
        NSLog(@"%@",sessionError);
    }
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];

    NSError *error;
    NSURL   *fileUrl = [NSURL fileURLWithPath:[self audioRecordPath]];
    self.audioPlayer                 = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
    self.audioPlayer.meteringEnabled = YES;
    self.audioPlayer.numberOfLoops   = 0;
    [self.audioPlayer setVolume:10.0f];
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

- (void)stopPlay {
//    [self.avPlayer pause];
    [self.audioPlayer stop];
}

#pragma mark - Accessors

- (NSString *)recordPath {
    return [self audioRecordPath];
}

- (NSString *)audioRecordPath {
    NSArray  *dirPaths      = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@.%@", [dirPaths objectAtIndex:0], TempAudioFileName, SaveAudioFormat];
    return soundFilePath;
}

- (NSDictionary *)audioRecordingSettings {
    NSDictionary        *result        = nil;
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    //kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000 44100是CD的采样率
    [recordSetting setValue:[NSNumber numberWithFloat:16000] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    result = [NSDictionary dictionaryWithDictionary:recordSetting];
    return result;
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        if ([self.delegate respondsToSelector:@selector(recordManagerFinishRecording:recordDuration:)]) {
            [self.delegate recordManagerFinishRecording:[NSURL fileURLWithPath:[self audioRecordPath]] recordDuration:self.recordDuration];
        }
    }
}

@end
