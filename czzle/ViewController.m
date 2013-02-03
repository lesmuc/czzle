//
//  ViewController.m
//  czzle
//
//  Created by Udo Von Eynern on 02.02.13.
//  Copyright (c) 2013 Udo Von Eynern / Alex Haslberger. All rights reserved.
//

#import "ViewController.h"
#import "AFJSONRequestOperation.h"
#import "CocoaLibSpotify.h"
#include "appkey.c"
#import "SPURLExtensions.h"
#import "AFHTTPClient.h"
#import "AppDelegate.h"
#import "MapAnnotation.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.labelScoreView.alpha = 0.0f;
    self.labelTimeView.alpha = 0.0f;
    self.labelLevelView.alpha = 0.0f;
    self.resultView.alpha = 0.0f;
    self.titleView.alpha = 0.0f;
    
    self.score = START_POINTS;
    self.labelScore.text = [NSString stringWithFormat:@"%i", self.score];
    
    self.level = 1;
    self.labelLevel.text = [NSString stringWithFormat:@"Level %i", self.level];
    
    self.resultLabel.text = @"";
    self.resultTextView.text = @"";
    
	NSError *error = nil;
	[SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
											   userAgent:@"com.spotify.SimplePlayer-iOS"
										   loadingPolicy:SPAsyncLoadingManual
												   error:&error];
	if (error != nil) {
		NSLog(@"CocoaLibSpotify init failed: %@", error);
		abort();
	}
    
	self.playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
	[[SPSession sharedSession] setDelegate:self];
    
	[self addObserver:self forKeyPath:@"currentTrack.name" options:0 context:nil];
	[self addObserver:self forKeyPath:@"currentTrack.artists" options:0 context:nil];
	[self addObserver:self forKeyPath:@"currentTrack.duration" options:0 context:nil];
	[self addObserver:self forKeyPath:@"currentTrack.album.cover.image" options:0 context:nil];
	[self addObserver:self forKeyPath:@"playbackManager.trackPosition" options:0 context:nil];
	
	[self performSelector:@selector(showLogin) withObject:nil afterDelay:0.3];
    
    UITapGestureRecognizer *lpgr = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleGesture:)];
    [self.mapView addGestureRecognizer:lpgr];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CLLocationCoordinate2D startCoord = CLLocationCoordinate2DMake(48.216, 16.375);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(startCoord, 1000000, 1000000)];
    [self.mapView setRegion:adjustedRegion animated:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentTrack.name"]) {
        NSLog(@"track name: %@", self.currentTrack.name);
	} else if ([keyPath isEqualToString:@"currentTrack.artists"]) {
        NSLog(@"track name: %@", [[self.currentTrack.artists valueForKey:@"name"] componentsJoinedByString:@","]);
	} else if ([keyPath isEqualToString:@"currentTrack.album.cover.image"]) {
	} else if ([keyPath isEqualToString:@"currentTrack.duration"]) {
        
        NSLog(@"track name: %f", self.currentTrack.duration);
        
	} else if ([keyPath isEqualToString:@"playbackManager.trackPosition"]) {
        
        self.labelTime.text = [NSString stringWithFormat:@"%.02f", self.playbackManager.trackPosition];

        self.score = (self.score - 1);
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)showLogin {
    
	SPLoginViewController *controller = [SPLoginViewController loginControllerForSession:[SPSession sharedSession]];
	controller.allowsCancel = NO;
	[self presentViewController:controller animated:YES completion:nil];
}

- (void)loadJSON {
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate showHUD];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@?level=%i", SERVICE_URL, @"/hackday/index.php", self.level];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
            AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [delegate hideHUD];
        
            NSDictionary *songDictionary = [JSON valueForKeyPath:@"song"];
            NSString *foreignId = [songDictionary objectForKey:@"foreign_id"];
        
            [self playTrack:[NSURL URLWithString:foreignId]];
        
            self.labelScoreView.alpha = 0.0f;
            self.labelTimeView.alpha = 0.0f;
            self.labelLevelView.alpha = 0.0f;
            self.titleView.alpha = 0.0f;
        
            [UIView animateWithDuration:2.0 animations:^() {
                self.labelScoreView.alpha = 1.0f;
                self.labelTimeView.alpha = 1.0f;
                self.labelLevelView.alpha = 1.0f;
                self.titleView.alpha = 0.5f;
            }];
        
            self.artistDictionary = [JSON valueForKeyPath:@"artist"];
        
            NSLog(@"artist dictionary: %@", self.artistDictionary);

    } failure:^(NSURLRequest *request , NSURLResponse *response , NSError *error , id JSON){
        
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate hideHUD];
        
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:[error localizedDescription]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }];
    
    [operation start];
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView
             viewForAnnotation:(id <MKAnnotation>) annotation {
    MKPinAnnotationView *annView=[[MKPinAnnotationView alloc]
                                  initWithAnnotation:annotation reuseIdentifier:@"pin"];
    
    NSRange range = [annotation.title rangeOfString:@"Your guess!"];
    
    if (range.location != NSNotFound) {
        annView.pinColor = MKPinAnnotationColorRed;
    } else {
        annView.pinColor = MKPinAnnotationColorGreen;
        annView.selected = YES;
    }
    
    annView.animatesDrop=TRUE;
    annView.canShowCallout = YES;
    
    return annView;
}

- (void)playTrack:(NSURL *)trackURL {
	
    // Invoked by clicking the "Play" button in the UI.
    [[SPSession sharedSession] trackForURL:trackURL callback:^(SPTrack *track) {
        
        if (track != nil) {
            
            [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *tracks, NSArray *notLoadedTracks) {
                [self.playbackManager playTrack:track callback:^(NSError *error) {
                    
                    if (error) {
                        [self loadJSON];
                    } else {
                        self.currentTrack = track;
                    }
                    
                }];
            }];
        }
    }];
    
    return;
}

#pragma mark -
#pragma mark SPSessionDelegate Methods

-(UIViewController *)viewControllerToPresentLoginViewForSession:(SPSession *)aSession {
	return self;
}

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {
	// Invoked by SPSession after a successful login.
    
    [self loadJSON];    
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
	// Invoked by SPSession after a failed login.
}

-(void)sessionDidLogOut:(SPSession *)aSession {
	
	SPLoginViewController *controller = [SPLoginViewController loginControllerForSession:[SPSession sharedSession]];
	controller.allowsCancel = NO;
	
	[self presentViewController:controller animated:YES completion:nil];
}

-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
	return;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
													message:aMessage
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.gamePaused == YES) {
        return;
    }
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    MapAnnotation *addAnnotation = [[MapAnnotation alloc] initWithCoordinate:touchMapCoordinate];
    [addAnnotation setTitle:@"Your guess!"];
    [addAnnotation setPinColor:MKPinAnnotationColorRed];
    [self.mapView addAnnotation:addAnnotation];
    
    self.gamePaused = YES;
    
    NSURL *url = [NSURL URLWithString:SERVICE_URL];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithDouble:touchMapCoordinate.latitude], @"latitude",
                            [NSNumber numberWithDouble:touchMapCoordinate.longitude], @"longitude",
                            [self.artistDictionary valueForKeyPath:@"artist_location"], @"artist_location",
                            [self.artistDictionary valueForKeyPath:@"id"], @"artist_id",                            
                            nil];
    
    
    AFHTTPClient * Client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:SERVICE_URL]];
    NSMutableURLRequest * request = [Client requestWithMethod:@"POST" path:@"/hackday/maps.php" parameters:params];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

        NSLog(@"JSON: %@", JSON);
        
        NSNumber *jsonValue = [JSON objectForKey:@"value"];
        
        self.resultLabel.text = [NSString stringWithFormat:@"Result: %@", [JSON objectForKey:@"text"]];
        self.resultTextView.text = [JSON objectForKey:@"bio"];

        self.score = (self.score - [jsonValue intValue]);
        self.labelScore.text = [NSString stringWithFormat:@"%i", self.score];
        
        self.resultView.alpha = 0.0f;
        
        NSDictionary *locationDictionary = [JSON objectForKey:@"location"];
        
        NSNumber *longitude = (NSNumber *)[locationDictionary objectForKey:@"lng"];
        NSNumber *latitude = (NSNumber *)[locationDictionary objectForKey:@"lat"];
        
        CLLocationCoordinate2D coord;
        coord.longitude = [longitude floatValue];
        coord.latitude = [latitude floatValue];
        
        MapAnnotation *addAnnotation = [[MapAnnotation alloc] initWithCoordinate:coord];
        
        NSString *title = [NSString stringWithFormat:@"%@ lived in %@", [self.artistDictionary objectForKey:@"name"], [locationDictionary objectForKey:@"city"]];
        
        [addAnnotation setTitle:title];
        [addAnnotation setPinColor:MKPinAnnotationColorGreen];
        addAnnotation.pinColor = MKPinAnnotationColorGreen;
        [self.mapView addAnnotation:addAnnotation];
        
        [self.mapView selectAnnotation:addAnnotation animated:YES];
        
        [self zoomToFitMapAnnotations];        
        
        if (self.score >= 0) {
            [self.buttonAction setTitle:@"Next Level" forState:UIControlStateNormal];
            self.buttonAction.tag = 1;
        } else {
            [self.buttonAction setTitle:@"Game Over - Restart" forState:UIControlStateNormal];
            self.buttonAction.tag = 2;
        }
        
        [UIView animateWithDuration:0.3 animations:^() {
            self.resultView.alpha = 1.0f;
            
        }];
        
        // do something with return data
    }failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:[error localizedDescription]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }];
    
    [operation start];
}

-(void)zoomToFitMapAnnotations {
    if([self.mapView.annotations count] == 0)
        return;
    
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    for(MapAnnotation* annotation in self.mapView.annotations)
    {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
        
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 2.5; // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 2.5; // Add a little extra space on the sides
    
    region = [self.mapView regionThatFits:region];
    [self.mapView setRegion:region animated:NO];
}


- (IBAction)doButtonAction:(id)sender {
    
    self.gamePaused = NO;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    UIButton *button = (UIButton *)sender;
    
    self.playbackManager.playbackSession.playing = NO;
    [self.playbackManager.playbackSession unloadPlayback];
        
    self.resultView.alpha = 1.0f;
    
    [UIView animateWithDuration:0.3 animations:^() {
        self.resultView.alpha = 0.0f;
    }];
    
    // Next level
    if (button.tag == 1) {
        self.level++;
        
    } if (button.tag == 2) { // Game Over - Restart
        self.level = 1;
        self.score = START_POINTS;
        self.labelScore.text = [NSString stringWithFormat:@"%i", self.score];
    }
    
    self.labelLevel.text = [NSString stringWithFormat:@"Level %i", self.level];
    
    [self loadJSON];
}


@end
