#import "SettingsStorage.h"


@interface SettingsStorage ()

@property (strong, nonatomic) NSArray<SettingsModel*>* entries;

@end


@implementation SettingsModel (SettingsStorage)

- (instancetype)initWithDictionary:(NSDictionary*)value {
    self = [super init];
    if (self) {
        self.category = value[@"category"];
        self.mode = value[@"mode"];
        self.policy = [value[@"policy"] unsignedIntegerValue];
        self.options = [value[@"options"] unsignedIntegerValue];
        self.forceOutputToSpeaker = [value[@"speaker"] boolValue];
    }
    return self;
}

- (NSDictionary*)dictionary {
    return @{
        @"category": self.category,
        @"mode": self.mode,
        @"policy": @(self.policy),
        @"options": @(self.options),
        @"speaker": @(self.forceOutputToSpeaker),
    };
}

@end


@implementation SettingsStorage

static NSString* SettingsStorageKey = @"AudioSessionExplorerSettingsStorage";

+ (instancetype)sharedStorage {
    static dispatch_once_t onceToken;
    static SettingsStorage* instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[SettingsStorage alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reloadDataFromStorage];
    }
    return self;
}

- (NSUserDefaults*)backend {
    return NSUserDefaults.standardUserDefaults;
}

- (void)reloadDataFromStorage {
    NSArray* stored = [self.backend arrayForKey:SettingsStorageKey];
    NSMutableArray* entries = [NSMutableArray arrayWithCapacity:stored.count];
    for (id entry in stored) {
        if ([entry isKindOfClass:NSDictionary.class]) {
            SettingsModel* model = [[SettingsModel alloc] initWithDictionary:entry];
            if (model) {
                [entries addObject:model];
            }
        }
    }
    self.entries = [NSArray arrayWithArray:entries];
}

- (void)persistDataToStorage {
    NSArray* entries = [self.entries valueForKey:@"dictionary"];
    [self.backend setValue:entries forKey:SettingsStorageKey];
}

- (NSArray<SettingsModel *> *)savedStates {
    return self.entries;
}

- (void)saveState:(SettingsModel *)model {
    self.entries = [self.entries arrayByAddingObject:model];
    [self persistDataToStorage];
}

- (void)removeLastSavedState {
    NSUInteger n = self.entries.count;
    if (n > 0) {
        self.entries = [self.entries subarrayWithRange:NSMakeRange(0, n - 1)];
        [self persistDataToStorage];
    }
}

@end
