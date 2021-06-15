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
    
    for (AVAudioSessionCategory category in AppAudioSession.sharedSession.availableCategories) {
        NSString* title = NSStringFromAVAudioSessionCategory(category);
        UIAlertAction* action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [AppAudioSession.sharedSession setCategory:category];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)handleModeButton:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    
    for (AVAudioSessionMode mode in AppAudioSession.sharedSession.availableModes) {
        NSString* title = NSStringFromAVAudioSessionMode(mode);
        UIAlertAction* action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [AppAudioSession.sharedSession setMode:mode];
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
        NSString* title = NSStringFromAVAudioSessionRouteSharingPolicy(policy.unsignedIntegerValue);
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
    [self.categoryButton setTitle:NSStringFromAVAudioSessionCategory(session.category) forState:(UIControlStateNormal)];
    [self.modeButton setTitle:NSStringFromAVAudioSessionMode(session.mode) forState:(UIControlStateNormal)];
    [self.policyButton setTitle:NSStringFromAVAudioSessionRouteSharingPolicy(session.policy) forState:(UIControlStateNormal)];
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
    
    [so appendString:[session currentRouteDescription]];
    [so appendString:@"\n"];
    [so appendString:[session availableRoutesDescription]];

    self.statusTextView.text = so;
}

@end
