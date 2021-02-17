#import "PXSequenceController.h"

@interface PXSequenceController (Delegates) <UITableViewDelegate, UITableViewDataSource>
@end

@implementation PXSequenceController (Delegates)
- (void)viewDidLoad {
	self.title = self.specifier.properties[@"label"];
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"Cell"];
	[self.view addSubview:self.tableView];
	
	self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
	[self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
	[self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
	[self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

	self.builder = [self parsedPreferenceValue];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.editing = YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	if (indexPath.section != 0) {
		cell.textLabel.text = [self localizedKeywordForNumber:[self buttonTypeForPath:indexPath].integerValue];
	} else {
		cell.textLabel.text = [self localizedKeywordForNumber:((NSString *)[self.builder objectAtIndex:indexPath.row]).integerValue];
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.builder removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
	} else if (editingStyle == UITableViewCellEditingStyleInsert) {
		NSString *text = [self buttonTypeForPath:indexPath];
		[self.builder addObject:text];

		NSIndexPath *newPath = [NSIndexPath indexPathForRow:self.builder.count - 1 inSection:0];
		[tableView insertRowsAtIndexPaths:@[ newPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	
	[self encodePreferenceValue];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	if (destinationIndexPath.row != sourceIndexPath.row) {
		NSString *sequenceData = [self.builder objectAtIndex:sourceIndexPath.row];
		
		[self.builder removeObjectAtIndex:sourceIndexPath.row];
		[self.builder insertObject:sequenceData atIndex:destinationIndexPath.row];
	}
	
	[self encodePreferenceValue];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"Current Sequence";
		default:
			return @"Available Options";
	}
}

- (NSString *)buttonTypeForPath:(NSIndexPath *)indexPath {
	// Logic for the builder section
	if (indexPath.section != 0) {
		switch (indexPath.row) {
			// Yes I know, same line case statements; it looks worse the normal way
			case 0: return [NSString stringWithFormat:@"%i", PXPhysicalButtonTypePower];
			case 1: return [NSString stringWithFormat:@"%i", PXPhysicalButtonTypeVolumeUp];
			case 2: return [NSString stringWithFormat:@"%i", PXPhysicalButtonTypeVolumeDown];
		}
	}

	// We need a default case so the compiler doesn't complain
	// 106 is the error button used for scenarios like this
	return [NSString stringWithFormat:@"%i", 106];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0: return self.builder.count;
		default: return 3;
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 0: return UITableViewCellEditingStyleDelete;
		default: return UITableViewCellEditingStyleInsert;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}
@end