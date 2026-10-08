#import <Cocoa/Cocoa.h>
#import <sys/stat.h>

static NSColor *Ink(void) { return [NSColor colorWithSRGBRed:0.10 green:0.24 blue:0.21 alpha:1]; }
static NSColor *Muted(void) { return [NSColor colorWithSRGBRed:0.43 green:0.48 blue:0.45 alpha:1]; }
static NSColor *Paper(void) { return [NSColor colorWithSRGBRed:0.96 green:0.96 blue:0.93 alpha:1]; }
static NSColor *Line(void) { return [NSColor colorWithSRGBRed:0.86 green:0.89 blue:0.84 alpha:1]; }
static NSString *DayKey(NSDate *date) {
    NSDateFormatter *f = [NSDateFormatter new]; f.dateFormat = @"yyyy-MM-dd";
    f.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    return [f stringFromDate:date];
}

// An intentionally small, transparent spaced-repetition schedule; no background timer.
static NSDictionary *Schedule(NSDictionary *old, NSInteger rating, NSTimeInterval now, NSString *day) {
    NSInteger reps = [old[@"reps"] integerValue];
    double interval = [old[@"interval"] doubleValue];
    double delay;
    if (rating == 1) { reps = 0; interval = 0; delay = 60; }
    else if (rating == 2) { reps += 1; interval = MAX(1, interval * 1.3); delay = interval * 86400; }
    else { interval = reps == 0 ? 1 : (reps == 1 ? 3 : MAX(7, interval * 2.2)); reps += 1; interval = MIN(365, interval); delay = interval * 86400; }
    return @{@"reps":@(reps), @"interval":@(interval), @"due":@(now + delay),
             @"last":@(now), @"firstDay":old[@"firstDay"] ?: day,
             @"lapses":@([old[@"lapses"] integerValue] + (rating == 1 ? 1 : 0))};
}

static BOOL ValidWord(NSDictionary *w) {
    if (![w isKindOfClass:NSDictionary.class]) return NO;
    for (NSString *k in @[@"word", @"meaning", @"theme"]) {
        if (![w[k] isKindOfClass:NSString.class] || [w[k] length] == 0) return NO;
    }
    if ([w[@"word"] length] > 80 || [w[@"meaning"] length] > 300) return NO;
    for (NSString *k in @[@"pos", @"collocation", @"example"])
        if (w[k] && (![w[k] isKindOfClass:NSString.class] || [w[k] length] > 800)) return NO;
    return YES;
}

@interface Store : NSObject
@property NSMutableDictionary *state;
@property NSArray<NSDictionary *> *words;
@property NSString *path;
@property NSString *warning;
- (instancetype)initWithDirectory:(NSString *)directory deck:(NSArray *)deck;
- (BOOL)save:(NSError **)error;
- (NSMutableDictionary *)records;
- (NSMutableDictionary *)today;
- (NSArray *)themes;
- (NSDictionary *)wordForID:(NSString *)identifier;
- (NSDictionary *)nextWordForTheme:(NSString *)theme extra:(BOOL)extra excluding:(NSSet *)excluded;
- (NSInteger)dueCount:(NSString *)theme;
- (void)reloadWords:(NSArray *)deck;
@end

@implementation Store
- (instancetype)initWithDirectory:(NSString *)directory deck:(NSArray *)deck {
    self = [super init]; if (!self) return nil;
    self.path = [directory stringByAppendingPathComponent:@"progress.json"];
    NSError *dirError;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:&dirError]) self.warning = dirError.localizedDescription;
    NSData *data = [NSData dataWithContentsOfFile:self.path];
    id saved = data ? [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] : nil;
    BOOL valid = [saved isKindOfClass:NSMutableDictionary.class];
    if (valid) {
        valid = (!saved[@"records"] || [saved[@"records"] isKindOfClass:NSDictionary.class]) &&
                (!saved[@"days"] || [saved[@"days"] isKindOfClass:NSDictionary.class]) &&
                (!saved[@"custom"] || [saved[@"custom"] isKindOfClass:NSArray.class]);
    }
    if (valid) {
        for (id value in [saved[@"records"] allValues]) {
            if (![value isKindOfClass:NSDictionary.class]) { valid = NO; break; }
            for (NSString *key in @[@"reps", @"interval", @"due", @"last", @"lapses"])
                if (value[key] && ![value[key] isKindOfClass:NSNumber.class]) valid = NO;
        }
        for (id value in [saved[@"days"] allValues]) {
            if (![value isKindOfClass:NSDictionary.class] || (value[@"done"] && ![value[@"done"] isKindOfClass:NSArray.class]) || (value[@"attempts"] && ![value[@"attempts"] isKindOfClass:NSNumber.class])) valid = NO;
        }
        if (saved[@"goal"] && ![saved[@"goal"] isKindOfClass:NSNumber.class]) valid = NO;
        for (id word in saved[@"custom"]) if (!ValidWord(word)) valid = NO;
    }
    if (valid) self.state = saved;
    else {
        if (data) {
            NSString *backup = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"progress-recovered-%@.json", NSUUID.UUID.UUIDString]];
            NSError *backupError;
            if ([[NSFileManager defaultManager] moveItemAtPath:self.path toPath:backup error:&backupError])
                self.warning = [NSString stringWithFormat:@"原学习记录无法读取，已保留备份：%@", backup];
            else { self.warning = @"原学习记录无法读取，且无法保留备份。请检查目录权限。"; return nil; }
        }
        self.state = [@{@"version":@1, @"records":[NSMutableDictionary new], @"days":[NSMutableDictionary new], @"custom":[NSMutableArray new], @"goal":@20, @"pinned":@NO, @"theme":@"全部主题"} mutableCopy];
    }
    if (!self.state[@"records"]) self.state[@"records"] = [NSMutableDictionary new];
    if (!self.state[@"days"]) self.state[@"days"] = [NSMutableDictionary new];
    if (!self.state[@"custom"]) self.state[@"custom"] = [NSMutableArray new];
    NSInteger goal = [self.state[@"goal"] integerValue];
    self.state[@"goal"] = @(MIN(100, MAX(5, goal ?: 20)));
    if (![self.state[@"theme"] isKindOfClass:NSString.class]) self.state[@"theme"] = @"全部主题";
    if (![self.state[@"pinned"] isKindOfClass:NSNumber.class]) self.state[@"pinned"] = @NO;
    [self reloadWords:deck]; return self;
}
- (void)reloadWords:(NSArray *)deck {
    NSMutableArray *all = [NSMutableArray new]; NSMutableSet *ids = [NSMutableSet new];
    for (NSArray *list in @[deck ?: @[], self.state[@"custom"] ?: @[]]) {
        for (NSDictionary *word in list) {
            if (!ValidWord(word)) continue;
            NSString *identifier = [word[@"word"] lowercaseString];
            if ([ids containsObject:identifier]) continue;
            NSMutableDictionary *w = [word mutableCopy]; w[@"id"] = identifier;
            [all addObject:w]; [ids addObject:identifier];
        }
    }
    self.words = all;
}
- (NSMutableDictionary *)records { return self.state[@"records"]; }
- (NSMutableDictionary *)today {
    NSString *day = DayKey(NSDate.date);
    if (!self.state[@"days"][day]) self.state[@"days"][day] = [@{@"done":[NSMutableArray new], @"attempts":@0} mutableCopy];
    if (!self.state[@"days"][day][@"done"]) self.state[@"days"][day][@"done"] = [NSMutableArray new];
    return self.state[@"days"][day];
}
- (NSArray *)themes {
    NSMutableArray *result = [NSMutableArray arrayWithObject:@"全部主题"];
    for (NSDictionary *w in self.words) if (![result containsObject:w[@"theme"]]) [result addObject:w[@"theme"]];
    return result;
}
- (NSDictionary *)wordForID:(NSString *)identifier {
    if (![identifier isKindOfClass:NSString.class]) return nil;
    for (NSDictionary *w in self.words) if ([w[@"id"] isEqual:identifier]) return w;
    return nil;
}
- (NSArray *)eligible:(NSString *)theme {
    if ([theme isEqual:@"全部主题"]) return self.words;
    NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *w, NSDictionary *_) { return [w[@"theme"] isEqual:theme]; }];
    return [self.words filteredArrayUsingPredicate:p];
}
- (NSDictionary *)nextWordForTheme:(NSString *)theme extra:(BOOL)extra excluding:(NSSet *)excluded {
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSDictionary *dueWord; double earliest = DBL_MAX;
    NSArray *eligible = [self eligible:theme];
    for (NSDictionary *w in eligible) {
        if ([excluded containsObject:w[@"id"]]) continue;
        NSDictionary *r = self.records[w[@"id"]];
        if (r && [r[@"due"] doubleValue] <= now && [r[@"due"] doubleValue] < earliest) {
            dueWord = w; earliest = [r[@"due"] doubleValue];
        }
    }
    if (dueWord) return dueWord;
    if (!extra && [self.today[@"done"] count] >= [self.state[@"goal"] integerValue]) return nil;
    for (NSDictionary *w in eligible) if (!self.records[w[@"id"]] && ![excluded containsObject:w[@"id"]]) return w;
    return nil;
}
- (NSInteger)dueCount:(NSString *)theme {
    NSInteger n = 0; NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    for (NSDictionary *w in [self eligible:theme]) { NSDictionary *r = self.records[w[@"id"]]; if (r && [r[@"due"] doubleValue] <= now) n++; }
    return n;
}
- (BOOL)save:(NSError **)error {
    NSData *d = [NSJSONSerialization dataWithJSONObject:self.state options:NSJSONWritingPrettyPrinted error:error];
    if (!d || ![d writeToFile:self.path options:NSDataWritingAtomic error:error]) return NO;
    chmod(self.path.fileSystemRepresentation, 0600); return YES;
}
@end

@interface Canvas : NSView
@property NSColor *fill;
@property CGFloat radius;
@property BOOL border;
@end
@implementation Canvas
- (BOOL)isFlipped { return YES; }
- (void)drawRect:(NSRect)rect {
    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, .5, .5) xRadius:self.radius yRadius:self.radius];
    [self.fill ?: Paper() setFill]; [p fill];
    if (self.border) { [Line() setStroke]; p.lineWidth = 1; [p stroke]; }
}
@end

@interface CardButton : NSButton
@property BOOL primary;
@property BOOL quiet;
@end
@implementation CardButton
- (void)drawRect:(NSRect)rect {
    BOOL highlighted = self.cell.isHighlighted;
    NSColor *bg = self.primary ? Ink() : (self.quiet ? NSColor.clearColor : NSColor.whiteColor);
    if (highlighted) bg = [bg blendedColorWithFraction:0.15 ofColor:self.primary ? NSColor.whiteColor : Line()];
    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, .5, .5) xRadius:10 yRadius:10];
    [bg setFill]; [p fill];
    if (!self.primary && !self.quiet) { [Line() setStroke]; [p stroke]; }
    NSColor *color = self.primary ? NSColor.whiteColor : Ink();
    if (!self.enabled) color = Muted();
    NSDictionary *attributes = @{NSFontAttributeName:self.font ?: [NSFont systemFontOfSize:13 weight:NSFontWeightMedium], NSForegroundColorAttributeName:color};
    NSSize size = [self.title sizeWithAttributes:attributes];
    [self.title drawAtPoint:NSMakePoint((self.bounds.size.width-size.width)/2, (self.bounds.size.height-size.height)/2) withAttributes:attributes];
    if (self.window.firstResponder == self) { [[Ink() colorWithAlphaComponent:.5] setStroke]; NSBezierPath *focus = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 3, 3) xRadius:7 yRadius:7]; [focus stroke]; }
}
@end

@interface ProgressView : NSView
@property double fraction;
@end
@implementation ProgressView
- (void)drawRect:(NSRect)rect {
    NSBezierPath *track = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:2 yRadius:2]; [Line() setFill]; [track fill];
    if (self.fraction > 0) { NSRect r = self.bounds; r.size.width *= MIN(1, self.fraction); NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:r xRadius:2 yRadius:2]; [Ink() setFill]; [p fill]; }
}
@end

@class App;
@interface WordWindow : NSWindow
@property (weak) App *controller;
@end

@interface App : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate, NSSpeechSynthesizerDelegate>
@property Store *store;
@property NSArray *baseDeck;
@property WordWindow *window;
@property NSWindow *library;
@property NSTableView *table;
@property NSSearchField *search;
@property NSPopUpButton *libraryTheme;
@property NSTextField *libraryCount;
@property NSArray *filteredWords;
@property NSPopUpButton *theme;
@property NSPopUpButton *goal;
@property CardButton *pinButton;
@property CardButton *revealButton;
@property NSArray<CardButton *> *ratings;
@property CardButton *audioButton;
@property CardButton *exampleAudioButton;
@property NSTextField *progressLabel;
@property NSTextField *countLabel;
@property NSTextField *kindLabel;
@property NSTextField *wordLabel;
@property NSTextField *posLabel;
@property NSTextField *meaningLabel;
@property NSTextField *collocationLabel;
@property NSTextField *exampleLabel;
@property NSTextField *hintLabel;
@property NSTextField *footer;
@property ProgressView *bar;
@property Canvas *card;
@property NSDictionary *current;
@property BOOL revealed;
@property BOOL extra;
@property NSMutableSet *skipped;
@property NSDictionary *undoState;
@property NSString *undoID;
@property NSString *undoDay;
@property NSString *toast;
@property NSSpeechSynthesizer *speech;
@property NSString *voiceID;
- (void)flip:(id)sender;
- (void)rate:(id)sender;
- (void)undo:(id)sender;
- (void)speak:(id)sender;
- (void)chooseNext;
- (void)refresh;
@end

@implementation WordWindow
- (BOOL)canBecomeKeyWindow { return YES; }
- (void)keyDown:(NSEvent *)event {
    NSString *key = event.charactersIgnoringModifiers.lowercaseString;
    if (event.modifierFlags & NSEventModifierFlagCommand) { [super keyDown:event]; return; }
    if ([key isEqual:@" "] || event.keyCode == 36) { [self.controller flip:nil]; return; }
    if ([@[@"1", @"2", @"3"] containsObject:key] && self.controller.current && self.controller.revealed) {
        NSInteger n = key.integerValue; [self.controller rate:self.controller.ratings[n-1]]; return;
    }
    if ([key isEqual:@"s"]) { [self.controller speak:nil]; return; }
    [super keyDown:event];
}
@end

static NSTextField *Label(NSView *parent, NSRect frame, NSString *string, CGFloat size, NSColor *color, NSFontWeight weight) {
    NSTextField *l = [NSTextField wrappingLabelWithString:string]; l.frame = frame; l.font = [NSFont systemFontOfSize:size weight:weight];
    l.textColor = color; l.maximumNumberOfLines = 0; l.selectable = NO; l.lineBreakMode = NSLineBreakByWordWrapping; [parent addSubview:l]; return l;
}
static CardButton *Button(NSView *parent, NSRect frame, NSString *title, id target, SEL action, BOOL primary, BOOL quiet) {
    CardButton *b = [[CardButton alloc] initWithFrame:frame]; b.title = title; b.target = target; b.action = action; b.bordered = NO;
    b.primary = primary; b.quiet = quiet; b.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
    b.accessibilityLabel = title; [parent addSubview:b]; return b;
}

@implementation App
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSString *deckPath = [NSBundle.mainBundle pathForResource:@"words" ofType:@"json"];
    self.baseDeck = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:deckPath] options:0 error:nil];
    NSString *directory = [[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject.path stringByAppendingPathComponent:@"IELTSWordCard"];
    self.store = [[Store alloc] initWithDirectory:directory deck:self.baseDeck];
    if (!self.store || !self.store.words.count) { [self alert:@"词卡暂时无法打开" detail:@"请检查 App 资源和学习记录目录是否可读写。" ]; [NSApp terminate:nil]; return; }
    self.skipped = [NSMutableSet new];
    [self makeMenu]; [self buildWindow];
    NSDictionary *resume = [self.store wordForID:self.store.state[@"resumeID"]];
    NSString *theme = self.store.state[@"theme"];
    if ([self.store dueCount:theme] > 0) self.current = [self.store nextWordForTheme:theme extra:NO excluding:nil];
    else if (resume && ([theme isEqual:@"全部主题"] || [resume[@"theme"] isEqual:theme])) self.current = resume;
    else self.current = [self.store nextWordForTheme:self.theme.titleOfSelectedItem extra:NO excluding:self.skipped];
    [self refresh];
    [self.window makeKeyAndOrderFront:nil]; [NSApp activateIgnoringOtherApps:YES];
    if (self.store.warning) [self alert:@"学习记录提醒" detail:self.store.warning];
}
- (void)makeMenu {
    NSMenu *main = [NSMenu new];
    NSMenuItem *appItem = [NSMenuItem new]; [main addItem:appItem];
    NSMenu *appMenu = [NSMenu new]; appItem.submenu = appMenu;
    [self addMenu:appMenu title:@"关于雅思词卡" action:@selector(about:) key:@""];
    [appMenu addItem:NSMenuItem.separatorItem];
    NSMenuItem *hide = [appMenu addItemWithTitle:@"隐藏雅思词卡" action:@selector(hide:) keyEquivalent:@"h"]; hide.target = NSApp;
    [appMenu addItem:NSMenuItem.separatorItem];
    NSMenuItem *quit = [appMenu addItemWithTitle:@"退出雅思词卡" action:@selector(terminate:) keyEquivalent:@"q"]; quit.target = NSApp;
    NSMenuItem *study = [[NSMenuItem alloc] initWithTitle:@"学习" action:nil keyEquivalent:@""]; [main addItem:study];
    study.submenu = [NSMenu new];
    [self addMenu:study.submenu title:@"撤销上一次评分" action:@selector(undo:) key:@"z"];
    [self addMenu:study.submenu title:@"单词发音" action:@selector(speak:) key:@"s"];
    [self addMenu:study.submenu title:@"切换置顶" action:@selector(togglePin:) key:@"p"];
    [self addMenu:study.submenu title:@"查看 / 搜索词库…" action:@selector(showLibrary:) key:@"f"];
    [study.submenu addItem:NSMenuItem.separatorItem];
    [self addMenu:study.submenu title:@"导入自定义词表…" action:@selector(importWords:) key:@""];
    [self addMenu:study.submenu title:@"备份学习记录…" action:@selector(exportProgress:) key:@""];
    [self addMenu:study.submenu title:@"恢复学习记录…" action:@selector(restoreProgress:) key:@""];
    NSMenuItem *edit = [[NSMenuItem alloc] initWithTitle:@"编辑" action:nil keyEquivalent:@""]; [main addItem:edit]; edit.submenu = [NSMenu new];
    [edit.submenu addItemWithTitle:@"复制" action:@selector(copy:) keyEquivalent:@"c"];
    [edit.submenu addItemWithTitle:@"粘贴" action:@selector(paste:) keyEquivalent:@"v"];
    [edit.submenu addItemWithTitle:@"全选" action:@selector(selectAll:) keyEquivalent:@"a"];
    NSMenuItem *help = [[NSMenuItem alloc] initWithTitle:@"帮助" action:nil keyEquivalent:@""]; [main addItem:help]; help.submenu = [NSMenu new];
    [self addMenu:help.submenu title:@"使用说明" action:@selector(help:) key:@"?"];
    NSApp.mainMenu = main;
}
- (void)addMenu:(NSMenu *)menu title:(NSString *)title action:(SEL)action key:(NSString *)key {
    NSMenuItem *i = [menu addItemWithTitle:title action:action keyEquivalent:key]; i.target = self;
}
- (void)buildWindow {
    self.window = [[WordWindow alloc] initWithContentRect:NSMakeRect(0, 0, 364, 540) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskFullSizeContentView backing:NSBackingStoreBuffered defer:NO];
    self.window.controller = self; self.window.delegate = self; self.window.title = @"雅思词卡";
    self.window.titleVisibility = NSWindowTitleHidden; self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES; self.window.backgroundColor = Paper(); self.window.releasedWhenClosed = NO;
    self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    Canvas *root = [[Canvas alloc] initWithFrame:NSMakeRect(0, 0, 364, 540)]; root.fill = Paper(); self.window.contentView = root;
    Label(root, NSMakeRect(22, 43, 215, 25), @"IELTS  /  雅思词卡", 16, Ink(), NSFontWeightSemibold);
    self.pinButton = Button(root, NSMakeRect(265, 36, 54, 32), @"置顶", self, @selector(togglePin:), NO, YES);
    self.pinButton.toolTip = @"让词卡保持在其他窗口上方（⌘P）";
    Button(root, NSMakeRect(324, 36, 24, 32), @"•••", self, @selector(showOptions:), NO, YES).toolTip = @"词库、导入和备份";
    self.progressLabel = Label(root, NSMakeRect(22, 84, 180, 22), @"今日记住  0 / 20", 13, Ink(), NSFontWeightMedium);
    self.countLabel = Label(root, NSMakeRect(213, 85, 129, 20), @"", 11, Muted(), NSFontWeightRegular); self.countLabel.alignment = NSTextAlignmentRight;
    self.bar = [[ProgressView alloc] initWithFrame:NSMakeRect(22, 113, 320, 4)]; [root addSubview:self.bar];
    self.theme = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(17, 132, 192, 27) pullsDown:NO]; [self.theme addItemsWithTitles:self.store.themes];
    if ([self.store.themes containsObject:self.store.state[@"theme"]]) [self.theme selectItemWithTitle:self.store.state[@"theme"]];
    self.theme.font = [NSFont systemFontOfSize:12]; self.theme.target = self; self.theme.action = @selector(themeChanged:); self.theme.bordered = NO; self.theme.toolTip = @"按主题背词"; [root addSubview:self.theme];
    self.goal = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(246, 132, 101, 27) pullsDown:NO];
    for (NSNumber *g in @[@5, @10, @20, @30, @50, @100]) { [self.goal addItemWithTitle:[NSString stringWithFormat:@"目标 %@ 词", g]]; self.goal.lastItem.tag = g.integerValue; }
    [self.goal selectItemWithTag:[self.store.state[@"goal"] integerValue]];
    self.goal.bordered = NO; self.goal.font = [NSFont systemFontOfSize:11]; self.goal.target = self; self.goal.action = @selector(goalChanged:); [root addSubview:self.goal];
    self.card = [[Canvas alloc] initWithFrame:NSMakeRect(20, 177, 324, 252)]; self.card.fill = NSColor.whiteColor; self.card.radius = 16; self.card.border = YES; [root addSubview:self.card];
    self.kindLabel = Label(self.card, NSMakeRect(20, 17, 241, 18), @"", 11, Muted(), NSFontWeightMedium);
    self.audioButton = Button(self.card, NSMakeRect(276, 11, 34, 30), @"听", self, @selector(speak:), NO, YES); self.audioButton.toolTip = @"朗读单词（S / ⌘S）"; self.audioButton.accessibilityLabel = @"朗读单词";
    self.wordLabel = Label(self.card, NSMakeRect(20, 52, 284, 45), @"", 31, Ink(), NSFontWeightSemibold);
    self.posLabel = Label(self.card, NSMakeRect(20, 103, 284, 18), @"", 12, Muted(), NSFontWeightRegular);
    self.meaningLabel = Label(self.card, NSMakeRect(20, 130, 284, 40), @"", 17, Ink(), NSFontWeightMedium);
    self.collocationLabel = Label(self.card, NSMakeRect(20, 177, 284, 22), @"", 12, Ink(), NSFontWeightMedium);
    self.exampleLabel = Label(self.card, NSMakeRect(20, 204, 248, 40), @"", 12, Muted(), NSFontWeightRegular);
    self.exampleAudioButton = Button(self.card, NSMakeRect(279, 201, 29, 28), @"▶", self, @selector(speakExample:), NO, YES); self.exampleAudioButton.toolTip = @"朗读例句"; self.exampleAudioButton.accessibilityLabel = @"朗读例句";
    self.hintLabel = Label(self.card, NSMakeRect(20, 143, 284, 68), @"先回想中文意思\n再翻卡，给记忆一点时间。", 14, Muted(), NSFontWeightRegular);
    self.revealButton = Button(root, NSMakeRect(20, 445, 324, 43), @"查看释义  ↵", self, @selector(flip:), YES, NO);
    NSMutableArray *ratings = [NSMutableArray new];
    NSArray *titles = @[@"1  不认识", @"2  有点模糊", @"3  记住了"];
    for (NSInteger n = 0; n < 3; n++) { CardButton *b = Button(root, NSMakeRect(20+n*110, 445, 104, 43), titles[n], self, @selector(rate:), n == 2, NO); b.tag = n+1; [ratings addObject:b]; }
    self.ratings = ratings;
    self.footer = Label(root, NSMakeRect(22, 503, 320, 28), @"", 10, Muted(), NSFontWeightRegular); self.footer.alignment = NSTextAlignmentCenter;
    NSRect screen = NSScreen.mainScreen.visibleFrame;
    [self.window setFrameOrigin:NSMakePoint(NSMaxX(screen) - 388, NSMinY(screen) + 90)];
    [self.window setFrameAutosaveName:@"IELTSWordCardWindow"];
    // Recover if the saved position belongs to a monitor that is no longer attached.
    BOOL visible = NO;
    for (NSScreen *s in NSScreen.screens) if (NSIntersectsRect(NSInsetRect(self.window.frame, 40, 40), s.visibleFrame)) visible = YES;
    if (!visible) [self.window setFrameOrigin:NSMakePoint(NSMaxX(screen)-388, NSMinY(screen)+90)];
    [self applyPin];
}
- (void)alert:(NSString *)title detail:(NSString *)detail {
    NSAlert *a = [NSAlert new]; a.messageText = title; a.informativeText = detail; [a addButtonWithTitle:@"知道了"]; [a runModal];
}
- (BOOL)save {
    NSError *error; BOOL ok = [self.store save:&error];
    if (!ok) [self alert:@"进度暂时未保存" detail:[NSString stringWithFormat:@"%@\n请保留窗口，检查目录权限后再试。", error.localizedDescription]];
    return ok;
}
- (void)refresh {
    NSInteger done = [self.store.today[@"done"] count], goal = [self.store.state[@"goal"] integerValue];
    self.progressLabel.stringValue = [NSString stringWithFormat:@"今日记住  %ld / %ld", (long)done, (long)goal];
    self.countLabel.stringValue = [NSString stringWithFormat:@"%ld 待复习 · %ld 词", (long)[self.store dueCount:self.theme.titleOfSelectedItem], (long)self.store.words.count];
    self.bar.fraction = (double)done / goal; self.bar.needsDisplay = YES;
    BOOL has = self.current != nil;
    self.kindLabel.stringValue = has ? [NSString stringWithFormat:@"%@  ·  %@", self.store.records[self.current[@"id"]] ? @"复习" : @"新词", self.current[@"theme"]] : @"慢慢来，每次记住一点";
    self.wordLabel.stringValue = has ? self.current[@"word"] : (done >= goal ? @"今日目标完成" : @"暂时没有新卡");
    CGFloat fontSize = has ? ([self.current[@"word"] length] > 20 ? 23 : ([self.current[@"word"] length] > 16 ? 27 : 31)) : 24;
    self.wordLabel.font = [NSFont fontWithName:@"Georgia" size:fontSize] ?: [NSFont systemFontOfSize:fontSize weight:NSFontWeightSemibold];
    self.posLabel.stringValue = has ? (self.current[@"pos"] ?: @"") : @"进度已在本机保存";
    self.meaningLabel.stringValue = self.current[@"meaning"] ?: @"";
    self.collocationLabel.stringValue = self.current[@"collocation"] ?: @"";
    self.exampleLabel.stringValue = self.current[@"example"] ?: @"";
    self.wordLabel.toolTip = self.current[@"word"]; self.meaningLabel.toolTip = self.current[@"meaning"];
    self.collocationLabel.toolTip = self.current[@"collocation"]; self.exampleLabel.toolTip = self.current[@"example"];
    self.meaningLabel.hidden = !has || !self.revealed; self.collocationLabel.hidden = !has || !self.revealed; self.exampleLabel.hidden = !has || !self.revealed;
    self.exampleAudioButton.hidden = !has || !self.revealed || ![self.current[@"example"] length];
    self.audioButton.hidden = !has;
    self.hintLabel.hidden = has && self.revealed;
    self.hintLabel.stringValue = has ? @"先回想中文意思\n再翻卡，给记忆一点时间。" : @"到期卡片会优先出现。\n可以继续学新词，或打开词库挑选。";
    self.revealButton.hidden = has && self.revealed;
    self.revealButton.title = has ? @"查看释义  ↵" : @"继续学习 / 检查复习  ↵";
    for (CardButton *b in self.ratings) { b.hidden = !has || !self.revealed; b.needsDisplay = YES; }
    self.revealButton.needsDisplay = YES;
    self.footer.stringValue = self.toast ?: (self.revealed ? @"按 1 / 2 / 3 评分 · ⌘Z 撤销 · S 发音" : @"空格翻卡 · S 发音 · 关闭窗口即退出");
    [self.window makeFirstResponder:self.window];
}
- (void)chooseNext {
    self.current = [self.store nextWordForTheme:self.theme.titleOfSelectedItem extra:self.extra excluding:self.skipped];
    self.revealed = NO; self.store.state[@"resumeID"] = self.current[@"id"] ?: @"";
    [self save]; [self refresh];
}
- (void)flip:(id)sender {
    self.toast = nil;
    if (!self.current) { self.extra = YES; [self.skipped removeAllObjects]; [self chooseNext]; if (!self.current) { self.toast = @"当前主题暂无到期卡；可在词库挑选任意词"; [self refresh]; } return; }
    self.revealed = !self.revealed; [self refresh];
}
- (void)rate:(NSButton *)sender {
    if (!self.current || !self.revealed) return;
    NSInteger rating = sender.tag; if (rating < 1 || rating > 3) return;
    // Keep one small undo delta, independent of the size of imported word lists.
    NSDictionary *delta = @{@"record":self.store.records[self.current[@"id"]] ?: NSNull.null, @"day":self.store.today};
    NSData *snapshot = [NSJSONSerialization dataWithJSONObject:delta options:0 error:nil];
    self.undoState = [NSJSONSerialization JSONObjectWithData:snapshot options:NSJSONReadingMutableContainers error:nil];
    self.undoID = self.current[@"id"]; self.undoDay = DayKey(NSDate.date);
    self.store.records[self.current[@"id"]] = Schedule(self.store.records[self.current[@"id"]], rating, NSDate.date.timeIntervalSince1970, DayKey(NSDate.date));
    NSMutableDictionary *day = self.store.today; day[@"attempts"] = @([day[@"attempts"] integerValue]+1);
    if (rating > 1 && ![day[@"done"] containsObject:self.current[@"id"]]) [day[@"done"] addObject:self.current[@"id"]];
    [self.skipped removeAllObjects]; self.toast = rating == 1 ? @"已加入重练 · 1 分钟后可再检查复习" : (rating == 2 ? @"已保存 · 下次会更早复习" : @"已记住 · 自动安排下次复习");
    [self.speech stopSpeaking]; [self chooseNext];
}
- (void)undo:(id)sender {
    if (!self.undoState) { self.toast = @"还没有可撤销的评分"; [self refresh]; return; }
    if (![self.undoDay isEqual:DayKey(NSDate.date)]) { self.undoState = nil; self.toast = @"跨天后请直接复习该词"; [self refresh]; return; }
    if (self.undoState[@"record"] == NSNull.null) [self.store.records removeObjectForKey:self.undoID];
    else self.store.records[self.undoID] = self.undoState[@"record"];
    self.store.state[@"days"][self.undoDay] = self.undoState[@"day"];
    self.current = [self.store wordForID:self.undoID]; self.revealed = YES; self.undoState = nil;
    self.store.state[@"resumeID"] = self.current[@"id"] ?: @""; self.toast = @"已撤销，可重新评分";
    [self save]; [self refresh];
}
- (void)speakText:(NSString *)text {
    if (!text.length) return;
    if (!self.voiceID) {
        NSString *voice;
        for (NSString *v in NSSpeechSynthesizer.availableVoices) {
            NSDictionary *attributes = [NSSpeechSynthesizer attributesForVoice:v];
            if ([attributes[NSVoiceName] isEqual:@"Daniel"]) { voice = v; break; }
            if (!voice && [attributes[NSVoiceLocaleIdentifier] hasPrefix:@"en_"]) voice = v;
        }
        self.voiceID = voice;
    }
    self.speech.delegate = nil;
    [self.speech stopSpeaking];
    self.speech = [[NSSpeechSynthesizer alloc] initWithVoice:self.voiceID];
    self.speech.delegate = self; self.speech.rate = 160;
    if (![self.speech startSpeakingString:text]) { self.toast = @"系统发音暂时不可用，可在系统设置检查英语语音"; [self refresh]; }
}
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finished {
    if (sender == self.speech) { sender.delegate = nil; self.speech = nil; }
}
- (void)speak:(id)sender { [self speakText:self.current[@"word"]]; }
- (void)speakExample:(id)sender { [self speakText:self.current[@"example"]]; }
- (void)themeChanged:(id)sender {
    self.store.state[@"theme"] = self.theme.titleOfSelectedItem; self.extra = NO; self.toast = nil; [self.skipped removeAllObjects]; [self chooseNext];
}
- (void)goalChanged:(id)sender { self.store.state[@"goal"] = @(self.goal.selectedItem.tag); self.toast = nil; self.extra = NO; [self save]; [self refresh]; }
- (void)applyPin {
    BOOL pin = [self.store.state[@"pinned"] boolValue]; self.window.level = pin ? NSFloatingWindowLevel : NSNormalWindowLevel;
    self.window.collectionBehavior = pin ? NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary : NSWindowCollectionBehaviorDefault;
    self.pinButton.title = pin ? @"已置顶" : @"置顶"; self.pinButton.needsDisplay = YES;
}
- (void)togglePin:(id)sender { self.store.state[@"pinned"] = @(![self.store.state[@"pinned"] boolValue]); [self applyPin]; [self save]; }
- (void)showOptions:(id)sender {
    NSMenu *menu = [NSMenu new];
    [self addMenu:menu title:@"查看 / 搜索词库…" action:@selector(showLibrary:) key:@""];
    [self addMenu:menu title:@"撤销上一次评分" action:@selector(undo:) key:@""];
    [menu addItem:NSMenuItem.separatorItem];
    [self addMenu:menu title:@"导入自定义词表…" action:@selector(importWords:) key:@""];
    [self addMenu:menu title:@"备份学习记录…" action:@selector(exportProgress:) key:@""];
    [self addMenu:menu title:@"恢复学习记录…" action:@selector(restoreProgress:) key:@""];
    [self addMenu:menu title:@"使用说明" action:@selector(help:) key:@""];
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, [sender bounds].size.height) inView:sender];
}
- (void)showLibrary:(id)sender {
    if (!self.library) {
        self.library = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 620, 480) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
        self.library.title = @"雅思词库"; self.library.releasedWhenClosed = NO; self.library.minSize = NSMakeSize(540, 380); self.library.delegate = self;
        Canvas *root = [[Canvas alloc] initWithFrame:NSMakeRect(0, 0, 620, 480)]; root.fill = Paper(); root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable; self.library.contentView = root;
        self.search = [[NSSearchField alloc] initWithFrame:NSMakeRect(20, 20, 380, 28)]; self.search.placeholderString = @"搜索英文 / 中文 / 搭配"; self.search.delegate = self;
        self.search.autoresizingMask = NSViewWidthSizable; [root addSubview:self.search];
        self.libraryTheme = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(416, 20, 184, 28)]; self.libraryTheme.target = self; self.libraryTheme.action = @selector(filterLibrary:);
        self.libraryTheme.autoresizingMask = NSViewMinXMargin; [root addSubview:self.libraryTheme];
        NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 65, 580, 335)]; scroll.hasVerticalScroller = YES; scroll.borderType = NSLineBorder; scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.table = [[NSTableView alloc] initWithFrame:scroll.bounds]; self.table.rowHeight = 34; self.table.dataSource = self; self.table.delegate = self; self.table.target = self; self.table.doubleAction = @selector(studySelected:);
        self.table.columnAutoresizingStyle = NSTableViewLastColumnOnlyAutoresizingStyle;
        NSArray *names = @[@"单词", @"释义", @"主题 / 进度"]; NSArray *keys = @[@"word", @"meaning", @"status"]; NSArray *widths = @[@170, @240, @150];
        for (NSInteger n = 0; n < 3; n++) { NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:keys[n]]; col.title = names[n]; col.width = [widths[n] doubleValue]; [self.table addTableColumn:col]; }
        scroll.documentView = self.table; [root addSubview:scroll];
        self.libraryCount = Label(root, NSMakeRect(22, 421, 365, 37), @"", 11, Muted(), NSFontWeightRegular); self.libraryCount.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;
        CardButton *start = Button(root, NSMakeRect(424, 417, 176, 40), @"开始背选中的词", self, @selector(studySelected:), YES, NO); start.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
        [self.library center];
    }
    [self.libraryTheme removeAllItems]; [self.libraryTheme addItemsWithTitles:self.store.themes];
    [self filterLibrary:nil]; [self.library makeKeyAndOrderFront:nil]; [self.library makeFirstResponder:self.search];
}
- (void)filterLibrary:(id)sender {
    NSString *query = [self.search.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *theme = self.libraryTheme.titleOfSelectedItem ?: @"全部主题";
    self.filteredWords = [self.store.words filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *w, NSDictionary *_) {
        if (![theme isEqual:@"全部主题"] && ![w[@"theme"] isEqual:theme]) return NO;
        if (!query.length) return YES;
        for (NSString *k in @[@"word", @"meaning", @"collocation"])
            if ([w[k] isKindOfClass:NSString.class] && [w[k] rangeOfString:query options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound) return YES;
        return NO;
    }]];
    [self.table reloadData];
    self.libraryCount.stringValue = [NSString stringWithFormat:@"%ld / %ld 词 · 双击即可背词\n自编主题入门词库，非官方完整词表", (long)self.filteredWords.count, (long)self.store.words.count];
}
- (void)controlTextDidChange:(NSNotification *)notification { if (notification.object == self.search) [self filterLibrary:nil]; }
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView { return self.filteredWords.count; }
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    NSTextField *l = [tableView makeViewWithIdentifier:column.identifier owner:self];
    if (!l) { l = [NSTextField labelWithString:@""]; l.identifier = column.identifier; l.font = [NSFont systemFontOfSize:12]; l.lineBreakMode = NSLineBreakByTruncatingTail; }
    NSDictionary *w = self.filteredWords[row]; NSString *value = w[column.identifier];
    if ([column.identifier isEqual:@"status"]) {
        NSDictionary *r = self.store.records[w[@"id"]];
        value = [NSString stringWithFormat:@"%@ · %@", w[@"theme"], r ? ([r[@"due"] doubleValue] <= NSDate.date.timeIntervalSince1970 ? @"待复习" : @"已学") : @"新词"];
    }
    l.stringValue = value ?: @""; l.textColor = Ink(); return l;
}
- (void)studySelected:(id)sender {
    NSInteger row = self.table.selectedRow; if (row < 0 || row >= self.filteredWords.count) return;
    self.current = self.filteredWords[row]; self.revealed = NO; self.toast = nil;
    [self.theme selectItemWithTitle:@"全部主题"]; self.store.state[@"theme"] = @"全部主题"; self.store.state[@"resumeID"] = self.current[@"id"];
    [self.library orderOut:nil]; [self.window makeKeyAndOrderFront:nil]; [self save]; [self refresh];
}
- (void)importWords:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel]; panel.allowedFileTypes = @[@"tsv", @"txt"]; panel.allowsMultipleSelection = NO; panel.message = @"导入 UTF-8 词表：英文、中文释义、词性、搭配、例句、主题（制表符分隔）";
    if ([panel runModal] != NSModalResponseOK) return;
    NSError *error; NSData *data = [NSData dataWithContentsOfURL:panel.URL options:0 error:&error];
    if (!data || data.length > 5*1024*1024) { [self alert:@"未导入" detail:error.localizedDescription ?: @"词表请控制在 5 MB 以内。" ]; return; }
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!text) { [self alert:@"未导入" detail:@"请使用 UTF-8 编码的 TSV / TXT 文件。" ]; return; }
    NSMutableArray *added = [NSMutableArray new]; NSMutableSet *known = [NSMutableSet new];
    for (NSDictionary *w in self.store.words) [known addObject:w[@"id"]];
    NSInteger skipped = 0;
    for (NSString *line in [text componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *trim = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!trim.length || [trim hasPrefix:@"#"]) continue;
        NSArray *c = [line componentsSeparatedByString:@"\t"];
        if (c.count < 2) { skipped++; continue; }
        NSMutableArray *fields = [NSMutableArray new];
        for (NSString *s in c) [fields addObject:[s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
        NSString *word = [fields[0] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\uFEFF"]];
        if ([@[@"word", @"英文", @"单词"] containsObject:word.lowercaseString]) continue;
        NSString *identifier = word.lowercaseString;
        NSDictionary *w = @{@"word":word, @"meaning":fields[1], @"pos":fields.count>2 ? fields[2] : @"", @"collocation":fields.count>3 ? fields[3] : @"", @"example":fields.count>4 ? fields[4] : @"", @"theme":fields.count>5 && [fields[5] length] ? fields[5] : @"我的词表", @"id":identifier};
        if (!ValidWord(w) || [known containsObject:identifier] || self.store.words.count+added.count >= 10000) { skipped++; continue; }
        [added addObject:w]; [known addObject:identifier];
    }
    [self.store.state[@"custom"] addObjectsFromArray:added]; [self.store reloadWords:self.baseDeck];
    NSString *selected = self.theme.titleOfSelectedItem; [self.theme removeAllItems]; [self.theme addItemsWithTitles:self.store.themes]; [self.theme selectItemWithTitle:selected];
    BOOL saved = [self save]; [self refresh];
    if (saved) [self alert:@"词表已导入" detail:[NSString stringWithFormat:@"新增 %ld 词，跳过 %ld 行（重复或格式不符）。\n可在主题菜单和词库中查看。", (long)added.count, (long)skipped]];
}
- (void)exportProgress:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel]; panel.allowedFileTypes = @[@"json"]; panel.nameFieldStringValue = [NSString stringWithFormat:@"雅思词卡备份-%@.json", DayKey(NSDate.date)];
    if ([panel runModal] != NSModalResponseOK) return;
    NSError *error; NSData *data = [NSJSONSerialization dataWithJSONObject:self.store.state options:NSJSONWritingPrettyPrinted error:&error];
    if (!data || ![data writeToURL:panel.URL options:NSDataWritingAtomic error:&error]) [self alert:@"备份失败" detail:error.localizedDescription];
    else { chmod(panel.URL.path.fileSystemRepresentation, 0600); self.toast = @"学习记录和自定义词表已备份"; [self refresh]; }
}
- (void)restoreProgress:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel]; panel.allowedFileTypes = @[@"json"]; panel.allowsMultipleSelection = NO; panel.message = @"选择雅思词卡备份；当前记录会先自动保留一份。";
    if ([panel runModal] != NSModalResponseOK) return;
    NSData *data = [NSData dataWithContentsOfURL:panel.URL];
    if (!data || data.length > 10*1024*1024) { [self alert:@"恢复失败" detail:@"备份无法读取或超过 10 MB。" ]; return; }
    NSString *scratch = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    [NSFileManager.defaultManager createDirectoryAtPath:scratch withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:nil];
    [data writeToFile:[scratch stringByAppendingPathComponent:@"progress.json"] atomically:YES];
    Store *candidate = [[Store alloc] initWithDirectory:scratch deck:self.baseDeck];
    [NSFileManager.defaultManager removeItemAtPath:scratch error:nil];
    if (!candidate || candidate.warning) { [self alert:@"恢复失败" detail:@"文件不是有效的雅思词卡备份。" ]; return; }
    // A bare JSON object is not a backup even though defaults could be applied to it.
    NSDictionary *raw = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![raw[@"version"] isEqual:@1] || !raw[@"records"] || !raw[@"days"] || !raw[@"custom"]) { [self alert:@"恢复失败" detail:@"请选择从雅思词卡导出的备份文件。" ]; return; }
    NSError *error; NSString *oldBackup = [self.store.path.stringByDeletingLastPathComponent stringByAppendingPathComponent:[NSString stringWithFormat:@"before-restore-%@.json", NSUUID.UUID.UUIDString]];
    NSData *oldData = [NSJSONSerialization dataWithJSONObject:self.store.state options:NSJSONWritingPrettyPrinted error:&error];
    if (!oldData || ![oldData writeToFile:oldBackup options:NSDataWritingAtomic error:&error]) { [self alert:@"恢复失败" detail:error.localizedDescription]; return; }
    chmod(oldBackup.fileSystemRepresentation, 0600);
    self.store.state = candidate.state; [self.store reloadWords:self.baseDeck]; self.undoState = nil;
    [self.theme removeAllItems]; [self.theme addItemsWithTitles:self.store.themes];
    [self.theme selectItemWithTitle:self.store.state[@"theme"]]; [self.goal selectItemWithTag:[self.store.state[@"goal"] integerValue]];
    [self applyPin]; self.extra = NO; [self.skipped removeAllObjects]; self.toast = @"已恢复备份，原记录也已保留"; [self chooseNext];
}
- (void)help:(id)sender {
    [self alert:@"一次一张，随时开始" detail:@"先回想词义，按空格翻卡，再用 1 / 2 / 3 评分。\n不认识：1 分钟后可重练；模糊：更早复习；记住：逐步拉长间隔。到期复习优先出现。\n\nS 发音，⌘Z 撤销评分，⌘F 搜索词库，⌘P 置顶。今日目标按不重复的“模糊 / 记住”词计数。\n\n支持导入 UTF-8 TSV：英文、中文释义、词性、搭配、例句、主题，前两列必填。使用制表符分隔，重复词会跳过。\n\n学习记录只保存在本机。关闭词卡窗口即退出；再次双击桌面快捷方式继续。" ];
}
- (void)about:(id)sender {
    [self alert:@"雅思词卡 · 1.0" detail:[NSString stringWithFormat:@"一个轻量的 macOS 原生桌面词卡。\n内置 300 个自编主题入门词条，包含中文释义、搭配和例句；可导入自己的词表。\n\n词库用于雅思主题与学术词汇练习，并非官方完整词表。\n\n记录位置：%@", self.store.path]];
}
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.store && self.window && self.library != NSApp.keyWindow) [self refresh];
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag { [self.window makeKeyAndOrderFront:nil]; return YES; }
- (BOOL)windowShouldClose:(NSWindow *)sender {
    if (sender == self.window) { if ([self save]) [NSApp terminate:nil]; return NO; }
    return YES;
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender { return [self save] ? NSTerminateNow : NSTerminateCancel; }
- (void)applicationWillTerminate:(NSNotification *)notification { [self.speech stopSpeaking]; }
@end

static int SelfTest(void) {
    int failures = 0;
    void (^check)(BOOL, NSString *) = ^(BOOL ok, NSString *name) { printf("%s %s\n", ok ? "PASS" : "FAIL", name.UTF8String); };
    #define CHECK(x, n) do { BOOL ok = (x); check(ok, n); if (!ok) failures++; } while(0)
    NSDictionary *first = Schedule(nil, 3, 1000, @"2026-10-08");
    CHECK([first[@"due"] doubleValue] == 87400, @"remembered new card is due in one day");
    NSDictionary *second = Schedule(first, 3, 87400, @"2026-10-09");
    CHECK([second[@"interval"] doubleValue] == 3, @"second successful review uses three days");
    NSDictionary *again = Schedule(second, 1, 500000, @"2026-10-10");
    CHECK([again[@"due"] doubleValue] == 500060 && [again[@"reps"] integerValue] == 0, @"forgotten card returns after 60 seconds");
    NSDictionary *hard = Schedule(nil, 2, 1000, @"2026-10-08");
    CHECK([hard[@"interval"] doubleValue] == 1, @"hard new card is due in one day");
    NSDictionary *capped = Schedule(@{@"reps":@15, @"interval":@300}, 3, 1000, @"2026-10-08");
    CHECK([capped[@"interval"] doubleValue] == 365, @"review interval is capped");
    NSArray *deck = @[@{@"word":@"assess", @"meaning":@"评估", @"theme":@"学术"}, @{@"word":@"habitat", @"meaning":@"栖息地", @"theme":@"环境"}];
    NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    Store *store = [[Store alloc] initWithDirectory:dir deck:deck];
    CHECK(store.words.count == 2 && [store.today[@"done"] count] == 0, @"first launch creates an empty local progress store");
    store.records[@"habitat"] = @{@"due":@0};
    CHECK([[store nextWordForTheme:@"全部主题" extra:NO excluding:nil][@"id"] isEqual:@"habitat"], @"due review is prioritised over new cards");
    CHECK([[store nextWordForTheme:@"学术" extra:NO excluding:nil][@"id"] isEqual:@"assess"], @"theme selection filters the queue");
    store.state[@"goal"] = @5;
    [store.today[@"done"] addObjectsFromArray:@[@"a", @"b", @"c", @"d", @"e"]];
    CHECK([store nextWordForTheme:@"学术" extra:NO excluding:nil] == nil, @"new cards stop at the daily target");
    CHECK([store nextWordForTheme:@"学术" extra:YES excluding:nil] != nil, @"continue studying allows extra new cards");
    CHECK([store nextWordForTheme:@"学术" extra:YES excluding:[NSSet setWithObject:@"assess"]] == nil, @"exclusion is respected");
    NSError *error;
    CHECK([store save:&error], @"progress is saved atomically");
    Store *reopened = [[Store alloc] initWithDirectory:dir deck:deck];
    CHECK([reopened.today[@"done"] count] == 5 && reopened.records[@"habitat"] != nil, @"progress survives reopening");
    NSString *today = DayKey(NSDate.date);
    reopened.state[@"days"] = [@{@"2000-01-01":[@{@"done":[NSMutableArray arrayWithObject:@"assess"]} mutableCopy]} mutableCopy];
    CHECK([reopened.today[@"done"] count] == 0 && [reopened.state[@"days"] objectForKey:today] != nil, @"a new calendar day has independent progress");
    [@"invalid json" writeToFile:store.path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    Store *recovered = [[Store alloc] initWithDirectory:dir deck:deck];
    CHECK(recovered.warning != nil && recovered.records.count == 0, @"corrupt progress is preserved before recovery");
    NSArray *files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir error:nil];
    CHECK(files.count == 1 && [files.firstObject hasPrefix:@"progress-recovered-"], @"recovery retains the original file");
    [NSFileManager.defaultManager removeItemAtPath:dir error:nil];
    printf("%d failures\n", failures); return failures ? 1 : 0;
}

static void MakeIcon(NSString *path) {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(1024, 1024)]; [image lockFocus];
    NSBezierPath *base = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(58, 58, 908, 908) xRadius:205 yRadius:205]; [Ink() setFill]; [base fill];
    NSAffineTransform *rotation = [NSAffineTransform transform]; [rotation translateXBy:512 yBy:512]; [rotation rotateByDegrees:-9]; [rotation translateXBy:-512 yBy:-512];
    [NSGraphicsContext saveGraphicsState]; [rotation concat];
    NSBezierPath *back = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(218, 223, 582, 578) xRadius:54 yRadius:54]; [[NSColor colorWithSRGBRed:.68 green:.80 blue:.59 alpha:1] setFill]; [back fill]; [NSGraphicsContext restoreGraphicsState];
    NSBezierPath *front = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(234, 232, 570, 582) xRadius:54 yRadius:54]; [Paper() setFill]; [front fill];
    [@"Aa" drawAtPoint:NSMakePoint(331, 436) withAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Georgia" size:240], NSForegroundColorAttributeName:Ink()}];
    [Ink() setStroke]; NSBezierPath *rule = [NSBezierPath bezierPath]; rule.lineWidth=14; rule.lineCapStyle=NSLineCapStyleRound; [rule moveToPoint:NSMakePoint(339, 365)]; [rule lineToPoint:NSMakePoint(688, 365)]; [rule stroke];
    [image unlockFocus]; NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:image.TIFFRepresentation]; [[bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:path atomically:YES];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        umask(0077);
        if (argc > 1 && strcmp(argv[1], "--self-test") == 0) return SelfTest();
        [NSApplication sharedApplication];
        if (argc > 2 && strcmp(argv[1], "--make-icon") == 0) { MakeIcon([NSString stringWithUTF8String:argv[2]]); return 0; }
        NSApp.activationPolicy = NSApplicationActivationPolicyRegular;
        App *app = [App new]; NSApp.delegate = app; [NSApp run];
    }
    return 0;
}
