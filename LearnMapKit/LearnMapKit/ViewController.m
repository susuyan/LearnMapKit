//
//  ViewController.m
//  LearnMapKit
//
//  Created by susuyan on 2017/8/23.
//  Copyright © 2017年 susuyan. All rights reserved.
//

#import "ViewController.h"

#import <MapKit/MapKit.h>
#import "YULocationManager.h"

@interface ViewController ()<MKMapViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}
- (IBAction)locationAction:(UIButton *)sender {

    YULocationManager *manager = [YULocationManager sharedManager];
//    [manager requestCurrentLocationWithCompletion:^(BOOL success, NSDictionary *locationDictionary, NSError *error) {
//       
//        NSLog(@"%@",locationDictionary);
//    }];
    
    [manager requestCurrentGeoCodeAddressWithCompletion:^(BOOL success, NSDictionary *geoCodeDictionary, NSError *error) {
        
        NSLog(@"%@",geoCodeDictionary);
    }];

}



@end
