#import <AVKit/AVKit.h>
#import "AppAudioSession.h"
#import "SettingsViewController.h"


@interface SettingsViewController () <AppAudioSessionDelegate>

@property (weak, nonatomic) IBOutlet AVRoutePickerView* routePickerView;
@property (weak, nonatomic) IBOutlet UIButton* categoryButton;
@property (weak, nonatomic) IBOutlet UIButton* modeButton;
@property (weak, nonatomic) IBOutlet UIButton* policyButton;
@property (weak, nonatomic) IBOutlet UISwitch* forceOutputToSpeakerSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* allowBluetoothSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* allowBluetoothA2DPSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* allowAirPlaySwitch;
@property (weak, nonatomic) IBOutlet UISwitch* defaultToSpeakerSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* duckOthersSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* mixWithOthersSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* interruptSpokenAudioSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* overrideMutedMicSwitch;
@property (weak, nonatomic) IBOutlet UITextView* statusTextView;
@property (weak, nonatomic) IBOutlet UIToolbar* stateToolbar;
@property (strong, nonatomic) NSMutableDictionary<NSNumber*, SettingsModel*>* savedStates;

@end


static NSString*
NSStringFromAVAudioSessionRouteSharingPolicy(AVAudioSessionRouteSharingPolicy policy) {
    switch (policy) {
        case AVAudioSessionRouteSharingPolicyDefault:
            return @"AVAudioSessionRouteSharingPolicyDefault";
        case AVAudioSessionRouteSharingPolicyLongFormAudio:
            return @"AVAudioSessionRouteSharingPolicyLongFormAudio";
        case AVAudioSessionRouteSharingPolicyIndependent:
            return @"AVAudioSessionRouteSharingPolicyIndependent";
        case AVAudioSessionRouteSharingPolicyLongFormVideo:
            return @"AVAudioSessionRouteSharingPolicyLongFormVideo";
    }
    return nil;
}


@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.savedStates = [NSMutableDictionary dictionary];
    AppAudioSession.sharedSession.delegate = self;
    [self loadSessionState];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadSessionState];
}

- (IBAction)handleCategoryButton:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    
    for (NSString* name in AppAudioSession.sharedSession.availableCategories) {
        NSString* title = [name substringFromIndex:@"AVAudioSessionCategory".length];
        UIAlertAction* action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [AppAudioSession.sharedSession setCategory:name];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)handleModeButton:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    
    for (NSString* name in AppAudioSession.sharedSession.availableModes) {
        NSString* title = [name substringFromIndex:@"AVAudioSessionMode".length];
        UIAlertAction* action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [AppAudioSession.sharedSession setMode:name];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)handlePolicyButton:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    
    for (NSNumber* policy in AppAudioSession.sharedSession.availableRouteSharingPolicies) {
        NSString* name = NSStringFromAVAudioSessionRouteSharingPolicy(policy.unsignedIntegerValue);
        NSString* title = [name substringFromIndex:@"AVAudioSessionRouteSharingPolicy".length];
        UIAlertAction* action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [AppAudioSession.sharedSession setPolicy:policy.unsignedIntegerValue];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)handleForceOutputToSpeakerSwitch:(id)sender {
    [AppAudioSession.sharedSession setForceOutputToSpeaker:self.forceOutputToSpeakerSwitch.isOn];
}

- (IBAction)handleAllowBluetoothSwitch:(id)sender {
    [AppAudioSession.sharedSession setAllowBluetooth:self.allowBluetoothSwitch.isOn];
}

- (IBAction)handleAllowBluetoothA2DPSwitch:(id)sender {
    [AppAudioSession.sharedSession setAllowBluetoothA2DP:self.allowBluetoothA2DPSwitch.isOn];
}

- (IBAction)handleAllowAirPlaySwitch:(id)sender {
    [AppAudioSession.sharedSession setAllowAirPlay:self.allowAirPlaySwitch.isOn];
}

- (IBAction)handleDefaultToSpeakerSwitch:(id)sender {
    [AppAudioSession.sharedSession setDefaultToSpeaker:self.defaultToSpeakerSwitch.isOn];
}

- (IBAction)handleDuckOthersSwitch:(id)sender {
    [AppAudioSession.sharedSession setDuckOthers:self.duckOthersSwitch.isOn];
}

- (IBAction)handleMixWithOthersSwitch:(id)sender {
    [AppAudioSession.sharedSession setMixWithOthers:self.mixWithOthersSwitch.isOn];
}

- (IBAction)handleInterruptSpokenAudioSwitch:(id)sender {
    [AppAudioSession.sharedSession setInterruptSpokenAudio:self.interruptSpokenAudioSwitch.isOn];
}

- (IBAction)handleOverrideMutedMicSwitch:(id)sender {
    [AppAudioSession.sharedSession setOverrideMutedMic:self.overrideMutedMicSwitch.isOn];
}

- (IBAction)handleSaveStateButton:(id)sender {
    NSInteger buttonId = self.stateToolbar.items.count;

    SettingsModel* settingsModel = AppAudioSession.sharedSession.settingsModel;
    self.savedStates[@(buttonId)] = settingsModel;

    NSString* title = [NSString stringWithFormat:@"#%d", (int)buttonId];
    UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithTitle:title style:(UIBarButtonItemStylePlain) target:self action:@selector(handleLoadStateButton:)];
    button.tag = buttonId;
    
    [self.stateToolbar setItems:[self.stateToolbar.items arrayByAddingObject:button] animated:YES];
}

- (IBAction)handleLoadStateButton:(UIBarButtonItem*)sender {
    if (sender.tag) {
        SettingsModel* model = self.savedStates[@(sender.tag)];
        [AppAudioSession.sharedSession loadFromSettingsModel:model];
    }
}

- (void)audioSession:(AppAudioSession *)audioSession didChangeConfiguration:(id)sender {
    [self loadSessionState];
}

- (void)loadSessionState {
    AppAudioSession* session = AppAudioSession.sharedSession;
    [self.categoryButton setTitle:[session.category substringFromIndex:@"AVAudioSessionCategory".length] forState:(UIControlStateNormal)];
    [self.modeButton setTitle:[session.mode substringFromIndex:@"AVAudioSessionMode".length] forState:(UIControlStateNormal)];
    [self.policyButton setTitle:[NSStringFromAVAudioSessionRouteSharingPolicy(session.policy) substringFromIndex:@"AVAudioSessionRouteSharingPolicy".length] forState:(UIControlStateNormal)];
    self.forceOutputToSpeakerSwitch.on = session.forceOutputToSpeaker;
    self.allowBluetoothSwitch.on = session.allowBluetooth;
    self.allowBluetoothA2DPSwitch.on = session.allowBluetoothA2DP;
    self.allowAirPlaySwitch.on = session.allowAirPlay;
    self.defaultToSpeakerSwitch.on = session.defaultToSpeaker;
    self.duckOthersSwitch.on = session.duckOthers;
    self.mixWithOthersSwitch.on = session.mixWithOthers;
    self.interruptSpokenAudioSwitch.on = session.interruptSpokenAudio;
    self.overrideMutedMicSwitch.on = session.overrideMutedMic;
    
    NSMutableString* so = [NSMutableString string];
    
    if (session.lastError) {
        [so appendFormat:@"%@\n\n", session.lastError.localizedDescription];
    }
    
    void(^formatPortDescription)(AVAudioSessionPortDescription*) = ^(AVAudioSessionPortDescription* port) {
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
    };
    
    [so appendString:@"Current route:\n"];
    AVAudioSessionRouteDescription* currentRoute = session.currentRoute;
    for (AVAudioSessionPortDescription* port in currentRoute.inputs) {
        [so appendString:@"in "];
        formatPortDescription(port);
    }
    for (AVAudioSessionPortDescription* port in currentRoute.outputs) {
        [so appendString:@"out "];
        formatPortDescription(port);
    }
    
    [so appendString:@"\nAvailable inputs:\n"];
    for (AVAudioSessionPortDescription* port in session.availableInputs) {
        [so appendString:@"in "];
        formatPortDescription(port);
    }

    self.statusTextView.text = so;
}

@end
