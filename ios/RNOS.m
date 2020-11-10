//
//  RNOS.m
//  RNOS
//
//  Created by Andy Prock on 11/3/16.
//  Copyright © 2016 Peel. All rights reserved.
//

#import "RNOS.h"

#import "RCTAssert.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <net/if_dl.h>


@implementation RNOS {
    SCNetworkReachabilityRef _reachability;
}

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

static void RCTReachabilityCallback(__unused SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    RNOS *self = (__bridge id)info;

    // update the info on network changes
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"rn-os-info"
                                                    body:@{ @"networkInterfaces": [self networkInterfaces] }];
}

- (instancetype)init
{
    if ((self = [super init])) {
        [self startObserving];
    }

    return self;
}

- (void)startObserving
{
    _reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "apple.com");
    SCNetworkReachabilityContext context = { 0, ( __bridge void *)self, NULL, NULL, NULL };
    SCNetworkReachabilitySetCallback(_reachability, RCTReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

- (void)stopObserving
{
    if (_reachability) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        CFRelease(_reachability);
    }
}

- (void)invalidate
{
    [self stopObserving];
}

- (NSString *)getPathForDirectory:(int)directory
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
  return [paths firstObject];
}

- (NSDictionary *)constantsToExport
{
    // initialize os info dict
    return @{
        @"networkInterfaces": [self networkInterfaces],
        @"homedir": [self getPathForDirectory:NSDocumentDirectory]
    };
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

- (NSDictionary*)networkInterfaces {
    NSMutableDictionary* ifaces = [NSMutableDictionary new];
    struct ifaddrs *addrs, *ent;

    if (getifaddrs(&addrs)) {
        return @{};
    }

    for (ent = addrs; ent != NULL; ent = ent->ifa_next) {
        if (!((ent->ifa_flags & IFF_UP) && (ent->ifa_flags & IFF_RUNNING)))
            continue;

        if (ent->ifa_addr == NULL)
            continue;

        /*
         * On Mac OS X getifaddrs returns information related to Mac Addresses for
         * various devices, such as firewire, etc. These are not relevant here.
         */
        if (ent->ifa_addr->sa_family == AF_LINK)
            continue;

        NSMutableDictionary* address = [NSMutableDictionary new];
        NSString *name = [NSString stringWithUTF8String:ent->ifa_name];

        const struct sockaddr_in *addr = (const struct sockaddr_in*)ent->ifa_addr;
        char addrBuf[MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN)];

        if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
            if(addr->sin_family == AF_INET) {
                inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN);
                [address setObject: [NSString stringWithUTF8String: addrBuf] forKey: @"address"];
                [address setObject: @"IPv4" forKey: @"family"];
            } else {
                const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)ent->ifa_addr;
                inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN);
                [address setObject: [NSString stringWithUTF8String: addrBuf] forKey: @"address"];
                [address setObject: @"IPv6" forKey: @"family"];
            }
        }

        char netmaskBuf[MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN)];
        const struct sockaddr_in *mask = (const struct sockaddr_in*)ent->ifa_netmask;
        if(mask && (mask->sin_family==AF_INET || mask->sin_family==AF_INET6)) {
            if(mask->sin_family == AF_INET) {
                inet_ntop(AF_INET, &mask->sin_addr, netmaskBuf, INET_ADDRSTRLEN);
                [address setObject: [NSString stringWithUTF8String: netmaskBuf] forKey: @"netmask"];
            } else {
                const struct sockaddr_in6 *mask6 = (const struct sockaddr_in6*)ent->ifa_netmask;
                inet_ntop(AF_INET6, &mask6->sin6_addr, netmaskBuf, INET6_ADDRSTRLEN);
                [address setObject: [NSString stringWithUTF8String: netmaskBuf] forKey: @"netmask"];
            }
        }

        [address setValue: [NSNumber numberWithBool:!!(ent->ifa_flags & IFF_LOOPBACK)] forKey: @"internal"];

        if (((ent->ifa_flags & IFF_UP) || (ent->ifa_flags & IFF_RUNNING)) &&
            !(ent->ifa_addr == NULL) &&
            !(ent->ifa_addr->sa_family != AF_LINK)) {

            NSMutableString *macString = [NSMutableString string];

            struct sockaddr_dl* dlAddr = (struct sockaddr_dl*)(ent->ifa_addr);
            const unsigned char* base = (const unsigned char *) &dlAddr->sdl_data[dlAddr->sdl_nlen];
            for(NSInteger i = 0; i < dlAddr->sdl_alen; i++) {
                [macString appendFormat:@"%02x", base[i]];
            }

            if ([macString length] > 0) {
                [address setObject: macString forKey: @"mac"];
            }
        }

        // update array
        NSMutableArray* ifacesArray = [ifaces objectForKey: name];
        if (ifacesArray) {
            [ifacesArray addObject: address];
        } else {
            ifacesArray = [NSMutableArray arrayWithObject:address];
        }
        [ifaces setObject: ifacesArray forKey: name];
    }

    freeifaddrs(addrs);

    return ifaces;
}

@end
