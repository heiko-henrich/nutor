//
//  Document.m
//  NuEditor
//
//  Created by Heiko Henrich on 13.07.13.
//
//

#import "Document.h"
#import "Debugger.h"


@interface NuCell (editor)

- (NSString *) multilineStringValue; // as header for nubile

@end

@implementation NutorSplitView
{
    CGFloat _lastSplitViewSubViewLeftWidth;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setPosition:[self maxPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
    _lastSplitViewSubViewLeftWidth = 60.0;
    _secondViewHidden = YES;
    
    
    return self;
}

- (void)awakeFromNib
{
    _lastSplitViewSubViewLeftWidth = self.window.frame.size.width / 3.0 *  2.0;
}

- (void)showSecondPane
{
    if (_secondViewHidden) {
        [self setPosition:_lastSplitViewSubViewLeftWidth ofDividerAtIndex:0];
        _secondViewHidden = NO;
    }
}

- (void) hideSecondPane
{
    if (!_secondViewHidden)
    {
        _lastSplitViewSubViewLeftWidth = [[self.subviews objectAtIndex:0] frame].size.width;
        [self setPosition:[self maxPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
        _secondViewHidden = YES;
    }
}

@end

@implementation NutorDocument
{
    NSString *_loadedData;
}


- (id)init
{
    self = [super init];
    if (self) {
        _loadedData = @"";
        _autosaveForRealEnabled = NO;
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"document %@ deallocated", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)windowNibName
{
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    self.assistantEditorEnabled = NO;
    self.backTranslationEnabled = NO;
    self.codeView.legacyParserEnabled = NO;
    self.splitView.delegate = self;
    self.undoManager = (NSUndoManager *)self.editor.sourceStorage.undoManager;
    //[[NutorParser shared] setValue:self.editor forKey:[NSString stringWithFormat:@"<%@>", self.displayName]];
    [self restoreDefaults];
    [self.messageView setFont:[NSFont fontWithName:@"Arial" size:9.0]];
    [self loadDatatInEditor];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

+ (BOOL)autosavesDrafts
{
    return YES;
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSData *data =[self.editor.sourceStorage.string dataUsingEncoding:NSUTF8StringEncoding];
    [self unblockUserInteraction];
    return  data;
}

- (void) loadDatatInEditor
{
    if (self.editor.sourceStorage)
    {
        [self.editor.sourceStorage beginEditing];
        [self.editor.sourceStorage.undoManager disableUndoRegistration];
        [self.editor.sourceStorage replaceCharactersInRange:NSMakeRange(0, self.editor.sourceStorage.length) withString:_loadedData];
        [self.editor.sourceStorage.undoManager enableUndoRegistration];
        [self.editor.sourceStorage endEditing];
        [self.editor.sourceStorage.undoManager removeAllActions];
        [self.editor didChangeText];
    }
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{

    _loadedData = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self loadDatatInEditor];
    
    return YES;
}


- (void)splitViewDidResizeSubviews:(NSNotification *)notification
{
    if (self.assistantEditorEnabled )
    {
        CGFloat y = self.codeView.enclosingScrollView.documentVisibleRect.origin.y;
        [self.codeView scrollPoint:NSMakePoint(0, y)];
    }
}

- (void)setAssistantEditorEnabled:(BOOL)enabled
{
    if (enabled) {
        [self.splitView showSecondPane];
    }
    else
    {
        [self.splitView hideSecondPane];
    }
    _assistantEditorEnabled = !self.splitView.secondViewHidden;
}

- (BOOL)canAsynchronouslyWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation
{
    return YES;
}

-(void)saveToURL:(NSURL *)url
          ofType:(NSString *)typeName
forSaveOperation:(NSSaveOperationType)saveOperation
completionHandler:(void (^)(NSError *errorOrNil))completionHandler {
    
    // for debugging autosave
    //NSLog(@"sabe to url %@ %lu", url, (unsigned long)saveOperation);
    if (self.autosaveForRealEnabled &&
        saveOperation == NSAutosaveInPlaceOperation)
        saveOperation = NSSaveOperation;
    
    [super saveToURL:url ofType:typeName forSaveOperation: saveOperation completionHandler:completionHandler];
}

- (void)setBackTranslationEnabled:(BOOL)backTranslation
{
    if (backTranslation && !_backTranslationEnabled) {
        self.assistantEditorEnabled = YES;
        [self translateBack];
    }
    _backTranslationEnabled = backTranslation;
}

- (void)translateBack
{
    self.codeView.string = [self.editor.sourceStorage.parseJob.root.car multilineStringValue ];
    self.codeView.selectedRange = NSMakeRange(0, 0);
    [self.codeView didChangeText];
}

- (void)textDidChange:(NSNotification *)notification
{
    if (self.backTranslationEnabled) [self translateBack];
}

// this should go to document.nu
- (IBAction)eval:(id)sender {
    [self saveDocument:self];
    if (self.assistantEditorEnabled)
        self.backTranslationEnabled = NO;
    NutorParser *parser = (NutorParser *)[Nu sharedParser];
    id result;
    self.codeView.string = @"";
    NuParseJob *job;
    @try {
        if (self.editor.liveEvaluationEnabled)
        {
            job = self.editor.sourceStorage.parseJob;
        }
        else
        {
            [parser parse:self.editor.sourceStorage.string for:[self asNuExpression] stamp:[NSDate date]];
            job = parser.jobs [[self asNuExpression]];
            //[[NSNotificationCenter defaultCenter]addObserver:self.editor.sourceStorage selector:@selector(updateResult:) name:@"ResultUpdate" object:job];
        }
        [job prepareForEvaluation];
        result = [job.rootParser evalWithContext:parser.context];
    }
    @catch (NSException *exception) {
        result = exception; // should not happen.
    }
    @finally {
        //[self.editor.sourceStorage processResults];
        if (self.codeView)
        {
            if ([result respondsToSelector:@selector(asNuExpression)])
            {
                self.codeView.string = [result asNuExpression];
                [self.codeView.sourceStorage splitLinesIn:  self.codeView.sourceStorage.parseJob.rootParser];
            }
            else if (result)
            {
                self.codeView.string = [result description];
                
            }
            [self.codeView didChangeText];
        }
        self.editor.message = [result stringValue].mutableCopy;
        self.editor.sourceStorage.parseJob.preventEvaluation = YES;
        [self.editor didChangeText];
        self.editor.sourceStorage.parseJob.preventEvaluation = NO;
    }
}

- (NSUndoManager *)undoManager
{
    return (NSUndoManager *)self.editor.sourceStorage.undoManager;
}


- (IBAction)reparse:(id)sender {
    [self.editor.sourceStorage.parseJob parse];
    [self.editor didChangeText];
}

- (IBAction)toggleAssistantEditor:(id)sender {
    if (self.assistantEditorEnabled)
    {
        self.backTranslationEnabled = NO;
        self.assistantEditorEnabled = NO;
    }
    else
        self.assistantEditorEnabled = YES;
}

- (IBAction)performFindPanelAction:(id)sender {
    [self.editor performFindPanelAction:sender];
}

- (IBAction)toggleConsole:(id)sender {
}

- (IBAction)toggleGuide:(id)sender {}

- (IBAction)evalFocusParser:(id)sender {
}

- (IBAction)updateResults:(id)sender {
}

- (IBAction)toggleWindowOnTop:(id)sender {
}


- (IBAction)undoSegmentedControlAction:(id)sender {
    
    NSInteger clickedSegment = [sender selectedSegment];
    NSInteger clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
    if (clickedSegmentTag == 0) {
        [self.editor undo:sender];
    }
    else if (clickedSegmentTag == 1)
    {
        [self.editor redo:sender];
    }
}

- (IBAction)toggleOptionsDrawer:(id)sender {
    [[self.editor.window.drawers objectAtIndex: 0] toggle: self];
}

- (void) restoreDefaults
{
    
}

- (IBAction)customToolbarAction1:(id)sender {
}

- (IBAction)customToolbarAction2:(id)sender {
}

- (IBAction)customToolbarAction3:(id)sender {
}

- (IBAction)customToolbarAction4:(id)sender {
}

- (IBAction)customToolbarAction5:(id)sender {
}

- (IBAction)customToolbarAction6:(id)sender {
}

- (IBAction)customToolbarAction7:(id)sender {
}

- (IBAction)customToolbarAction8:(id)sender {
}

+ (NSDocument *) load: (NSURL *) url
{
    NSError *error;
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url
                                                                           display:YES
                                                                             error:&error];
    if (error)
        return nil;
    else
        return [[NSDocumentController sharedDocumentController] documentForURL:url.absoluteURL];
}

@end
