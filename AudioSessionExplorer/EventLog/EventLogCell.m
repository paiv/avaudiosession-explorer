#import "EventLogCell.h"


@interface EventLogCell ()

@property (weak, nonatomic) IBOutlet UITextView* textView;

@end


@implementation EventLogCell

- (NSString *)entryText {
    return self.textView.text;
}

- (void)setEntryText:(NSString *)entryText {
    self.textView.text = entryText;
}

@end
