# JSCalendarManager
An Objective-C class for common calendar and events operations. Requires EventKit.framework.

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
JSCalendarManager *manager = [[JSCalendarManager alloc]init];
```
## Check calendar permissions
Be sure to call `requestCalendarAccessWithCompletionHandler:` method before you do anything with calendar operation or event operation.

There are also three methods you can use to check the calendar permissions your app has.
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

## Calendar operations
### Create a customize calendar
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

### Using availabe calendars
If you saved the calendar identifier before, you can set the calendar you want to use using
```objective-C
[manager setUsingCalendar:KNOWN_CALENDAR_IDENTIFIER];
```
You must set the calendar you wish to use, otherwise the default calendar in your app will be used. 
If possible, we recommend creat your own calendar, therefore, the user's other calendar will not be interfered, incase user accidentally deleted calendars/events they don't want to.

If you don't know the calendar identifier, don't worry, you can pull a list of calendars available on the device, and pick one or let user pick one.
```obejective-C
  NSArray *calendars = [manager allCalendars];
  for (EKCalendar *cal in calendars){
    NSLog(@"%@",cal.calendarIdentifier);
    //do something here.
  }
```  
