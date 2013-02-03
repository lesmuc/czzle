//
//  MapAnnotation.h
//  czzle
//
//  Created by Udo Von Eynern on 03.02.13.
//  Copyright (c) 2013 Udo Von Eynern / Alex Haslberger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapAnnotation : NSObject <MKAnnotation> {
    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
    MKPinAnnotationColor pinColor;
}

@property (nonatomic,retain) NSString *title;
@property (nonatomic,retain) NSString *subtitle;
@property (nonatomic, assign) MKPinAnnotationColor pinColor;

-(id)initWithCoordinate:(CLLocationCoordinate2D) c;

@end

