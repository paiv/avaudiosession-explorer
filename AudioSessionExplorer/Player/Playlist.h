#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface Playlist : NSObject

+ (instancetype)sharedPlaylist;

@property (strong, nonatomic, readonly) NSArray<NSURL*>* items;

- (void)addUrl:(NSURL*)url;

@end


NS_ASSUME_NONNULL_END
