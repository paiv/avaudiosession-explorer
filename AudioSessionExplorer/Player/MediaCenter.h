#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface MediaCenter : NSObject

+ (instancetype)sharedMediaCenter;

- (void)playFromPlaylist:(NSArray<NSURL*>*)playlist atIndex:(NSUInteger)index;
- (void)playUrl:(NSURL*)url;
- (void)stopUrl:(NSURL*)url;
- (void)startRecording;
- (void)stopRecording;

@property (assign, nonatomic, readonly, nullable) NSURL* currentUrl;
@property (assign, nonatomic, readonly) BOOL isRecording;

extern NSNotificationName const MediaCenterWillStartPlayingNotification;
extern NSNotificationName const MediaCenterDidFinishRecordingNotification;
                                                                                                             
@end


NS_ASSUME_NONNULL_END
