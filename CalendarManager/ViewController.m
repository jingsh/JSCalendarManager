//
//  ViewController.m
//  CalendarManager
//
//  Created by Jing Shan on 6/14/15.
//  Copyright (c) 2015 Jing Shan. All rights reserved.
//

#import "ViewController.h"
#import "JSCalendarManager.h"
#import "LoremIpsum.h"

@interface ViewController ()
@property(nonatomic,strong)NSMutableArray *events;
@property(nonatomic,strong)JSCalendarManager *calendarManager;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.events = [NSMutableArray array];
	self.calendarManager = [[JSCalendarManager alloc]init];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Tableview methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.events.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"CellIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}
	cell.textLabel.text = [[self.events objectAtIndex:indexPath.row]objectForKey:@"title"];
	cell.detailTextLabel.text = [[self.events objectAtIndex:indexPath.row]objectForKey:@"id"];
	return cell;
}

#pragma mark 
-(IBAction)addCalendar:(id)sender
{
	[self.calendarManager requestCalendarAccessWithCompletionHandler:^(BOOL granted, NSError *error){
		if (granted) {
			[self promptForCalendarNameWithCompletionHandler:^(BOOL success, NSError *error, NSString *calendarIdentifier){
				if (success) {
					NSLog(@"Calendar: %@ is created.",calendarIdentifier);
				}
				if (error) {
					NSLog(@"Error: %@",error);
				}
			}];
		}
	}];
}

-(IBAction)addRandomEvents:(id)sender
{
	NSString *title = [LoremIpsum wordsWithNumber:4];
	NSString *location = [LoremIpsum wordsWithNumber:2];
	NSDate *start = [LoremIpsum date];
	NSDate *end = [NSDate dateWithTimeInterval:3600 sinceDate:start];
	NSString *notes = [LoremIpsum paragraph];
	NSString *url = [[LoremIpsum URL]absoluteString];
	
	[self.calendarManager createEvent:title location:location startTime:start endTime:end description:notes URL:url completionHanlder:^(BOOL success, NSError *error, NSString *eventIdentifier){
		if (success) {
			NSDictionary *dict = @{@"title":title,@"id":eventIdentifier};
			NSLog(@"Event: %@ is created.",eventIdentifier);
			[self.events addObject:dict];
			[self.tableView reloadData];
		}
	}];
}

-(void)promptForCalendarNameWithCompletionHandler:(calendarOperationCompletionHandler)handler
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Create UCS Calendar" message:@"Please enter the name of the calendar you want to sync to. Press cancel button to sync to existing calendars." preferredStyle:UIAlertControllerStyleAlert];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *nameField){
		nameField.placeholder = @"Calendar name";
		[nameField addTarget:self action:@selector(calendarNameFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
	}];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
		UITextField *nameField = alertController.textFields.firstObject;
		NSString *name = nameField.text;
		[self.calendarManager createLocalCalendar:name completionHandler:handler];
	}];
	[alertController addAction:okAction];
	
	[self presentViewController:alertController animated:YES completion:nil];
}

-(void)calendarNameFieldDidChange:(id)sender
{
	UIAlertController *alert = (UIAlertController *)self.presentedViewController;
	if (alert) {
		UITextField *nameField = alert.textFields.firstObject;
		UIAlertAction *okAction = alert.actions.lastObject;
		okAction.enabled = !(nameField.text.length == 0);
	}
}
@end
