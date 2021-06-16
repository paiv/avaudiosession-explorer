#import <AVFoundation/AVFoundation.h>
#import "AppAudioSession.h"
#import "EventLog.h"
#import "MediaCenter.h"
#import "RecorderSettings.h"


@interface MediaCenter () <AVAudioRecorderDelegate>

@property (strong, nonatomic) AVPlayer* currentPlayer;
@property (strong, nonatomic) AVPlayerItem* currentPlayerItem;
@property (strong, nonatomic) AVAudioRecorder* currentRecorder;

@end


@implementation MediaCenter

NSNotificationName const MediaCenterWillStartPlayingNotification = @"MediaCenterWillStartPlayingNotification";
NSNotificationName const MediaCenterDidFinishRecordingNotification = @"MediaCenterDidFinishRecordingNotification";

static void* PlayerStatusObserverContext = &PlayerStatusObserverContext;
static void* PlayerItemStatusObserverContext = &PlayerItemStatusObserverContext;

+ (instancetype)sharedMediaCenter {
    static dispatch_once_t onceToken;
    static MediaCenter* instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[MediaCenter alloc] init];
    });
    return instance;
}

- (void)dealloc {
    self.currentPlayer = nil;
    self.currentPlayerItem = nil;
}

- (void)setCurrentPlayer:(AVPlayer *)currentPlayer {
    if (_currentPlayer) {
        [_currentPlayer removeObserver:self forKeyPath:@"currentItem"];
        [_currentPlayer removeObserver:self forKeyPath:@"status"];
    }
    _currentPlayer = currentPlayer;
    if (_currentPlayer) {
        [_currentPlayer addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:PlayerStatusObserverContext];
        [_currentPlayer addObserver:self forKeyPath:@"currentItem" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:PlayerStatusObserverContext];
    }
}

- (void)setCurrentPlayerItem:(AVPlayerItem *)item {
    if (_currentPlayerItem) {
        [_currentPlayerItem removeObserver:self forKeyPath:@"status"];
    }
    _currentPlayerItem = item;
    if (_currentPlayerItem) {
        [_currentPlayerItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:PlayerItemStatusObserverContext];
    }
}

- (NSURL *)currentUrl {
    AVAsset* asset = self.currentPlayerItem.asset;
    if ([asset isKindOfClass:AVURLAsset.class]) {
        return [(AVURLAsset*)asset URL];
    }
    return nil;
}

- (void)playFromPlaylist:(NSArray<NSURL *> *)playlist atIndex:(NSUInteger)index {
    NSArray* sublist = [playlist subarrayWithRange:NSMakeRange(index, playlist.count - index)];
    NSArray* items = [self playerItemsWithPlaylist:sublist];
    AVQueuePlayer* player = [AVQueuePlayer queuePlayerWithItems:items];
    self.currentPlayerItem = nil;
    self.currentPlayer = player;
    [player play];
}

- (NSArray<AVPlayerItem*>*)playerItemsWithPlaylist:(NSArray<NSURL*>*)playlist {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:playlist.count];
    [playlist enumerateObjectsUsingBlock:^(NSURL* url, NSUInteger idx, BOOL* stop) {
        AVPlayerItem* item = [AVPlayerItem playerItemWithURL:url];
        [items addObject:item];
    }];
    return items;
}

- (void)playUrl:(NSURL *)url {
    [AppAudioSession.sharedSession setActive:YES];
    
    AVPlayerItem* item = [AVPlayerItem playerItemWithURL:url];
    AVPlayer* player = [AVPlayer playerWithPlayerItem:item];
    self.currentPlayer = player;
    self.currentPlayerItem = item;
    [player play];
}

- (void)stopUrl:(NSURL *)url {
    if (!self.currentUrl || [self.currentUrl isEqual:url]) {
        [self.currentPlayer pause];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == PlayerStatusObserverContext) {
        AVPlayer* player = object;
        if ([keyPath isEqualToString:@"status"]) {
            if (player.status == AVPlayerStatusFailed) {
                [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Player error\n%@", player.error]];
            }
        }
        else if ([keyPath isEqualToString:@"currentItem"]) {
            self.currentPlayerItem = player.currentItem;
            NSURL* url = self.currentUrl;
            [NSNotificationCenter.defaultCenter postNotificationName:MediaCenterWillStartPlayingNotification object:self userInfo:url ? @{@"url":url} : @{}];
        }
        return;
    }
    
    if (context == PlayerItemStatusObserverContext) {
        AVPlayerItem* item = object;
        if (item.status == AVPlayerItemStatusFailed) {
            [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Player error\n%@", item.error]];
        }
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
