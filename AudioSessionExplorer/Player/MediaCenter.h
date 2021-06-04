#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface MediaCenter : NSObject

+ (instancetype)sharedMediaCenter;

- (void)playUrl:(NSURL*)url;
- (void)stopUrl:(NSURL*)url;
- (void)startRecording;
- (void)stopRecording;

@property (assign, nonatomic, readonly) BOOL isRecording;

extern NSNotificationName const MediaCenterDidFinishRecordingNotification;
                                                                                                             
@end


NS_ASSUME_NONNULL_END
