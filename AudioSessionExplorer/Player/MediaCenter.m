#import <AVFoundation/AVFoundation.h>
#import "AppAudioSession.h"
#import "EventLog.h"
#import "MediaCenter.h"
#import "RecorderSettings.h"


@interface MediaCenter () <AVAudioPlayerDelegate, AVAudioRecorderDelegate>

@property (strong, nonatomic) AVAudioPlayer* currentPlayer;
@property (strong, nonatomic) AVAudioRecorder* currentRecorder;

@end


@implementation MediaCenter

NSNotificationName const MediaCenterDidFinishRecordingNotification = @"MediaCenterDidFinishRecordingNotification";

+ (instancetype)sharedMediaCenter {
    static dispatch_once_t onceToken;
    static MediaCenter* instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[MediaCenter alloc] init];
    });
    return instance;
}

- (void)playUrl:(NSURL *)url {
    [AppAudioSession.sharedSession setActive:YES];
    
    NSError* error = nil;
    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error) {
        [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Player initialization error\n%@", error]];
        return;
    }
    player.delegate = self;
    self.currentPlayer = player;
    [player play];
}

- (void)stopUrl:(NSURL *)url {
    if ([self.currentPlayer.url isEqual:url]) {
        [self.currentPlayer stop];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Player decode error\n%@", error]];
}

- (void)startRecording {
    [AppAudioSession.sharedSession setActive:YES];
    
    NSDictionary* recordingSettings = RecorderSettings.settingsDictionary;
    NSURL* recordingFileUrl = [self recordingFileUrl];
    if (!recordingFileUrl) {
        return;
    }
    
    NSError* error = nil;
    AVAudioRecorder* recorder = [[AVAudioRecorder alloc] initWithURL:recordingFileUrl settings:recordingSettings error:&error];
    if (error) {
        [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Recorder initialization error\n%@", error]];
        return;
    }
    recorder.delegate = self;
    self.currentRecorder = recorder;
    if (![recorder record]) {
        [NSNotificationCenter.defaultCenter postNotificationName:MediaCenterDidFinishRecordingNotification object:self userInfo:@{@"success":@(NO)}];
    }
}

- (void)stopRecording {
    [self.currentRecorder stop];
}

- (BOOL)isRecording {
    return self.currentRecorder.isRecording;
}

- (NSURL*)recordingFileUrl {
    NSURL* caches = [NSFileManager.defaultManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSString* name = [NSString stringWithFormat:@"recording_%@.m4a", [self randomStringOfLength:8]];
    return [caches URLByAppendingPathComponent:name isDirectory:NO];
}

- (NSString*)randomStringOfLength:(NSUInteger)length {
    static const char abc[] = "abcdefghijklmnopqrstuvwxyz";
    unichar buf[length];
    for (size_t i = 0; i < length; ++i) {
        buf[i] = abc[arc4random_uniform(sizeof(abc))];
    }
    return [NSString stringWithCharacters:buf length:length];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    [NSNotificationCenter.defaultCenter postNotificationName:MediaCenterDidFinishRecordingNotification object:self userInfo:@{@"recorder":recorder, @"success":@(flag)}];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Recorder encode error\n%@", error]];
}

@end
