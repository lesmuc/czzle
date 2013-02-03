//
//  ViewController.h
//  czzle
//
//  Created by Udo Von Eynern on 02.02.13.
//  Copyright (c) 2013 Udo Von Eynern / Alex Haslberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CocoaLibSpotify.h"
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController <SPSessionDelegate, SPSessionPlaybackDelegate>

@property (nonatomic, strong) SPTrack *currentTrack;
@property (nonatomic, strong) SPPlaybackManager *playbackManager;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) NSDictionary *artistDictionary;

@property (nonatomic, strong) UIImageView *rightLocationImageView;

@property (nonatomic, strong) IBOutlet UILabel *labelScore;
@property (nonatomic, strong) IBOutlet UILabel *labelTime;
@property (nonatomic, strong) IBOutlet UILabel *labelLevel;

@property (nonatomic, strong) IBOutlet UIView *labelScoreView;
@property (nonatomic, strong) IBOutlet UIView *labelTimeView;
@property (nonatomic, strong) IBOutlet UIView *labelLevelView;

@property (nonatomic, strong) IBOutlet UIView *resultView;
@property (nonatomic, strong) IBOutlet UILabel *resultLabel;
@property (nonatomic, strong) IBOutlet UITextView *resultTextView;

@property (nonatomic, strong) IBOutlet UIButton *buttonAction;

@property (nonatomic, strong) IBOutlet UIView *titleView;

@property (assign) BOOL gamePaused;

@property (assign) int score;
@property (assign) int level;

@end
