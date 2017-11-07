//
//  YULocationManager.m
//  LearnMapKit
//
//  Created by susuyan on 2017/8/24.
//  Copyright © 2017年 susuyan. All rights reserved.
//

#import "YULocationManager.h"
#import <UIKit/UIKit.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)	([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

//
//static inline BOOL isEmptyString( NSString * _Null_unspecified str)
//{
//    if(str.length==0 || [str isKindOfClass:[NSNull class]] || [str isEqualToString:@""]|| [str isEqualToString:@"(null)"]||str==nil || [str isEqualToString:@"<null>"]){
//        return YES;
//    }
//    return NO;
//}

//This enum is only used to track what kind of work I need to do inside
//the method -locationManager:didUpdateLocations:
typedef enum : NSUInteger {
    LocationTaskTypeRequestCurrentLocation,
    LocationTaskTypeRequestSignificantChangeLocation,
    LocationTaskTypeRequestGeoCodeAddress,
    LocationTaskTypeNone
} LocationTaskType;


@interface YULocationManager()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray *geofences;

@property (nonatomic, strong) CLGeocoder *geocoder;

@property (nonatomic, copy) LocationUpdateBlock locationCompletionBlock;

@property (nonatomic, copy) GeoCodeUpdateBlock geocodeCompletionBlock;

@property (nonatomic, assign) LocationTaskType activeLocationTaskType;

@end

@implementation YULocationManager

#pragma mark - Initial

+ (instancetype)sharedManager {
    
    static YULocationManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[YULocationManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init {
    if (self == [super init]) {
        
        self.locationManager = [[CLLocationManager alloc] init];
        
        self.locationManager.delegate = self;
        
        self.activeLocationTaskType = LocationTaskTypeNone;
    }
    
    return self;
}
#pragma mark - Private
- (void)startUpdatingLocation {
    
    [self requestPermissionForStartUpdatingLocation];
    
    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] ||
        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysAndWhenInUseUsageDescription"]) {
       
        if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"]) {
            BOOL hasLocationBackgroundMode = NO;
            NSArray *bgmodesArray = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
            
            for(NSString *str in bgmodesArray) {
                if([str isEqualToString:@"location"]) {
                    hasLocationBackgroundMode = YES;
                    break;
                }
            }
            
            if(!hasLocationBackgroundMode) {
                [[NSException exceptionWithName:@"[BBLocationManager] UIBackgroundModes not enabled" reason:@"Your apps info.plist does not contain 'UIBackgroundModes' key with a 'location' string in it, which is required for background location access 'NSLocationAlwaysAndWhenInUseUsageDescription' for iOS 11 or 'NSLocationAlwaysUsageDescription' for iOS 10" userInfo:nil] raise];
            }else{
                if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
                    [self.locationManager setAllowsBackgroundLocationUpdates:YES];
                }
            }
            
        }else{
            [[NSException exceptionWithName:@"[BBLocationManager] UIBackgroundModes not enabled" reason:@"Your apps info.plist does not contain 'UIBackgroundModes' key with a 'location' string in it, which is required for background location access 'NSLocationAlwaysAndWhenInUseUsageDescription' for iOS 11 or 'NSLocationAlwaysUsageDescription' for iOS 10" userInfo:nil] raise];
        }
        
    }
    
    if(self.activeLocationTaskType == LocationTaskTypeRequestSignificantChangeLocation)
    {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
    else
    {
        [self.locationManager startUpdatingLocation];
    }


    
}
#pragma mark - Public

+ (BOOL)locationPermission {
    
    BOOL isPermitted = YES;
    
    if (![CLLocationManager locationServicesEnabled]) {

        return NO;
    }
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLRegion class]]) {

    }

    CLAuthorizationStatus locationPermission = [CLLocationManager authorizationStatus];
    
    if ((locationPermission == kCLAuthorizationStatusRestricted) || (locationPermission == kCLAuthorizationStatusDenied)) {
        
        isPermitted = NO;
        
    }
    
    if (isPermitted &&
        SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") &&
        locationPermission == kCLAuthorizationStatusNotDetermined) {
        
        isPermitted = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] || [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] || [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysAndWhenInUseUsageDescription"];
        
    }

    return isPermitted;
}

- (void)requestPermissionForStartUpdatingLocation {
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {

        if ((status == kCLAuthorizationStatusNotDetermined) &&
            ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)] ||
             [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])) {
                
                if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysAndWhenInUseUsageDescription"]) { //https://developer.apple.com/documentation/corelocation/choosing_the_authorization_level_for_location_services/request_always_authorization
                    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
                        [self.locationManager performSelector:@selector(requestAlwaysAuthorization)];
                    }
                    else{
                        [[NSException exceptionWithName:@"[BBLocationManager] Fix needed for location permission key" reason:@"Your app's info.plist need both NSLocationWhenInUseUsageDescription and NSLocationAlwaysAndWhenInUseUsageDescription keys for asking 'Always usage of location' in iOS 11" userInfo:nil] raise];
                    }
                    
                } else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) { //https://developer.apple.com/documentation/corelocation/choosing_the_authorization_level_for_location_services/requesting_when_in_use_authorization
                    [self.locationManager performSelector:@selector(requestWhenInUseAuthorization)];
                } else {
                    [[NSException exceptionWithName:@"[BBLocationManager] Fix needed for location permission key" reason:@"Your app's info.plist does not contain NSLocationWhenInUseUsageDescription and/or NSLocationAlwaysAndWhenInUseUsageDescription key required for iOS 11" userInfo:nil] raise];
                }

                
            
            }else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
                
                NSLog(@"[BBLocationManager] Location Permission Denied by user, prompt user to allow location permission.");
                NSString *title, *message;
                if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysAndWhenInUseUsageDescription"]) {
                    title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location is not enabled";
                    message = @"To use background location you must turn on 'Always' in the Location Services Settings";
                } else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
                    title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Location Service is not enabled";
                    message = @"To use location you must turn on 'While Using the App' in the Location Services Settings";
                }
            }

    }else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        if ((status == kCLAuthorizationStatusNotDetermined) &&
            ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)] ||
             [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])) {
                
            if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"]) {
                [self.locationManager performSelector:@selector(requestAlwaysAuthorization)];
            } else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
                [self.locationManager performSelector:@selector(requestWhenInUseAuthorization)];
            } else {
                [[NSException exceptionWithName:@"[BBLocationManager] Location Permission Error" reason:@"Info.plist does not contain NSLocationWhenUse or NSLocationAlwaysUsageDescription key required for iOS 8" userInfo:nil] raise];
            }
        } else if(status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted){
            NSLog(@"[BBLocationManager] Location Permission Denied by user, prompt user to allow location permission.");
            NSString *title, *message;
            if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"]) {
                title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location is not enabled";
                message = @"To use background location you must turn on 'Always' in the Location Services Settings";
            } else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
                title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Location Service is not enabled";
                message = @"To use location you must turn on 'While Using the App' in the Location Services Settings";
            }
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Settings", nil];
            [alertView show];
            
            //可以用HUD来替换alert
        }
    }

    
}

#pragma mark - Location

- (void)requestCurrentLocationWithCompletion:(LocationUpdateBlock)completion {

    self.locationCompletionBlock = completion;
    self.activeLocationTaskType = LocationTaskTypeRequestCurrentLocation;
    [self startUpdatingLocation];
}

- (void)requestCurrentGeoCodeAddressWithCompletion:(GeoCodeUpdateBlock)completion {
    self.geocodeCompletionBlock = completion;
    self.activeLocationTaskType = LocationTaskTypeRequestGeoCodeAddress;
    [self startUpdatingLocation];
}

- (void)requestGeoCodeAtLocation:(CLLocation *)location {
    
    if (!self.geocoder) {
        self.geocoder = [[CLGeocoder alloc] init];
    }
    
    YULocationManager *__weak weakSelf = self;
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
       
        if ([placemarks count] > 0) {
            // requested a address
            CLPlacemark *mark = (CLPlacemark *)[placemarks firstObject];
            NSString *name = mark.name ? mark.name : @"";
            NSString *thoroughfare = mark.thoroughfare ? mark.thoroughfare : @"";
            NSString *locality = mark.locality ? mark.locality : @"" ;
            NSString *subAdministrativeArea = mark.subAdministrativeArea ? mark.subAdministrativeArea : @"" ;
            NSString *administrativeArea = mark.administrativeArea ? mark.administrativeArea : @"" ;
            NSString *postalcode = mark.postalCode ? mark.postalCode : @"" ;
            NSString *country = mark.country ? mark.country : @"" ;
            
            weakSelf.lastKnownGeocodeAddress = @{kLatitude    : [NSNumber numberWithDouble:location.coordinate.latitude],
                                                 kLongitude    : [NSNumber numberWithDouble:location.coordinate.longitude],
                                                 kAltitude    : [NSNumber numberWithDouble:location.altitude],
                                                 kAddressName    : name,
                                                 kAddressStreet  : thoroughfare,
                                                 kAddressCity    : locality,
                                                 kAddressState   : administrativeArea,
                                                 kAddressCounty  : subAdministrativeArea,
                                                 kAddressZipcode : postalcode,
                                                 kAddressCountry  : country,
                                                 kAddressDictionary: mark.addressDictionary
                                                 };
            
            
        }else {
            
            weakSelf.lastKnownGeocodeAddress = @{kLatitude    : [NSNumber numberWithDouble:location.coordinate.latitude],
                                                 kLongitude    : [NSNumber numberWithDouble:location.coordinate.longitude],
                                                 kAltitude    : [NSNumber numberWithDouble:location.altitude],
                                                 kAddressName    : @"Unknown",
                                                 kAddressStreet  : @"Unknown",
                                                 kAddressCity    : @"Unknown",
                                                 kAddressState   : @"Unknown",
                                                 kAddressCounty  : @"Unknown",
                                                 kAddressZipcode : @"Unknown",
                                                 kAddressCountry  : @"Unknown",
                                                 kAddressDictionary: @{}
                                                 };
        }
        
        
        if (weakSelf.geocodeCompletionBlock != nil) {
            self.geocodeCompletionBlock(error ? false : true, [NSDictionary dictionaryWithDictionary:weakSelf.lastKnownGeocodeAddress], error);
        }
        
    }];
    
    
}

#pragma mark - CLLocationManager Delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    
    if (locations && locations.count < 1) {
        return;
    }

    
    CLLocation *location = [locations lastObject];
    
    
    switch (self.activeLocationTaskType) {
        case LocationTaskTypeNone:
        {
            
        }
            break;
            
        case LocationTaskTypeRequestCurrentLocation:
        {
            NSDictionary *locationDict = @{kLatitude: [NSNumber numberWithDouble:location.coordinate.latitude],
                                           kLongitude: [NSNumber numberWithDouble:location.coordinate.longitude],
                                           kAltitude: [NSNumber numberWithDouble:location.altitude]};
            
            if (self.locationCompletionBlock != nil) {
                self.locationCompletionBlock(true, locationDict, nil);
            }
            
            [self.locationManager stopUpdatingLocation];
            
            self.activeLocationTaskType = LocationTaskTypeNone;
        }
            break;
        case LocationTaskTypeRequestGeoCodeAddress:
        {
            // Initialize Region/fence to Monitor
            [self requestGeoCodeAtLocation:location];
            
            //stop getting/updating location data, means stop the GPS :)
            [self.locationManager stopUpdatingLocation];
            self.activeLocationTaskType = LocationTaskTypeNone;
        }
            break;
            
            
        default:
            break;
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(nonnull NSError *)error {

    if (self.locationCompletionBlock != nil) {
        self.locationCompletionBlock(false, nil, error);
    }
}

@end
