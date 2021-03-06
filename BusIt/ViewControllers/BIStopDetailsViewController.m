//
//  BIArrivalDeparturesTableViewController.m
//  BusStop
//
//  Created by Lolcat on 8/4/13.
//  Copyright (c) 2013 0xC0ffee. All rights reserved.
//

#import "BIStopDetailsViewController.h"

@interface BIStopDetailsViewController ()
    @property BIBusData *busData;
@end

@implementation BIStopDetailsViewController {
}

@synthesize busData, stop;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        busData = [[BIBusData alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateAPIData];
    NSLog(@"Did update apiData");
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHue:0.589 saturation:1 brightness:1.0 alpha:0.3];
    [self.tableView reloadData];
    self.navigationItem.title = [NSString stringWithFormat:@"%@", stop.name];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
- (IBAction)dismissView:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - API

- (IBAction)refresh:(id)sender {
    [self updateAPIData];
    CGPoint top = CGPointMake(self.tableView.contentOffset.x, -self.tableView.contentInset.top);
    [self.tableView setContentOffset:top animated:YES];
}

- (void)updateAPIData
{
    NSLog(@"about to fetch arrivals for stop");
    NSLog(@"stop: %@", stop);
    self.progressBar.progress = 0.1;

    [stop fetchArrivalsAndPerformCallback:^{
        NSLog(@"Got the OBA data");
        [self.tableView reloadData];
        self.progressBar.progress = 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.progressBar.progress = 0;
        });
    } progressCallback:^(float newDownloadProgress) {
        self.progressBar.progress = newDownloadProgress;
    }];

    // Got the local GTFS data, can reload
    NSLog(@"Did fetch arrivals");
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([stop.arrivals count] == 0)
        return 1;
    return [stop.arrivals count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([stop.arrivals count] == 0)
        return 0;
    return [[stop.arrivals objectForKey:stop.arrivalKeys[section]] count];
}

-(BIArrival *)dataForIndexPath:(NSIndexPath *)indexPath {
    return [stop.arrivals objectForKey:stop.arrivalKeys[indexPath.section]][indexPath.row];
}

#pragma mark - Table view delegate

- (NSString *)distanceString:(float)meters
{
	if(meters > 1000.0) {
		float km = meters * 0.001;
		if(km > 5.0) {
			return [NSString stringWithFormat:NSLocalizedString(@"%0.0f km", nil), km];
		} else {
			return [NSString stringWithFormat:NSLocalizedString(@"%0.1f km", nil), km];
		}
	} else {
		return [NSString stringWithFormat:NSLocalizedString(@"%0.0f meters", nil), meters];
	}
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    static NSString *CellIdentifier = @"TripHeadsignCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        [NSException raise:@"headerView == nil.." format:@"No cells with matching CellIdentifier loaded from your storyboard"];
    }

    UILabel *routeNumber = (UILabel *)[cell viewWithTag:1];
    UILabel *tripHeadsign = (UILabel *)[cell viewWithTag:2];

    if ([stop.arrivals count] == 0) {
        routeNumber.text = @"☹";
        tripHeadsign.text = @"No scheduled arrivals.";
        return cell;
    }
    else {
        NSMutableArray *arrivalGroup = [stop.arrivals objectForKey:[stop.arrivalKeys objectAtIndex:section]];
        BIArrival *arrival = arrivalGroup[0];

        routeNumber.text = arrival.routeId;
        tripHeadsign.text = arrival.tripHeadsign;
    }

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    BIArrival *arrival = [self dataForIndexPath:indexPath];
    UITableViewCell *cell;
    static NSString *CellIdentifier;
    NSDateFormatter *DateFormatter= [[NSDateFormatter alloc] init];
    NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"EST"];
    [DateFormatter setDateFormat:@"hh:mm"];
    [DateFormatter setTimeZone:tz];
    
    if (arrival.hasObaData == NO) {
        CellIdentifier = @"ScheduledArrivalCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UILabel *scheduled = (UILabel *)[cell viewWithTag:1];
        scheduled.text = [DateFormatter stringFromDate:arrival.scheduledArrivalTime];
    }
    else {
        CellIdentifier = @"RealtimeArrivalCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        UILabel *scheduled = (UILabel *)[cell viewWithTag:1];
        UILabel *predicted = (UILabel *)[cell viewWithTag:2];
        UILabel *distance = (UILabel *)[cell viewWithTag:3];
        UILabel *timeOffset = (UILabel *)[cell viewWithTag:4];
        scheduled.text = [DateFormatter stringFromDate:arrival.scheduledArrivalTime];
        predicted.text = [DateFormatter stringFromDate:arrival.predictedArrivalTime];
        distance.text = [NSString stringWithFormat:@"%@ / %@ stops away", arrival.formattedDistanceFromStop, arrival.numberOfStopsAway.stringValue];
        timeOffset.text = arrival.formattedScheduleDeviation;
    }

    NSDate *now = [NSDate date];
    if ([now isEqual:[arrival.scheduledArrivalTime laterDate:now]]) {
        cell.backgroundColor = [UIColor colorWithHue:[BIHelpers hueForRoute:[arrival.routeId intValue]] saturation:0.01 brightness:0.945 alpha:1];
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // http://stackoverflow.com/questions/8615862/custom-cell-row-height-setting-in-storyboard-is-not-responding
    // For some reason the custom heights specified in Storyboard are ignored.
    // This will force them to the custom height.

    if ([[self dataForIndexPath:indexPath] hasObaData])
    {
        return 60.0f;
    }
    else {
        return 40.0f;
    }
}

@end
