# JSCalendarManager
An Objective-C class for common calendar and events tasks. Like creating/deleting calendars, creating/updating/deleting events (`EKEntityTypeEvent`). Requires `EventKit.framework`.

*Support for `EKEntityTypeReminder` will be in future versions.*

You need to link the `EventKit.framework` in the target's build phase.

## How to install?
Drag and drop `JSCalendarManager.h` and `JSCalendarManager.m` file into your project. 

## How to use?
In your project, import the class using
```objective-C
#import"JSCalendarManager.h"
```

### Using the manager as singleton object so that the same manager object can be used across different view controllers.
```objective-C
JSCalendarManager *manager = [JSCalendarManager sharedManager];
```

### Or using in single controller or your data model.
```objective-C
@interface yourClass
@property (nonatomic, strong)JSCalendarManager *manager
@end

@implementation yourClass
//...
self.manager = [[JSCalendarManager alloc]init];
//...
@end
```
## Defined completion handlers
The class defined three completion handler blocks, the definition are pretty self explanatory. 
### Calendar operation handler block
```objective-C
typedef void (^calendarOperationCompletionHandler)(BOOL success, NSError *error, NSString *calendarIdentifier);
```
The block is called by the calendar operations, such as create or delete calendars in the device's calendar database. It includes a `BOOL success` flag, a `NSError *error` object indicating any errors, and a `NSString *calendarIdentifier` (if any) to indicate which calendar is being created/deleted.

### Events operation handler block
```objective-C
typedef void (^eventsOperationCompletionHandler)(BOOL success, NSError *error, NSString *eventIdentifier);
```
The block is called by event operation methods, such as create/update/delete events in the selected calendar.  It includes a `BOOL success` flag, a `NSError *error` object indicating any errors, and a `NSString *calendarIdentifier` (if any) to indicate the event being created/updated/deleted.

### Event search handler block
```objective-C
typedef void (^eventSearchHandler)(BOOL found, NSError *error, NSArray *eventsArray);
```
The block is called by event searching methods. It includes a `BOOL found` flag, a `NSError *error` object for any errors (`nil` if no errors), and an array of events that being found (`nil` if not found).

## Check/Request calendar permissions
**You MUST call `requestCalendarAccessWithCompletionHandler:` method before you do anything with calendar or events.**

You should prompt user for permissions or notify them that they should enable calendar access from the *Settings* app if they explicitly denied the access before. Example:
```objective-C
[manager requestCalendarAccessWithCompletionHandler:^(BOOL granted, NSError *error){
	if (granted) {
		NSLog("Granted by user when the system ask-for-permission prompt is shown. Or the user already granted permission before.");	
		//do something else here.
	}
	else{
		NSLog(@"%@",error);
		//do some error handling here.
		if ([error.domain isEqualToString:JSCalendarManagerErrorDomain]) {
			if (error.code == kErrorCalendarAccessNotGranted) {
				//do something, for example prompt an alert to user
				UIAlertView *alert = [UIAlertView alloc]initWithTitle:@"Needs calendar access" message:@"The app needs to access to your calendar. Please go the Settings app to turn on the permission." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
				[alert show];
			}
		}
	}];
```

There are also three methods you can use to check the calendar permissions your app has, and implement your own calendar permission logic based on returned value. The methods are pretty self explanatory.
```objective-C
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
```
**Note:** if the user has explicitly turned off the permisson to calendar before, you can use `shouldGrantAccessManually` method to check this, and prompt an alert view explaining the necessity of access to calendar and show instructions how to turn the permission back on.
```objective-C
	if([manager shouldGrantAccessManually]){
		UIAlertView *alert = [UIAlertView alloc]initWithTitle:@"Needs calendar access" message:@"The app needs to access to your calendar. Please go the Settings app to turn on the permission." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
		[alert show];
	}
```

## Calendar operations
### Creating a customized calendar for your app
You can create your own calendar for your app. There are two methods to do this.
```objective-C
/*!
 @method     createCalendar: iCloud: completionHandler:
 @discussion Call this method to create a calendar with the given title. The parameter iCloud indicates whether this calendar is on icloud.
 */
-(void)createCalendar:(NSString *)calendarTitle
			   iCloud:(BOOL)icloud
	completionHandler:(calendarOperationCompletionHandler)handler;
```
This method will creat a local/iCloud calendar with given name. You can also create a local calendar using 
```objective-C
/*!
 @method     createLocalCalendar: completionHandler:
 @discussion Call this method to create a local calendar with the given title.
 */
-(void)createLocalCalendar:(NSString *)calendarTitle
		 completionHandler:(calendarOperationCompletionHandler)handler;
```
The completion handler will include a `(NSString *)eventIdentifier`, you should be responsible for saving this identifier in your app for future use.

### Using existing calendars available in the database
#### Choose calendar to use with calendar identifier
If you saved the calendar identifier before, you can set the calendar you want to use using
```objective-C
[manager setUsingCalendar:KNOWN_CALENDAR_IDENTIFIER];
```
You **must** set the calendar you wish to use, otherwise the default calendar in your app will be used. 
If possible, we recommend creating your own calendar. Therefore, the user's other calendar will not be left alone, incase user accidentally deletes/messes their calendars/events.

#### Choose calendar from a list of available calendars
If you don't know the calendar identifier, don't worry, you can pull a list of calendars available on the device, and pick one or let user pick one.
```obejective-C
	NSArray *calendars = [manager allCalendars];
	for(EKCalendar *cal in calendars){
  		NSLog(@"%@",cal.calendarIdentifier);
  		//do something here.
	}
```  
## Events operations (create, update, and delete)
### Creating events
There are two ways to creat events in the calendar.

Both methods are self explanatory. The completion handler block returns a `NSString *eventIdentifier`, you are responsible to save this event identifier for future use, such as updating or deleting events. 
```objective-C
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
```
Typical use
```objective-C
[manager createEvent:eventName location:eventLocation startTime:start endTime:end description:description URL:url completionHandler:(BOOL success, NSError *error, NSString *eventIdentifier){
	if (success){
		NSLog(@"%@",eventIdentifier);
		//save the identifier or other stuff...
	}
	else{
		//error handling
	}
}];
```

### Updating events
#### Generic method
You can call the method below to update an event. You **must** have the `eventIdentifier` by your hand to update an event.
```objective-C
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
``` 

#### Updating single parameters
The class provides a few methods that only update single field (property) of an event for quick use.
``` objective-C
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
```

## TODO:
1. More documentation.
2. Add support for reminders.
3. Swift version.

## License
The MIT License (MIT)

Copyright (c) 2015 Jing Shan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
