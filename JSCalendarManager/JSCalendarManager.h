//
//  JSCalendarManager.h
//  CalendarManager
//
//  Created by Jing Shan on 6/14/15.
//  Copyright (c) 2015 Jing Shan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

static NSString *JSCalendarManagerErrorDomain = @"JSCalendarManagerErrorDomain";

typedef enum:NSInteger{
	kErrorCalendarAccessNotGranted = 1001,
	kErrorICloudCalendarNotAvailable,
	kErrorCalendarSourceNotAvailable,
	kErrorCalendarDoesNotExist,
	kErrorEventDoesNotExist,
}JSCalendarManagerErrorCode;

typedef void (^calendarOperationCompletionHandler)(BOOL success, NSError *error, NSString *calendarIdentifier);
typedef void (^eventsOperationCompletionHandler)(BOOL success, NSError *error, NSString *eventIdentifier);
typedef void (^eventSearchHandler)(BOOL found, NSError *error, NSArray *eventsArray);

@interface JSCalendarManager : NSObject

/*!
 @method     sharedManager
 @discussion Returns the singleton calendar manager that can be used in the whole app across different view controllers.
 */
+(instancetype)sharedManager;

/*!
 @method     init
 @discussion Returns the calendar manager object. Contrast to singleton method.
 */
-(instancetype)init;

/*!
 @method     calendarAccessGranted
 @discussion Returns the authorization status for the app
 */
+(BOOL)calendarAccessGranted;

/*!
 @method     shouldRequestCalendarAccess
 @discussion Returns whether should request user to grant access to calendar by the use. Call requestCalendarAccessWithCompletionHandler: method to prompt user for permissions.
 */
+(BOOL)shouldRequestCalendarAccess;

/*!
 @method     shouldGrantAccessManually
 @discussion Returns whether the user has denied or limited the access to calendar.
 */
+(BOOL)shouldGrantAccessManually;

/*!
 @method     requestCalendarAccessWithCompletionHandler:
 @discussion Must call this method before any operation on calendars or events. This method takes EKEventStoreRequestAcessCompletionHandler to handle the permission request response.
 */
-(void)requestCalendarAccessWithCompletionHandler:(EKEventStoreRequestAccessCompletionHandler)handler;

/*!
 @method     isICloudCalendarAvailable
 @discussion Returns whether iCloud calendars are in the calendar database. Call to determine if user can operate on iCloud calendars.
 */
-(BOOL)isICloudCalendarAvailable;

/*!
 @method     allCalendars
 @discussion Returns a list of calendars in the database.
 */
-(NSArray *)allCalendars;

/*!
 @method     iCloudCalendars
 @discussion Returns a list of iCloud calendars in the calendar database.
 */
-(NSArray *)iCloudCalendars;

/*!
 @method     setUsingCalendar:
 @discussion Call this method to set a calendar to use. Typically you should call allCalendars method to get a list of calendars available.
 */
-(void)setUsingCalendar:(NSString *)calendarIdentifier;

/*!
 @method     createCalendar: iCloud: completionHandler:
 @discussion Call this method to create a calendar with the given title. The parameter iCloud indicates whether this calendar is on icloud.
 */
-(void)createCalendar:(NSString *)calendarTitle
			   iCloud:(BOOL)icloud
	completionHandler:(calendarOperationCompletionHandler)handler;

/*!
 @method     createLocalCalendar: completionHandler:
 @discussion Call this method to create a local calendar with the given title.
 */
-(void)createLocalCalendar:(NSString *)calendarTitle
		 completionHandler:(calendarOperationCompletionHandler)handler;

/*!
 @method     deleteCalendar: completionHandler:
 @discussion Call this method to delete a given calendar from the database.
 */
-(void)deleteCalendar:(NSString *)calendarIdentifier
	completionHandler:(calendarOperationCompletionHandler)handler;

/*!
 @method     createEvent: location: startTime: endTime: description: URL: completionHandler:
 @discussion Call this method to creat an event in the selected calendar. Must select a calendar or create one before calling this method.
 */
-(void)createEvent:(NSString *)eventTitle
		  location:(NSString *)location
		 startTime:(NSDate *)startDate
		   endTime:(NSDate *)endDate
	   description:(NSString *)description
			   URL:(NSString *)urlString
 completionHanlder:(eventsOperationCompletionHandler)handler;

/*!
 @method     createEvent: completionHandler:
 @discussion Call this method to create an event from an EKEvent object.
 */
-(void)createEvent:(EKEvent *)event
 completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     updateEvent: withTitle: location: startTime: endTime: description: URL: completionHandler:
 @discussion Call this method to retrieve and update an event.
 */
-(void)updateEvent:(NSString *)eventIdentifier
		 withTitle:(NSString *)title
		  location:(NSString *)location
		 startTime:(NSDate *)start
		   endTime:(NSDate *)end
	   description:(NSString *)descrition
			   URL:(NSString *)urlString
 completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     updateEvent: withEvent: completionHandler:
 @discussion Call this method to retrieve and update the event using an EKEvent object.
 */
-(void)updateEvent:(NSString *)eventIdentifier
		 withEvent:(EKEvent *)event
 completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     updateEventTitle: forEvent: completionHandler:
 @discussion Call this method to retrieve and update the event's title.
 */
-(void)updateEventTitle:(NSString *)title
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     updateEventLocation: forEvent: completionHandler:
 @discussion Call this method to retrieve and update the event's location.
 */
-(void)updateEventLocation:(NSString *)location
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     updateEventDescription: forEvent: completionHandler:
 @discussion Call this method to retrieve and update the event's description.
 */
-(void)updateEventDescription:(NSString *)description
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     updateEventStartTime: forEvent: completionHandler:
 @discussion Call this method to retrieve and update the event's start time.
 */
-(void)updateEventStartTime:(NSDate *)startTime
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     updateEventEndTime: forEvent: completionHandler:
 @discussion Call this method to retrieve and update the event's end time.
 */
-(void)updateEventEndTime:(NSDate *)endTime
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     updateEventURL: forEvent: completionHandler:
 @discussion Call this method to retrieve and update the event's URL.
 */
-(void)updateEventURL:(NSString *)urlString
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     deleteEvent: completionHandler:
 @discussion Call this method to delete an event from database.
 */
-(void)deleteEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler;

/*!
 @method     isEvent: inCalendarWithSearchHandler:
 @discussion Call this method to determine whether an event is in the database.
 */
-(void)isEvent:(NSString *)eventIdentifier inCalendarWithSearchHandler:(eventSearchHandler)handler;

/*!
 @method     findEventsBetween: and: withSearchHandler:
 @discussion Call this method to find all events in the specified date range.
 */
-(void)findEventsBetween:(NSDate *)start and:(NSDate *)end withSearchHandler:(eventSearchHandler)handler;

@end
