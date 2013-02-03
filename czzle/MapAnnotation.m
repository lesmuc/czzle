//
//  MapAnnotation.m
//  czzle
//
//  Created by Udo Von Eynern on 03.02.13.
//  Copyright (c) 2013 Udo Von Eynern / Alex Haslberger. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;
@synthesize pinColor;

- (NSString *)subtitle{
    return subtitle;
}
- (NSString *)title{
    return title;
}
-(id)initWithCoordinate:(CLLocationCoordinate2D) c{
    coordinate=c;
    return self;
}
@end
