//
//  BusStopREST.m
//  BusStop
//
//  Created by Chris Woodard on 4/12/13.
//  Copyright (c) 2013 0xC0ffee. All rights reserved.
//

#import "BusStopREST.h"

#define kFrakkingLongAPIKey @"onebusaway.forest.usf.edu-7e74c063-43c9-4067-8aef-5730aa860628"
#define kFrakkingStupidAgencyID @"Hillsborough%20Area%20Regional%20Transit"

@implementation BusStopREST

-(NSDictionary *)restToJSON:(NSString *)jsonURL
{
    NSString *wholeURLStr = [NSString stringWithFormat:@"%@?key=%@", jsonURL, kFrakkingLongAPIKey];
    NSURL *url = [NSURL URLWithString:wholeURLStr];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [req setHTTPMethod:@"GET"];
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:req delegate:self];
    
    self.cumulativeData = [[NSMutableData alloc] initWithCapacity:0];
    isFinished = NO;
    isScrewed = NO;
    [conn start];
    while(!isFinished)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:self.cumulativeData options:0 error:nil];
    return response;
}

-(NSDictionary *)agencies
{
    return [self restToJSON:@"http://onebusaway.forest.usf.edu/api/api/where/agencies-with-coverage.json"];
}

-(NSDictionary *)routesForAgency
{
    return [self restToJSON:@"http://onebusaway.forest.usf.edu/api/api/where/routes-for-agency/Hillsborough%20Area%20Regional%20Transit.json"];
}

#pragma mark - NSURLConnection/Data Delegates

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.cumulativeData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.cumulativeData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // hope we don't get here
    isFinished = YES;
    isScrewed = YES;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    isFinished = YES;
    isScrewed = NO;
}

@end