//
//  TKAudioRecorder.h
//  IPad_TalkmateGame
//
//  Created by FlyElephant on 16/11/9.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol  AudioRecorderManagerDelegate<NSObject>

-(void)recordManagerError:(NSURL *)recordUrl recordDuration:(NSTimeInterval)recordDuration;

@optional
-(void)recordManagerFinishRecording:(NSURL *)recordUrl recordDuration:(NSTimeInterval)recordDuration;

@end

@interface FEAudioRecorderManager : NSObject

@property (weak, nonatomic) id<AudioRecorderManagerDelegate>  delegate;

@property (assign, readonly, nonatomic) CGFloat averagePower;

@property (assign, readonly, nonatomic) CGFloat recordProgress;

@property (copy, nonatomic) NSString *recordPath;

+ (instancetype)sharedInstance;

- (void)record;

- (void)stopRecord;

- (void)play;

- (void)stopPlay;

@end
