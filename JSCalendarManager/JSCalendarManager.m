//
//  JSCalendarManager.m
//  CalendarManager
//
//  Created by Jing Shan on 6/14/15.
//  Copyright (c) 2015 Jing Shan. All rights reserved.
//

#import "JSCalendarManager.h"

@interface JSCalendarManager ()
@property(nonatomic,strong)EKEventStore *eventStore;
@end

@implementation JSCalendarManager

+(instancetype)sharedManager
{
	static JSCalendarManager *manager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,^{
		manager = [[self alloc]init];
	});
	return manager;
}

-(instancetype)init
{
	self = [super init];
	if (self) {
		self.eventStore = [[EKEventStore alloc]init];
	}
	return self;
}

#pragma mark - Determine access to calendar
+(BOOL)calendarAccessGranted
{
	EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
	return (status == EKAuthorizationStatusAuthorized)?YES:NO;
}

+(BOOL)shouldRequestCalendarAccess
{
	EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
	return (status == EKAuthorizationStatusNotDetermined)?YES:NO;
}

+(BOOL)shouldGrantAccessManually
{
	EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
	if (status == EKAuthorizationStatusDenied || status == EKAuthorizationStatusRestricted) {
		return YES;
	}
	else return NO;
}

-(void)requestCalendarAccessWithCompletionHandler:(EKEventStoreRequestAccessCompletionHandler)handler
{
	if ([JSCalendarManager shouldRequestCalendarAccess]) {
		[self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:handler];
	}
	if ([JSCalendarManager calendarAccessGranted]){
		handler(YES,nil);
	}
	if ([JSCalendarManager shouldGrantAccessManually]) {
		NSError *error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarAccessNotGranted userInfo:nil];
		handler(NO,error);
	}
}

#pragma mark - Event store methods

-(BOOL)isICloudCalendarAvailable
{
	for (EKSource *source in self.eventStore.sources) {
		if (source.sourceType == EKSourceTypeCalDAV && [source.title isEqualToString:@"iCloud"]) {
			return YES;
		}
	}
	return NO;
}

-(NSArray *)nonBirthDayCalendars
{
	NSMutableArray *calendars = [NSMutableArray array];
	if ([JSCalendarManager calendarAccessGranted]) {
		for (EKCalendar *calendar in [self.eventStore calendarsForEntityType:EKEntityTypeEvent]) {
			if (calendar.type != EKCalendarTypeBirthday) {
				[calendars addObject:calendar];
			}
		}
	}
	return calendars;
}

-(NSArray *)iCloudCalendars
{
	NSMutableArray *calendars = [NSMutableArray array];
	if ([JSCalendarManager calendarAccessGranted]) {
		for (EKCalendar *calendar in [self.eventStore calendarsForEntityType:EKEntityTypeEvent]) {
			if (calendar.type == EKCalendarTypeCalDAV && [calendar.source.title isEqualToString:@"iCloud"]) {
				[calendars addObject:calendar];
			}
		}
	}
	return calendars;
}


@end
