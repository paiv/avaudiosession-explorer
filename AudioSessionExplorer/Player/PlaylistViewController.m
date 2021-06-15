#import <AVKit/AVKit.h>
#import "AppAudioSession.h"
#import "MediaCenter.h"
#import "Playlist.h"
#import "PlaylistViewController.h"


@interface PlaylistViewController ()

@property (weak, nonatomic) IBOutlet AVRoutePickerView* routePickerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* routePickerButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* startRecordingButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* stopRecordingButtonItem;
@property (strong, nonatomic) id<NSObject> interruptionObserver;
@property (strong, nonatomic) id<NSObject> recorderObserver;


@end


@implementation PlaylistViewController

- (void)dealloc {
    self.interruptionObserver = nil;
    self.recorderObserver = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray* items = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
        [[UIBarButtonItem alloc] initWithTitle:@"Interrupted" style:(UIBarButtonItemStylePlain) target:nil action:nil],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:nil action:nil],
    ];
    [self setToolbarItems:items animated:NO];

    __weak typeof(self) weakSelf = self;
    self.interruptionObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification* notification) {
        [weakSelf handleInterruption:notification];
    }];

    self.recorderObserver = [NSNotificationCenter.defaultCenter addObserverForName:MediaCenterDidFinishRecordingNotification object:MediaCenter.sharedMediaCenter queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification* notification) {
        [weakSelf mediaCenterDidFinishRecordingWithNotification:notification];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadRecorderButton];
}

- (void)reloadRecorderButton {
    BOOL isRecording = MediaCenter.sharedMediaCenter.isRecording;
    NSArray* items = @[
        isRecording ? self.stopRecordingButtonItem : self.startRecordingButtonItem,
        self.routePickerButtonItem];
    self.navigationItem.rightBarButtonItems = items;
}

- (void)setInterruptionObserver:(id<NSObject>)observer {
    if (_interruptionObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:_interruptionObserver];
    }
    _interruptionObserver = observer;
}

- (void)setRecorderObserver:(id<NSObject>)observer {
    if (_recorderObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:_recorderObserver];
    }
    _recorderObserver = observer;
}

- (NSArray<NSURL*>*)playlist {
    return Playlist.sharedPlaylist.items;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playlist.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL* itemUrl = self.playlist[indexPath.row];
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"itemcell" forIndexPath:indexPath];
    
    cell.textLabel.text = itemUrl.lastPathComponent;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL* itemUrl = self.playlist[indexPath.row];
    [MediaCenter.sharedMediaCenter playUrl:itemUrl];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL* itemUrl = self.playlist[indexPath.row];
    [MediaCenter.sharedMediaCenter stopUrl:itemUrl];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView.indexPathsForSelectedRows containsObject:indexPath]) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        NSURL* itemUrl = self.playlist[indexPath.row];
        [MediaCenter.sharedMediaCenter stopUrl:itemUrl];
        return nil;
    }
    return indexPath;
}

- (IBAction)handleStartRecordingButton:(id)sender {
    [MediaCenter.sharedMediaCenter startRecording];
    [self reloadRecorderButton];
}

- (IBAction)handleStopRecordingButton:(id)sender {
    [MediaCenter.sharedMediaCenter stopRecording];
}

- (void)mediaCenterDidFinishRecordingWithNotification:(NSNotification*)notification {
    [self reloadRecorderButton];
    
    NSNumber* success = notification.userInfo[@"success"];
    if (success.boolValue) {
        AVAudioRecorder* recorder = notification.userInfo[@"recorder"];
        [Playlist.sharedPlaylist addUrl:recorder.url];
        [self.tableView reloadData];
    }
}

- (void)handleInterruption:(NSNotification*)notification {
    BOOL isBeingInterrupted = AppAudioSession.sharedSession.isBeingInterrupted;
    [self.navigationController setToolbarHidden:!isBeingInterrupted animated:YES];
}

@end
