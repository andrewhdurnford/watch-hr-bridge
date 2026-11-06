#import "WatchBroadcaster.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <objc/message.h>

// CBPeripheralManager / CBMutable* calls go through objc_msgSend.

@implementation WatchBroadcaster {
    id _mgr;
    id _service;
    id _hrChar;
    NSInteger _subs;
}

- (NSInteger)subscriberCount { return _subs; }

/// Log only.
- (void)info:(NSString *)s { NSLog(@"[WatchBroadcaster] %@", s); }

/// Log and surface to the UI (problems; pass @"" to clear).
- (void)report:(NSString *)s {
    NSLog(@"[WatchBroadcaster] %@", s);
    void (^cb)(NSString *) = self.onStatus;
    if (cb) dispatch_async(dispatch_get_main_queue(), ^{ cb(s); });
}

- (void)reportReceivers {
    void (^cb)(NSInteger) = self.onReceivers;
    NSInteger n = _subs;
    if (cb) dispatch_async(dispatch_get_main_queue(), ^{ cb(n); });
}

- (void)start {
    if (_mgr) {
        [self advertiseIfReady];
        return;
    }
    Class cls = NSClassFromString(@"CBPeripheralManager");
    if (!cls) { [self report:@"Bluetooth unavailable"]; return; }
    id raw = ((id (*)(id, SEL))objc_msgSend)(cls, NSSelectorFromString(@"alloc"));
    _mgr = ((id (*)(id, SEL, id, id))objc_msgSend)(raw, NSSelectorFromString(@"initWithDelegate:queue:"), self, nil);
    if (_mgr) [self info:@"manager created"]; else [self report:@"Bluetooth failed"];
}

/// CoreBluetooth has no "disconnect this central" call for a peripheral, and stopAdvertising
/// leaves existing connections open (receivers then sit "connected" until they time out).
/// Tearing the whole manager down drops the GATT server and with it the connections.
- (void)stop {
    if (!_mgr) return;
    id mgr = _mgr;
    ((void (*)(id, SEL, id))objc_msgSend)(mgr, NSSelectorFromString(@"setDelegate:"), nil);
    ((void (*)(id, SEL))objc_msgSend)(mgr, NSSelectorFromString(@"stopAdvertising"));
    ((void (*)(id, SEL))objc_msgSend)(mgr, NSSelectorFromString(@"removeAllServices"));
    _mgr = nil;
    _service = nil;
    _hrChar = nil;
    _subs = 0;
    [self reportReceivers];
    [self info:@"stopped"];
}

- (NSInteger)managerState {
    return ((NSInteger (*)(id, SEL))objc_msgSend)(_mgr, NSSelectorFromString(@"state"));
}

- (void)buildServiceIfNeeded {
    if (_service) return;
    Class svcCls = NSClassFromString(@"CBMutableService");
    Class chrCls = NSClassFromString(@"CBMutableCharacteristic");
    if (!svcCls || !chrCls) { [self report:@"Bluetooth unavailable"]; return; }

    SEL chrInit = NSSelectorFromString(@"initWithType:properties:value:permissions:");

    // 0x2A37 Heart Rate Measurement: notify (0x10), no static value, readable permission.
    id hrAlloc = ((id (*)(id, SEL))objc_msgSend)(chrCls, NSSelectorFromString(@"alloc"));
    _hrChar = ((id (*)(id, SEL, id, NSUInteger, id, NSUInteger))objc_msgSend)(
        hrAlloc, chrInit, [CBUUID UUIDWithString:@"2A37"], (NSUInteger)0x10, nil, (NSUInteger)0x01);

    // 0x2A38 Body Sensor Location: read (0x02), static value 2 = wrist.
    uint8_t wrist = 2;
    id locAlloc = ((id (*)(id, SEL))objc_msgSend)(chrCls, NSSelectorFromString(@"alloc"));
    id locChar = ((id (*)(id, SEL, id, NSUInteger, id, NSUInteger))objc_msgSend)(
        locAlloc, chrInit, [CBUUID UUIDWithString:@"2A38"], (NSUInteger)0x02,
        [NSData dataWithBytes:&wrist length:1], (NSUInteger)0x01);

    id svcAlloc = ((id (*)(id, SEL))objc_msgSend)(svcCls, NSSelectorFromString(@"alloc"));
    _service = ((id (*)(id, SEL, id, BOOL))objc_msgSend)(
        svcAlloc, NSSelectorFromString(@"initWithType:primary:"), [CBUUID UUIDWithString:@"180D"], YES);

    ((void (*)(id, SEL, id))objc_msgSend)(_service, NSSelectorFromString(@"setCharacteristics:"), @[_hrChar, locChar]);
    ((void (*)(id, SEL, id))objc_msgSend)(_mgr, NSSelectorFromString(@"addService:"), _service);
    [self info:@"service requested"];
}

- (void)advertiseIfReady {
    if (!_mgr || [self managerState] != 5 /* poweredOn */) return;
    if (!_service) { [self buildServiceIfNeeded]; return; }
    NSDictionary *ad = @{
        @"kCBAdvDataServiceUUIDs": @[[CBUUID UUIDWithString:@"180D"]],
        @"kCBAdvDataLocalName": @"Watch HR",
    };
    ((void (*)(id, SEL, id))objc_msgSend)(_mgr, NSSelectorFromString(@"startAdvertising:"), ad);
}

- (void)sendBPM:(NSInteger)bpm {
    if (!_mgr || !_hrChar || bpm <= 0) return;
    uint8_t buf[3];
    NSUInteger len;
    if (bpm > 255) { buf[0] = 0x01; buf[1] = bpm & 0xFF; buf[2] = (bpm >> 8) & 0xFF; len = 3; }
    else           { buf[0] = 0x00; buf[1] = (uint8_t)bpm; len = 2; }
    NSData *d = [NSData dataWithBytes:buf length:len];
    ((BOOL (*)(id, SEL, id, id, id))objc_msgSend)(
        _mgr, NSSelectorFromString(@"updateValue:forCharacteristic:onSubscribedCentrals:"), d, _hrChar, nil);
}

#pragma mark - CBPeripheralManagerDelegate (informal; CoreBluetooth checks respondsToSelector)

- (void)peripheralManagerDidUpdateState:(id)peripheral {
    NSInteger st = [self managerState];
    [self info:[NSString stringWithFormat:@"state %ld", (long)st]];
    switch (st) {
        case 5: [self report:@""]; [self buildServiceIfNeeded]; break;
        case 4: [self report:@"Bluetooth is off"]; break;
        case 3: [self report:@"Bluetooth not allowed"]; break;
        case 2: [self report:@"Bluetooth unsupported"]; break;
        default: break; // unknown / resetting: transient
    }
}

- (void)peripheralManager:(id)peripheral didAddService:(id)service error:(NSError *)error {
    if (error) { [self report:[NSString stringWithFormat:@"Bluetooth: %@", error.localizedDescription]]; return; }
    [self advertiseIfReady];
}

- (void)peripheralManagerDidStartAdvertising:(id)peripheral error:(NSError *)error {
    if (error) { [self report:[NSString stringWithFormat:@"Bluetooth: %@", error.localizedDescription]]; return; }
    [self info:@"advertising"];
}

- (void)peripheralManager:(id)peripheral central:(id)central didSubscribeToCharacteristic:(id)characteristic {
    _subs++;
    [self reportReceivers];
}

- (void)peripheralManager:(id)peripheral central:(id)central didUnsubscribeFromCharacteristic:(id)characteristic {
    if (_subs > 0) _subs--;
    [self reportReceivers];
}

@end
