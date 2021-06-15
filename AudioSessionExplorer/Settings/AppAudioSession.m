#import "AppAudioSession.h"
#import "EventLog.h"


@interface AppAudioSession ()

@property (strong, nonatomic, nullable) NSError* lastError;
@property (assign, nonatomic) BOOL isBeingInterrupted;
@property (strong, nonatomic) id<NSObject> interruptionObserver;
@property (strong, nonatomic) id<NSObject> routeChangeObserver;
@property (strong, nonatomic) NSTimer* notificationDelayTimer;

@end


@implementation AppAudioSession

+ (instancetype)sharedSession {
    static dispatch_once_t onceToken;
    static AppAudioSession* obj = nil;
    dispatch_once(&onceToken, ^{
        obj = [[AppAudioSession alloc] init];
    });
    return obj;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self) weakSelf = self;
        
        self.interruptionObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification* notification) {
            [weakSelf handleInterruption:notification];
        }];
        
        self.routeChangeObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull notification) {
            [weakSelf handleRouteChange:notification];
        }];
    }
    return self;
}

- (void)dealloc {
    self.routeChangeObserver = nil;
}

- (void)setInterruptionObserver:(id<NSObject>)interruptionObserver {
    if (_interruptionObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:_interruptionObserver];
    }
    _interruptionObserver = interruptionObserver;
}

- (void)setRouteChangeObserver:(id<NSObject>)routeChangeObserver {
    if (_routeChangeObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:_routeChangeObserver];
    }
    _routeChangeObserver = routeChangeObserver;
}

- (AVAudioSession*)backend {
    return AVAudioSession.sharedInstance;
}

- (AVAudioSessionCategory)category {
    return self.backend.category;
}
- (void)setCategory:(AVAudioSessionCategory)category {
    [self setBackendCategory:category mode:self.mode policy:self.policy options:self.options];
}

- (AVAudioSessionMode)mode {
    return self.backend.mode;
}
- (void)setMode:(AVAudioSessionMode)mode {
    [self setBackendCategory:self.category mode:mode policy:self.policy options:self.options];
}

- (AVAudioSessionRouteSharingPolicy)policy {
    return self.backend.routeSharingPolicy;
}
- (void)setPolicy:(AVAudioSessionRouteSharingPolicy)policy {
    [self setBackendCategory:self.category mode:self.mode policy:policy options:self.options];
}

- (AVAudioSessionCategoryOptions)options {
    return self.backend.categoryOptions;
}
- (void)setOptions:(AVAudioSessionCategoryOptions)options {
    [self setBackendCategory:self.category mode:self.mode policy:self.policy options:options];
}

- (void)setForceOutputToSpeaker:(BOOL)speaker {
    NSError* error = nil;
    AVAudioSessionPortOverride portOverride = speaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
    [self.backend overrideOutputAudioPort:portOverride error:&error];
    self.lastError = error;
    _forceOutputToSpeaker = error ? NO : speaker;
}

- (BOOL)allowBluetooth {
    return (self.options & AVAudioSessionCategoryOptionAllowBluetooth) != 0;
}
- (void)setAllowBluetooth:(BOOL)enable {
    [self enableOption:AVAudioSessionCategoryOptionAllowBluetooth enable:enable];
}

- (BOOL)allowBluetoothA2DP {
    return (self.options & AVAudioSessionCategoryOptionAllowBluetoothA2DP) != 0;
}
- (void)setAllowBluetoothA2DP:(BOOL)enable {
    [self enableOption:AVAudioSessionCategoryOptionAllowBluetoothA2DP enable:enable];
}

- (BOOL)allowAirPlay {
    return (self.options & AVAudioSessionCategoryOptionAllowAirPlay) != 0;
}
- (void)setAllowAirPlay:(BOOL)enable {
    [self enableOption:AVAudioSessionCategoryOptionAllowAirPlay enable:enable];
}

- (BOOL)defaultToSpeaker {
    return (self.options & AVAudioSessionCategoryOptionDefaultToSpeaker) != 0;
}
- (void)setDefaultToSpeaker:(BOOL)enable {
    [self enableOption:AVAudioSessionCategoryOptionDefaultToSpeaker enable:enable];
}

- (BOOL)duckOthers {
    return (self.options & AVAudioSessionCategoryOptionDuckOthers) != 0;
}
- (void)setDuckOthers:(BOOL)enable {
    [self enableOption:AVAudioSessionCategoryOptionDuckOthers enable:enable];
}

- (BOOL)mixWithOthers {
    return (self.options & AVAudioSessionCategoryOptionMixWithOthers) != 0;
}
- (void)setMixWithOthers:(BOOL)enable {
    [self enableOption:AVAudioSessionCategoryOptionMixWithOthers enable:enable];
}

- (BOOL)interruptSpokenAudio {
    return (self.options & AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers) != 0;
}
- (void)setInterruptSpokenAudio:(BOOL)enable {
    [self enableOption:AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers enable:enable];
}

- (BOOL)overrideMutedMic {
    if (@available(iOS 14.5, *)) {
        return (self.options & AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption) != 0;
    }
    return NO;
}
- (void)setOverrideMutedMic:(BOOL)enable {
    if (@available(iOS 14.5, *)) {
        [self enableOption:AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption enable:enable];
    }
}

- (void)enableOption:(AVAudioSessionCategoryOptions)option enable:(BOOL)enable {
    AVAudioSessionCategoryOptions options = self.options;
    if (enable) {
        options |= option;
    }
    else {
        options &= ~option;
    }
    [self setOptions:options];
}

- (void)setBackendCategory:(AVAudioSessionCategory)category mode:(AVAudioSessionMode)mode policy:(AVAudioSessionRouteSharingPolicy)policy options:(AVAudioSessionCategoryOptions)options {
    [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Set category\n%@, mode %@, sharing policy %@, options %@", NSStringFromAVAudioSessionCategory(category), NSStringFromAVAudioSessionMode(mode), NSStringFromAVAudioSessionRouteSharingPolicy(policy), NSStringFromAVAudioSessionCategoryOptions(options)]];
    @try {
        NSError* error = nil;
        [self.backend setCategory:category mode:mode routeSharingPolicy:policy options:options error:&error];
        self.lastError = error;
        if (self.forceOutputToSpeaker) {
            [self setForceOutputToSpeaker:YES];
        }
    }
    @catch(NSException* exception) {
        self.lastError = [NSError errorWithDomain:@"MyAppErrorDomain" code:-1 userInfo:@{NSUnderlyingErrorKey:exception}];
    }
    [self notifyDidChangeConfiguration];
}

- (void)setActive:(BOOL)active {
    [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Set active %d", (int)active]];
    NSError* error = nil;
    [self.backend setActive:active error:&error];
    self.lastError = error;
}

- (void)setLastError:(NSError *)lastError {
    _lastError = lastError;
    if (_lastError) {
        [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Error\n%@", _lastError]];
        [self notifyDidChangeConfiguration];
    }
}

- (void)setNotificationDelayTimer:(NSTimer *)timer {
    [_notificationDelayTimer invalidate];
    _notificationDelayTimer = timer;
}

- (void)notifyDidChangeConfiguration {
    __weak typeof(self) weakSelf = self;
    self.notificationDelayTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 repeats:NO block:^(NSTimer * _Nonnull timer) {
        __strong typeof(self) self = weakSelf;
        [self.delegate audioSession:self didChangeConfiguration:self];
    }];
}

- (void)logRouteChangeEvent {
    NSMutableString* so = [NSMutableString string];
    [so appendString:@"Route changed\n"];
    [so appendString:[self currentRouteDescription]];
    [so appendString:@"\n"];
    [so appendString:[self availableRoutesDescription]];

    [EventLog.sharedEventLog addEntry:so];
}

- (void)handleRouteChange:(NSNotification*)notification {
    [self logRouteChangeEvent];
    [self notifyDidChangeConfiguration];
}

- (void)handleInterruption:(NSNotification*)notification {
    AVAudioSessionInterruptionType interruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan: {
            AVAudioSessionInterruptionReason reason = AVAudioSessionInterruptionReasonDefault;
            if (@available(iOS 14.5, *)) {
                reason = [notification.userInfo[AVAudioSessionInterruptionReasonKey] unsignedIntegerValue];
           
            }
            else {
                BOOL wasSuspended = [notification.userInfo[AVAudioSessionInterruptionWasSuspendedKey] boolValue];
                if (wasSuspended) {
                    reason = AVAudioSessionInterruptionReasonAppWasSuspended;
                }
            }
            [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Interruption began, reason %d", (int)reason]];
            self.isBeingInterrupted = reason != AVAudioSessionInterruptionReasonAppWasSuspended;
            [self.delegate audioSession:self wasInterruptedWithReason:reason];
            break;
        }
            
        case AVAudioSessionInterruptionTypeEnded: {
            AVAudioSessionInterruptionOptions options = [notification.userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
            BOOL shouldResume = (options & AVAudioSessionInterruptionOptionShouldResume) != 0;
            [EventLog.sharedEventLog addEntry:[NSString stringWithFormat:@"Interruption ended, should resume %d", (int)shouldResume]];
            self.isBeingInterrupted = NO;
            [self.delegate audioSession:self didStopBeingInterruptedAndShouldResume:shouldResume];
            break;
        }
    }
}

- (AVAudioSessionRouteDescription*)currentRoute {
    return self.backend.currentRoute;
}

- (NSArray<AVAudioSessionCategory>*)availableCategories {
    return self.backend.availableCategories;
}

- (NSArray<AVAudioSessionMode>*)availableModes {
    return self.backend.availableModes;
}

- (NSArray<NSNumber*>*)availableRouteSharingPolicies {
    NSMutableArray* policies = [NSMutableArray arrayWithArray:@[
        @(AVAudioSessionRouteSharingPolicyDefault),
        @(AVAudioSessionRouteSharingPolicyLongFormAudio),
        @(AVAudioSessionRouteSharingPolicyIndependent),
    ]];
    if (@available(iOS 13.0, *)) {
        [policies addObject:@(AVAudioSessionRouteSharingPolicyLongFormVideo)];
    }
    return policies;
}

- (NSArray<AVAudioSessionPortDescription*>*)availableInputs {
    return self.backend.availableInputs;
}

static void
formatPortDescription(NSMutableString* so, AVAudioSessionPortDescription* port) {
    [so appendFormat:@"%@:%@\n", port.portType, port.portName];
    
    NSMutableArray* sources = [NSMutableArray array];
    [port.dataSources enumerateObjectsUsingBlock:^(AVAudioSessionDataSourceDescription* source, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString* name = source.dataSourceName;
        if ([port.selectedDataSource isEqual:source]) {
            name = [name stringByAppendingString:@" (+)"];
        }
        [sources addObject:name];
    }];
    if (sources.count) {
        [so appendFormat: @"  %@\n", [sources componentsJoinedByString:@", "]];
    }
    else if (port.selectedDataSource) {
        [so appendFormat:@"  %@\n", port.selectedDataSource.dataSourceName];
    }
}

- (NSString *)currentRouteDescription {
    NSMutableString* so = [NSMutableString string];
    
    [so appendString:@"Current route:\n"];
    AVAudioSessionRouteDescription* currentRoute = self.currentRoute;
    for (AVAudioSessionPortDescription* port in currentRoute.inputs) {
        [so appendString:@"in "];
        formatPortDescription(so, port);
    }
    for (AVAudioSessionPortDescription* port in currentRoute.outputs) {
        [so appendString:@"out "];
        formatPortDescription(so, port);
    }
    
    return so;
}

- (NSString *)availableRoutesDescription {
    NSMutableString* so = [NSMutableString string];
    
    [so appendString:@"Available inputs:\n"];
    for (AVAudioSessionPortDescription* port in self.availableInputs) {
        [so appendString:@"in "];
        formatPortDescription(so, port);
    }
    
    return so;
}

- (SettingsModel *)settingsModel {
    SettingsModel* model = [[SettingsModel alloc] init];
    model.category = self.category;
    model.mode = self.mode;
    model.policy = self.policy;
    model.options = self.options;
    model.forceOutputToSpeaker = self.forceOutputToSpeaker;
    return model;
}

- (void)loadFromSettingsModel:(SettingsModel *)model {
    [self setForceOutputToSpeaker:NO];
    [self setBackendCategory:model.category mode:model.mode policy:model.policy options:model.options];
    if (model.forceOutputToSpeaker) {
        [self setForceOutputToSpeaker:YES];
    }
}

@end


NSString*
NSStringFromAVAudioSessionCategory(AVAudioSessionCategory category) {
    return [category substringFromIndex:@"AVAudioSessionCategory".length];
}


NSString*
NSStringFromAVAudioSessionMode(AVAudioSessionMode mode) {
    return [mode substringFromIndex:@"AVAudioSessionMode".length];
}


NSString*
NSStringFromAVAudioSessionRouteSharingPolicy(AVAudioSessionRouteSharingPolicy policy) {
    switch (policy) {
        case AVAudioSessionRouteSharingPolicyDefault:
            return @"Default";
        case AVAudioSessionRouteSharingPolicyLongFormAudio:
            return @"LongFormAudio";
        case AVAudioSessionRouteSharingPolicyIndependent:
            return @"Independent";
        case AVAudioSessionRouteSharingPolicyLongFormVideo:
            return @"LongFormVideo";
    }
    return nil;
}


NSString*
NSStringFromAVAudioSessionCategoryOptions(AVAudioSessionCategoryOptions options) {
    NSMutableArray* res = [NSMutableArray array];
    if ((options & AVAudioSessionCategoryOptionMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers) {
        [res addObject:@"MixWithOthers"];
    }
    if ((options & AVAudioSessionCategoryOptionDuckOthers) == AVAudioSessionCategoryOptionDuckOthers) {
        [res addObject:@"DuckOthers"];
    }
    if ((options & AVAudioSessionCategoryOptionAllowBluetooth) == AVAudioSessionCategoryOptionAllowBluetooth) {
        [res addObject:@"AllowBluetooth"];
    }
    if ((options & AVAudioSessionCategoryOptionDefaultToSpeaker) == AVAudioSessionCategoryOptionDefaultToSpeaker) {
        [res addObject:@"DefaultToSpeaker"];
    }
    if ((options & AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers) == AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers) {
        [res addObject:@"InterruptSpokenAudioAndMixWithOthers"];
    }
    if ((options & AVAudioSessionCategoryOptionAllowBluetoothA2DP) == AVAudioSessionCategoryOptionAllowBluetoothA2DP) {
        [res addObject:@"AllowBluetoothA2DP"];
    }
    if ((options & AVAudioSessionCategoryOptionAllowAirPlay) == AVAudioSessionCategoryOptionAllowAirPlay) {
        [res addObject:@"AllowAirPlay"];
    }
    if (@available(iOS 14.5, *)) {
        if ((options & AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption) == AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption) {
            [res addObject:@"OverrideMutedMicrophoneInterruption"];
        }
    }
    if (res.count) {
        return [res componentsJoinedByString:@"+"];
    }
    return @"()";
}
