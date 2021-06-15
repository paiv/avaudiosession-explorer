#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface EventLog : NSObject

+ (instancetype)sharedEventLog;

- (NSArray<NSString*>*)entriesArray;
- (void)addEntry:(NSString*)entryText;

@end


NS_ASSUME_NONNULL_END
