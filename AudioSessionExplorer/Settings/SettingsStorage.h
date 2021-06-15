#import <Foundation/Foundation.h>
#import "SettingsModel.h"

NS_ASSUME_NONNULL_BEGIN


@interface SettingsStorage : NSObject

+ (instancetype)sharedStorage;

- (NSArray<SettingsModel*>*)savedStates;
- (void)saveState:(SettingsModel*)model;
- (void)removeLastSavedState;

@end


NS_ASSUME_NONNULL_END
