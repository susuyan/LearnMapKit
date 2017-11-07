//
//  YULocationManager.h
//  LearnMapKit
//
//  Created by susuyan on 2017/8/24.
//  Copyright © 2017年 susuyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


typedef void(^LocationUpdateBlock)(BOOL success, NSDictionary *locationDictionary, NSError *error);
typedef void(^GeoCodeUpdateBlock)(BOOL success, NSDictionary *geoCodeDictionary, NSError *error);

static NSString * const kLatitude = @"latitude";
static NSString * const kLongitude = @"longitude";
static NSString * const kAltitude = @"altitude";
static NSString * const kRadious = @"radious";

static NSString * const kAddressName = @"address_name";                 // eg. Apple Inc
static NSString * const kAddressStreet = @"address_street";             // street name, eg. Infinite Loop
static NSString * const kAddressCity = @"address_city";                 // city, eg. Cupertino
static NSString * const kAddressState = @"address_state";               // state, eg. CA
static NSString * const kAddressCounty = @"address_county";             // county, eg. Santa Clara
static NSString * const kAddressZipcode = @"address_zipcode";           // zip code, eg. 95014
static NSString * const kAddressCountry = @"address_country";           // eg. United States
static NSString * const kAddressDictionary = @"address_full_dictionary";// total "addressDictionary" of "CLPlacemark" object

@interface YULocationManager : NSObject

/**
 *  The last known Geocode address determinded, will be nil if there is no geocode was requested.
 */
@property (nonatomic, strong) NSDictionary *lastKnownGeocodeAddress;

/**
 *  The last known location received. Will be nil until a location has been received. Returns an Dictionary using keys kLATITUDE, kLONGITUDE, kALTITUDE
 */
@property (nonatomic, strong) NSDictionary *lastKnownGeoLocation;

/**
 *  Similar to lastKnownLocation, The last location received. Will be nil until a location has been received. Returns an Dictionary using keys kLATITUDE, kLONGITUDE, kALTITUDE
 */
@property (nonatomic, strong) NSDictionary *location;


/**
 Returns a singeton(static) instance of the YULocationManager

 @return Instance of the YULocationManager
 */
+ (instancetype)sharedManager;


#pragma mark - Location

/**
 Location permission
 
 @return true or false based on permission given or not
 */
+ (BOOL)locationPermission;


/**
 Request location permission
 */
- (void)requestPermissionForStartUpdatingLocation;


/**
 Return current location

 @param completion A block which will be called when the location is updated
 */
- (void)requestCurrentLocationWithCompletion:(LocationUpdateBlock)completion;


/**
 Return current locaiton's geocode address

 @param completion Callback block is called when the location an geocode is updated
 */
- (void)requestCurrentGeoCodeAddressWithCompletion:(GeoCodeUpdateBlock)completion;
@end
