#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface SettingsModel : NSObject

@property (copy, nonatomic) AVAudioSessionCategory category;
@property (copy, nonatomic) AVAudioSessionMode mode;
@property (assign, nonatomic) AVAudioSessionRouteSharingPolicy policy;
@property (assign, nonatomic) AVAudioSessionCategoryOptions options;
@property (assign, nonatomic) BOOL forceOutputToSpeaker;

@end


NS_ASSUME_NONNULL_END
