//
//  JSCalendarManager.m
//  CalendarManager
//
//  Created by Jing Shan on 6/14/15.
//  Copyright (c) 2015 Jing Shan. All rights reserved.
//

#import "JSCalendarManager.h"

typedef enum:NSInteger{
	updateTitle = 1,
	updateLocation,
	updateStartDate,
	updateEndDate,
	updateNotes,
	updateURL
}updateOptions;


@interface JSCalendarManager ()
@property(nonatomic,strong)EKEventStore *eventStore;
@property(nonatomic,strong)EKCalendar *calendar;
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
		self.calendar = [self.eventStore defaultCalendarForNewEvents];
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

-(NSArray *)allCalendars
{
	if ([JSCalendarManager calendarAccessGranted]) {
		return [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
	}
	return nil;
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

#pragma mark - Calendar operation
-(void)setUsingCalendar:(NSString *)calendarIdentifier
{
	if (calendarIdentifier) {
		EKCalendar *cal = [self.eventStore calendarWithIdentifier:calendarIdentifier];
		if (cal) {
			self.calendar = cal;
		}
		else{
			self.calendar = [self.eventStore defaultCalendarForNewEvents];
		}
	}
}

-(void)createCalendar:(NSString *)calendarTitle iCloud:(BOOL)icloud completionHandler:(calendarOperationCompletionHandler)handler
{
	if (icloud && ![self isICloudCalendarAvailable]) {
		NSError *error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorICloudCalendarNotAvailable userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	EKSource *calendarSource;
	for (EKSource *source in self.eventStore.sources) {
		if (icloud) {
			if (source.sourceType == EKSourceTypeCalDAV && [source.title isEqualToString:@"iCloud"]) {
				calendarSource = source;
				break;
			}
		}
		else{
			if (source.sourceType == EKSourceTypeLocal) {
				calendarSource = source;
				break;
			}
		}
	}
	
	if (!calendarSource) {
		NSError *error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarSourceNotAvailable userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	EKCalendar *cal = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
	cal.source = calendarSource;
	cal.title = calendarTitle;
	
	NSError *error = nil;
	BOOL success = [self.eventStore saveCalendar:cal commit:YES error:&error];
	if (success) {
		self.calendar = cal;
		handler (success,error,cal.calendarIdentifier);
	}else{
		handler(success,error,nil);
	}
}

-(void)createLocalCalendar:(NSString *)calendarTitle completionHandler:(calendarOperationCompletionHandler)handler
{
	[self createCalendar:calendarTitle iCloud:NO completionHandler:handler];
}

-(void)deleteCalendar:(NSString *)calendarIdentifier completionHandler:(calendarOperationCompletionHandler)handler
{
	EKCalendar *calendar = [self.eventStore calendarWithIdentifier:calendarIdentifier];
	
	NSError *error = nil;
	if (calendar) {
		BOOL success = [self.eventStore removeCalendar:calendar commit:YES error:&error];
		handler(success,error,calendarIdentifier);
	}else{
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarDoesNotExist userInfo:nil];
		handler(NO,error,calendarIdentifier);
	}
}

#pragma mark - Event operations
-(void)createEvent:(NSString *)eventTitle location:(NSString *)location startTime:(NSDate *)startDate endTime:(NSDate *)endDate description:(NSString *)description URL:(NSString *)urlString completionHanlder:(eventsOperationCompletionHandler)handler
{
	NSError *error = nil;
	if (!self.calendar) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarDoesNotExist userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	EKEvent *event = [EKEvent eventWithEventStore:self.eventStore];
	
	event.calendar = self.calendar;
	
	event.title = eventTitle;
	event.location = location;
	event.startDate = startDate;
	event.endDate = endDate;
	event.notes = description;
	event.URL = [NSURL URLWithString:urlString];
	
	BOOL success = [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
	handler(success,error,event.eventIdentifier);
}

-(void)createEvent:(EKEvent *)event completionHandler:(eventsOperationCompletionHandler)handler
{
	NSError *error = nil;
	if (!self.calendar) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarDoesNotExist userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	event.calendar = self.calendar;
	BOOL success = [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
	handler(success,error,event.eventIdentifier);
}

-(void)updateEvent:(NSString *)eventIdentifier withTitle:(NSString *)title location:(NSString *)location startTime:(NSDate *)start endTime:(NSDate *)end description:(NSString *)descrition URL:(NSString *)urlString completionHandler:(eventsOperationCompletionHandler)handler
{
	NSError *error = nil;
	if (!self.calendar) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarDoesNotExist userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	EKEvent *event = [self.eventStore eventWithIdentifier:eventIdentifier];
	if (!event) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorEventDoesNotExist userInfo:nil];
		handler(NO,error,eventIdentifier);
		return;
	}
	event.title = title;
	event.location = location;
	event.startDate = start;
	event.endDate = end;
	event.notes = descrition;
	event.URL = [NSURL URLWithString:urlString];
	
	BOOL success = [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
	handler(success,error,event.eventIdentifier);
}

-(void)updateEvent:(NSString *)eventIdentifier withEvent:(EKEvent *)event completionHandler:(eventsOperationCompletionHandler)handler
{
	[self updateEvent:eventIdentifier
			withTitle:event.title
			 location:event.location
			startTime:event.startDate
			  endTime:event.endDate
		  description:event.description
				  URL:[event.URL absoluteString]
	completionHandler:handler];
}

-(void)updateEventWithOption:(updateOptions)option value:(id)value forEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler
{
	NSError *error = nil;
	if (!self.calendar) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarDoesNotExist userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	EKEvent *event = [self.eventStore eventWithIdentifier:eventIdentifier];
	if (!event) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorEventDoesNotExist userInfo:nil];
		handler(NO,error,eventIdentifier);
		return;
	}
	
	switch (option) {
		case updateTitle:
			event.title = (NSString *)value;
			break;
		case updateLocation:
			event.location = (NSString *)value;
			break;
		case updateStartDate:
			event.startDate = (NSDate *)value;
			break;
		case updateEndDate:
			event.endDate = (NSDate *)value;
			break;
		case updateNotes:
			event.notes = (NSString *)value;
			break;
		case updateURL:
			event.URL = [NSURL URLWithString:value];
			break;
	default:
			break;
	}
	
	BOOL success = [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
	handler(success,error,event.eventIdentifier);
}


-(void)updateEventTitle:(NSString *)title forEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler
{
	[self updateEventWithOption:updateTitle value:title forEvent:eventIdentifier completionHandler:handler];
}

-(void)updateEventLocation:(NSString *)location forEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler
{
	[self updateEventWithOption:updateLocation value:location forEvent:eventIdentifier completionHandler:handler];
}

-(void)updateEventStartTime:(NSDate *)startTime forEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler
{
	[self updateEventWithOption:updateStartDate value:startTime forEvent:eventIdentifier completionHandler:handler];
}

-(void)updateEventEndTime:(NSDate *)endTime forEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler
{
	[self updateEventWithOption:updateEndDate value:endTime forEvent:eventIdentifier completionHandler:handler];
}

-(void)updateEventDescription:(NSString *)description forEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler
{
	[self updateEventWithOption:updateNotes value:description forEvent:eventIdentifier completionHandler:handler];
}

-(void)updateEventURL:(NSString *)urlString forEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler
{
	[self updateEventWithOption:updateURL value:urlString forEvent:eventIdentifier completionHandler:handler];
}

-(void)deleteEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler
{
	NSError *error = nil;
	if (!self.calendar) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarDoesNotExist userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	EKEvent *event = [self.eventStore eventWithIdentifier:eventIdentifier];
	if (!event) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorEventDoesNotExist userInfo:nil];
		handler(NO,error,eventIdentifier);
		return;
	}
	
	BOOL success = [self.eventStore removeEvent:event span:EKSpanThisEvent commit:YES error:&error];
	handler(success,error,eventIdentifier);
}

#pragma mark - Event search operations
-(void)isEvent:(NSString *)eventIdentifier inCalendarWithSearchHandler:(eventSearchHandler)handler
{
	NSError *error = nil;
	if (![JSCalendarManager calendarAccessGranted]) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarAccessNotGranted userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	EKEvent *event = [self.eventStore eventWithIdentifier:eventIdentifier];
	if (event) {
		handler(YES,error,@[event]);
	}else{
		handler(NO,error,nil);
	}
}

-(void)findEventsBetween:(NSDate *)start and:(NSDate *)end withSearchHandler:(eventSearchHandler)handler
{
	NSError *error = nil;
	if (![JSCalendarManager calendarAccessGranted]) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarAccessNotGranted userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	if (!self.calendar) {
		error = [NSError errorWithDomain:JSCalendarManagerErrorDomain code:kErrorCalendarDoesNotExist userInfo:nil];
		handler(NO,error,nil);
		return;
	}
	
	
	NSPredicate *searchPredicate = [self.eventStore predicateForEventsWithStartDate:start endDate:end calendars:@[self.calendar]];
	
	NSArray *events = [self.eventStore eventsMatchingPredicate:searchPredicate];
	
	if (events) {
		handler(YES,error,events);
	}else{
		handler(NO,error,events);
	}
}

@end
