#import "EventLog.h"


@interface EventLog ()

@property (strong, nonatomic) NSMutableArray<NSString*>* entries;
@property (strong, nonatomic) NSDateFormatter* dateFormatter;

@end


@implementation EventLog

+ (instancetype)sharedEventLog {
    static dispatch_once_t onceToken;
    static EventLog* instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[EventLog alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.entries = [NSMutableArray array];
        
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm:ss.SSS";
        self.dateFormatter = dateFormatter;
    }
    return self;
}

- (NSArray<NSString *> *)entriesArray {
    return self.entries;
}

- (NSString*)timestampText {
    return [self.dateFormatter stringFromDate:[NSDate date]];
}

- (void)addEntry:(NSString *)entryText {
    NSString* formatted = [NSString stringWithFormat:@"%@ %@", self.timestampText, entryText];
    [self.entries insertObject:formatted atIndex:0];
}

@end
