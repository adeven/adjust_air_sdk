//
//  AdjustFunction.m
//  AdjustExtension
//
//  Created by Pedro Filipe on 07/08/14.
//  Copyright (c) 2014 adjust. All rights reserved.
//

#import "AdjustFunction.h"
#import "AdjustFREUtils.h"

FREContext adjustFREContext;

@implementation AdjustFunction

static id<AdjustDelegate> adjustFunctionInstance = nil;

- (id) init {
    self = [super init];
    return self;
}

- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    NSString *attributionString = [NSString stringWithFormat:@"%@=%@,%@=%@,%@=%@,%@=%@,%@=%@,%@=%@,%@=%@",
                                   @"trackerToken", attribution.trackerToken,
                                   @"trackerName", attribution.trackerName,
                                   @"campaign", attribution.campaign,
                                   @"network", attribution.network,
                                   @"creative", attribution.creative,
                                   @"adgroup", attribution.adgroup,
                                   @"clickLabel", attribution.clickLabel];
    const char* cResponseData = [attributionString UTF8String];

    FREDispatchStatusEventAsync(adjustFREContext,
                                (const uint8_t *)"adjust_attributionData",
                                (const uint8_t *)cResponseData);
}

@end

FREObject ADJonCreate(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    if (argc == 8) {
        NSString *appToken;
        NSString *environment;
        NSString *logLevel;
        NSString *defaultTracker;
        NSString *sdkPrefix;

        BOOL eventBufferingEnabled;
        BOOL macMd5TrackingEnabled;
        BOOL isAttributionCallbackSet;

        adjustFREContext = ctx;

        FREGetObjectAsNativeString(argv[0], &appToken);
        FREGetObjectAsNativeString(argv[1], &environment);

        if (appToken != nil && environment != nil) {
            ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken environment:ADJEnvironmentSandbox];

            if (argv[2] != nil) {
                FREGetObjectAsNativeString(argv[2], &logLevel);

                if (logLevel != nil) {
                    [adjustConfig setLogLevel:[ADJLogger LogLevelFromString:logLevel]];
                }
            }

            if (argv[3] != nil) {
                FREGetObjectAsNativeBool(argv[3], &eventBufferingEnabled);
                [adjustConfig setEventBufferingEnabled:eventBufferingEnabled];
            }

            if (argv[4] != nil) {
                FREGetObjectAsNativeBool(argv[4], &isAttributionCallbackSet);

                if (isAttributionCallbackSet) {
                    if (adjustFunctionInstance == nil) {
                        adjustFunctionInstance = [[AdjustFunction alloc] init];
                    }

                    [adjustConfig setDelegate:(id)adjustFunctionInstance];
                }
            }

            if (argv[5] != nil) {
                FREGetObjectAsNativeString(argv[5], &defaultTracker);

                if (defaultTracker != nil) {
                    [adjustConfig setDefaultTracker:defaultTracker];
                }
            }

            if (argv[6] != nil) {
                FREGetObjectAsNativeBool(argv[6], &macMd5TrackingEnabled);
                [adjustConfig setMacMd5TrackingEnabled:macMd5TrackingEnabled];
            }

            if (argv[7] != nil) {
                FREGetObjectAsNativeString(argv[7], &sdkPrefix);
                [adjustConfig setSdkPrefix:sdkPrefix];
            }

            [Adjust appDidLaunch:adjustConfig];
        }
    } else {
        NSLog(@"Adjust: Bridge onCreate method triggered with wrong number of arguments");
    }

    FREObject return_value;
    FRENewObjectFromBool(true, &return_value);
    return return_value;
}

FREObject ADJtrackEvent(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    if (argc == 8) {
        double revenue;

        BOOL isReceiptSet;

        NSString *eventToken;
        NSString *currency;
        NSString *receipt;
        NSString *transactionId;

        NSMutableArray *callbackParameters;
        NSMutableArray *partnerParameters;

        FREGetObjectAsNativeString(argv[0], &eventToken);
        FREGetObjectAsNativeString(argv[1], &currency);
        FREGetObjectAsDouble(argv[2], &revenue);
        FREGetObjectAsNativeArray(argv[3], &callbackParameters);
        FREGetObjectAsNativeArray(argv[4], &partnerParameters);
        FREGetObjectAsNativeString(argv[5], &transactionId);
        FREGetObjectAsNativeString(argv[6], &receipt);
        FREGetObjectAsNativeBool(argv[7], &isReceiptSet);

        if (eventToken != nil) {
            ADJEvent *adjustEvent = [ADJEvent eventWithEventToken:eventToken];

            if (currency != nil) {
                [adjustEvent setRevenue:revenue currency:currency];
            }

            if (callbackParameters != nil) {
                for (int i = 0; i < [callbackParameters count]; i += 2) {
                    NSString *key = [callbackParameters objectAtIndex:i];
                    NSString *value = [callbackParameters objectAtIndex:(i+1)];

                    [adjustEvent addCallbackParameter:key value:value];
                }
            }

            if (partnerParameters != nil) {
                for (int i = 0; i < [partnerParameters count]; i += 2) {
                    NSString *key = [partnerParameters objectAtIndex:i];
                    NSString *value = [partnerParameters objectAtIndex:(i+1)];

                    [adjustEvent addPartnerParameter:key value:value];
                }
            }

            if (isReceiptSet) {
                [adjustEvent setReceipt:[receipt dataUsingEncoding:NSUTF8StringEncoding] transactionId:transactionId];
            } else {
                if (transactionId != nil) {
                    [adjustEvent setTransactionId:transactionId];
                }
            }

            [Adjust trackEvent:adjustEvent];
        }
    } else {
        NSLog(@"Adjust: Bridge trackEvent method triggered with wrong number of arguments");
    }

    FREObject return_value;
    FRENewObjectFromBool(true, &return_value);
    return return_value;
}

FREObject ADJsetEnabled(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    if (argc == 1) {
        BOOL enable;

        FREGetObjectAsNativeBool(argv[0], &enable);

        [Adjust setEnabled:enable];
    } else {
        NSLog(@"Adjust: Bridge setEnabled method triggered with wrong number of arguments");
    }

    FREObject return_value;
    FRENewObjectFromBool(true, &return_value);
    return return_value;
}

FREObject ADJisEnabled(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    if (argc == 0) {
        BOOL isEnabled = [Adjust isEnabled];

        FREObject return_value;
        FRENewObjectFromBool((uint32_t)isEnabled, &return_value);
        return return_value;
    } else {
        NSLog(@"Adjust: Bridge isEnabled method triggered with wrong number of arguments");

        FREObject return_value;
        FRENewObjectFromBool(false, &return_value);
        return return_value;
    }
}

FREObject ADJonResume(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    FREObject return_value;
    FRENewObjectFromBool((uint32_t)ADJisEnabled, &return_value);
    return return_value;
}

FREObject ADJonPause(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    FREObject return_value;
    FRENewObjectFromBool((uint32_t)ADJisEnabled, &return_value);
    return return_value;
}

FREObject ADJappWillOpenUrl(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    if (argc == 1) {
        NSString *pUrl;

        FREGetObjectAsNativeString(argv[0], &pUrl);

        NSURL *url = [NSURL URLWithString:pUrl];

        [Adjust appWillOpenUrl:url];
    } else {
        NSLog(@"Adjust: Bridge appWillOpenUrl method triggered with wrong number of arguments");
    }

    FREObject return_value;
    FRENewObjectFromBool(true, &return_value);
    return return_value;
}

FREObject ADJsetOfflineMode(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    if (argc == 1) {
        BOOL isOffline;

        FREGetObjectAsNativeBool(argv[0], &isOffline);

        [Adjust setOfflineMode:isOffline];
    } else {
        NSLog(@"Adjust: Bridge setOfflineMode method triggered with wrong number of arguments");
    }

    FREObject return_value;
    FRENewObjectFromBool(true, &return_value);
    return return_value;
}

FREObject ADJsetDeviceToken(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    if (argc == 1) {
        NSString *pDeviceToken;

        FREGetObjectAsNativeString(argv[0], &pDeviceToken);

        NSData *deviceToken = [pDeviceToken dataUsingEncoding:NSUTF8StringEncoding];

        [Adjust setDeviceToken:deviceToken];
    } else {
        NSLog(@"Adjust: Bridge setDeviceToken method triggered with wrong number of arguments");
    }

    FREObject return_value;
    FRENewObjectFromBool(true, &return_value);
    return return_value;
}

FREObject ADJsetReferrer(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    FREObject return_value;
    FRENewObjectFromBool(true, &return_value);
    return return_value;
}