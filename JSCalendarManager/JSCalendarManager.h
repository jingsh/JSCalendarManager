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
}JSCalendarManagerErrorCode;

typedef void (^calendarOperationCompletionHandler)(BOOL success, NSError *error, NSString *calendarIdentifier);
typedef void (^eventsOperationCompletionHandler)(BOOL success, NSError *error, NSString *eventIdentifier);

@interface JSCalendarManager : NSObject

+(instancetype)sharedManager;

+(BOOL)calendarAccessGranted;

+(BOOL)shouldRequestCalendarAccess;

+(BOOL)shouldGrantAccessManually;

-(void)requestCalendarAccessWithCompletionHandler:(EKEventStoreRequestAccessCompletionHandler)handler;

-(BOOL)isICloudCalendarAvailable;

-(NSArray *)nonBirthDayCalendars;

-(NSArray *)iCloudCalendars;

-(void)setDefaultCalendar:(NSString *)calendarIdentifier;

-(void)createCalendar:(NSString *)calendarTitle
			   iCloud:(BOOL)icloud
	completionHandler:(calendarOperationCompletionHandler)handler;

-(void)deleteCalendar:(NSString *)calendarIdentifier
	completionHandler:(calendarOperationCompletionHandler)handler;

-(void)createEvent:(NSString *)eventTitle
		  location:(NSString *)location
		 startTime:(NSDate *)startDate
		   endTime:(NSDate *)endDate
	   description:(NSString *)description
			   URL:(NSString *)urlString
 completionHanlder:(eventsOperationCompletionHandler)handler;

-(void)createEvent:(EKEvent *)event
 completionHandler:(eventsOperationCompletionHandler)handler;

-(void)updateEvent:(NSString *)eventIdentifier
		 withTitle:(NSString *)title
		  location:(NSString *)location
		 startTime:(NSDate *)start
		   endTime:(NSDate *)end
	   description:(NSString *)descrition
			   URL:(NSString *)urlString
 completionHandler:(eventsOperationCompletionHandler)handler;

-(void)updateEvent:(NSString *)eventIdentifier
		 withEvent:(EKEvent *)event
 completionHandler:(eventsOperationCompletionHandler)handler;

-(void)updateEventTitle:(NSString *)title
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

-(void)updateEventLocation:(NSString *)location
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

-(void)updateEventDescription:(NSString *)description
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

-(void)updateEventStartTime:(NSDate *)startTime
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

-(void)updateEventEndTime:(NSDate *)endTime
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

-(void)updateEventURL:(NSString *)urlString
			   forEvent:(NSString *)eventIdentifier
	  completionHandler:(eventsOperationCompletionHandler)handler;

-(void)deleteEvent:(NSString *)eventIdentifier completionHandler:(eventsOperationCompletionHandler)handler;


@end
