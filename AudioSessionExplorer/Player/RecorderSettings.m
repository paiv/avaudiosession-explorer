#import <AVFoundation/AVFoundation.h>
#import "RecorderSettings.h"


@implementation RecorderSettings

+ (NSDictionary *)settingsDictionary {
    return @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: @(2),
        AVSampleRateKey: @(44100),
        AVEncoderAudioQualityKey: @(AVAudioQualityHigh),
        AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable,
    };
}

@end
