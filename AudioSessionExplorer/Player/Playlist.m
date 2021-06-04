#import "Playlist.h"


@interface Playlist ()

@property (strong, nonatomic) NSArray<NSURL*>* items;

@end


@implementation Playlist

+ (instancetype)sharedPlaylist {
    static dispatch_once_t onceToken;
    static Playlist* playlist = nil;
    dispatch_once(&onceToken, ^{
        playlist = [[Playlist alloc] init];
    });
    return playlist;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.items = [NSMutableArray arrayWithArray:[self bundledMediaItems]];
    }
    return self;
}

- (NSArray<NSURL*>*)bundledMediaItems {
    NSArray<NSURL*>* items = [NSBundle.mainBundle URLsForResourcesWithExtension:@"m4a" subdirectory:nil];
    return [items sortedArrayUsingComparator:^NSComparisonResult(NSURL* obj1, NSURL* obj2) {
        return [obj1.absoluteString compare:obj2.absoluteString];
    }];
}

- (void)addUrl:(NSURL *)url {
    self.items = [@[url] arrayByAddingObjectsFromArray:self.items];
}

@end
