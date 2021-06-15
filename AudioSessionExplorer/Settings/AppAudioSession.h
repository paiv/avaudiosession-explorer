#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "SettingsModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AppAudioSessionDelegate;


@interface AppAudioSession : NSObject

+ (instancetype)sharedSession;

@property (copy, nonatomic) AVAudioSessionCategory category;
@property (copy, nonatomic) AVAudioSessionMode mode;
@property (assign, nonatomic) AVAudioSessionRouteSharingPolicy policy;
@property (assign, nonatomic) AVAudioSessionCategoryOptions options;
@property (assign, nonatomic) BOOL forceOutputToSpeaker;
@property (assign, nonatomic) BOOL allowBluetooth;
@property (assign, nonatomic) BOOL allowBluetoothA2DP;
@property (assign, nonatomic) BOOL allowAirPlay;
@property (assign, nonatomic) BOOL defaultToSpeaker;
@property (assign, nonatomic) BOOL duckOthers;
@property (assign, nonatomic) BOOL mixWithOthers;
@property (assign, nonatomic) BOOL interruptSpokenAudio;
@property (assign, nonatomic) BOOL overrideMutedMic;
@property (strong, nonatomic, readonly, nullable) NSError* lastError;

@property (strong, nonatomic, readonly) AVAudioSessionRouteDescription* currentRoute;
@property (strong, nonatomic, readonly) NSArray<AVAudioSessionCategory>* availableCategories;
@property (strong, nonatomic, readonly) NSArray<AVAudioSessionMode>* availableModes;
@property (strong, nonatomic, readonly) NSArray<NSNumber*>* availableRouteSharingPolicies;
@property (strong, nonatomic, readonly) NSArray<AVAudioSessionPortDescription*>* availableInputs;
- (NSString*)currentRouteDescription;
- (NSString*)availableRoutesDescription;

- (void)setActive:(BOOL)active;

@property (weak, nonatomic) id<AppAudioSessionDelegate> delegate;

- (SettingsModel*)settingsModel;
- (void)loadFromSettingsModel:(SettingsModel*)settingsModel;

@end


@protocol AppAudioSessionDelegate <NSObject>

- (void)audioSession:(AppAudioSession*)audioSession didChangeConfiguration:(id)sender;

@end


extern NSString* NSStringFromAVAudioSessionCategory(AVAudioSessionCategory category);
extern NSString* NSStringFromAVAudioSessionMode(AVAudioSessionMode mode);
extern NSString* NSStringFromAVAudioSessionRouteSharingPolicy(AVAudioSessionRouteSharingPolicy policy);
extern NSString* NSStringFromAVAudioSessionCategoryOptions(AVAudioSessionCategoryOptions options);


NS_ASSUME_NONNULL_END
