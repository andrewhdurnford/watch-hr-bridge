#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// EXPERIMENT: advertises a standard BLE Heart Rate service straight from the watch.
/// CBPeripheralManager is marked unavailable for watchOS in the SDK headers, so this
/// reaches it through the Objective-C runtime to find out whether the OS allows it.
@interface WatchBroadcaster : NSObject
/// Called only for problems worth showing (Bluetooth off, not allowed, errors),
/// and with an empty string once the problem has cleared.
@property (nonatomic, copy, nullable) void (^onStatus)(NSString *status);
/// Called whenever the number of connected receivers (Zwift etc.) changes.
@property (nonatomic, copy, nullable) void (^onReceivers)(NSInteger count);
@property (nonatomic, readonly) NSInteger subscriberCount;
- (void)start;
- (void)stop;
- (void)sendBPM:(NSInteger)bpm;
@end

NS_ASSUME_NONNULL_END
