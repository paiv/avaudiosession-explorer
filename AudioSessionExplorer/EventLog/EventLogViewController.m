#import "EventLog.h"
#import "EventLogCell.h"
#import "EventLogViewController.h"


@implementation EventLogViewController

- (NSArray*)model {
    return EventLog.sharedEventLog.entriesArray;
}

- (IBAction)handleRefreshControl:(id)sender {
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.model.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventLogCell* cell = [tableView dequeueReusableCellWithIdentifier:@"eventcell" forIndexPath:indexPath];
    cell.entryText = self.model[indexPath.row];
    return cell;
}

@end
