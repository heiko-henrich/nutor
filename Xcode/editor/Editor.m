//
//  Editor.m
//  Nu
//
//  Created by Heiko Henrich on 06.06.13.
//
//

#import "Editor.h"
#import "Nu.h"

@implementation TextStorageUndoManager
{
    NSDate *_lastChange;
    BOOL _undoEnded;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _lastChange = [NSDate date];
        _groupingTime = 1.0;
        [self setGroupsByEvent:NO];
        [self beginUndoGrouping];
    }
    return self;
}

- (void) closeAllGroups
{
    for (NSInteger i = self.groupingLevel; i > 0; i--)
    {
        [self endUndoGrouping];
    }
}

- (void)groupByIdleTime
{
    if ([_lastChange timeIntervalSinceNow] < -self.groupingTime) {
        [self endUndoGrouping];
        [self beginUndoGrouping];
    }
    _lastChange = [NSDate date];
}

- (void) groupForSure
{
    _lastChange = [NSDate distantPast];
}

- (void)undo{
    [self closeAllGroups];
    [super undo];

}

- (void)redo
{
    [self closeAllGroups];
    [super redo];
}

@end


@implementation NuSourceStorage
{
    NSMutableAttributedString *_attrString;
    BOOL _shouldStartUndoGroup;
}
@synthesize defaultAttributes = _defaultAttributes;
@synthesize defaultFont = _defaultFont;
@synthesize parseJob = _parseJob;

- (void) setup
{
    _defaultAttributes = nil;
    _defaultFont = nil;
    _attrString = nil;
    _parseJob = nil;
    _fontSize = 11.0;
    _undoManager = [[TextStorageUndoManager alloc] init];
    _shouldStartUndoGroup = NO;
    _syntaxColorDictionary = @{@"character": [NSColor redColor],
                               @"number": [NSColor greenColor],
                               @"symbol": [NSColor colorWithCalibratedRed:0.33 green:0.5 blue:0.2 alpha:1.0],
                               @"label" : [NSColor brownColor],
                               @"operator": [NSColor blueColor],
                               @"macro" : [NSColor orangeColor],
                               @"object": [NSColor colorWithCalibratedRed:0.5 green:0.2 blue:0.6 alpha:1.0],
                               @"regex" : [NSColor colorWithCalibratedRed:0.9 green:0.06 blue:0.8 alpha:1.0],
                               @"string" : [NSColor colorWithDeviceRed:.8 green:0 blue:0 alpha:1.0]};
    _resultParserSetToUpdate = [[NSMutableOrderedSet alloc] init];
    _currentEvaluationErrors= nil;
    if ([self respondsToSelector:@selector(restoreDefaults)])
        [self restoreDefaults];
}

- (void)restoreDefaults
{
    
}

/* does not work yet
- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
        self.parseJob = [[NuParseJob alloc] initWithCoder:aDecoder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.parseJob];
}
*/
- (id)initWithString:(NSString *)str attributes:(NSDictionary *)attrs
{
    if (self = [super init])
    {
        [self setup];
        _attrString = [[[NSMutableAttributedString alloc] init] initWithString:str
                                                                attributes:attrs];
    }
    return self;
}

- (id)init
{
    self = [self initWithString:@"" attributes:self.defaultAttributes];
    return self;
}


static NSString *_stringWithSpaces;

+ (void)initialize
{
    NSMutableString * tempZeroString = [@"" mutableCopy];
    for (NSInteger i = 0; i < 256; i++) {
        [tempZeroString appendCharacter: ' '];
    }
    _stringWithSpaces = [NSString stringWithString:tempZeroString];
}

+ (NSString *) spaces: (NSInteger) count
{
    if (count > 256) count = 256;
    return [_stringWithSpaces substringToIndex:count];
}


- (void)setParseJob:(NuParseJob *)parseJob
{
    _parseJob = parseJob;
    if (!_attrString) {
        _attrString = [[NSMutableAttributedString alloc] initWithString:@"" attributes: self.defaultAttributes];
    }
    _parseJob.source = _attrString.mutableString;
    [_parseJob parse];
}

- (NuParseJob *)parseJob
{
    if (!_parseJob)
    {
        if (!_attrString) {
            _attrString = [[NSMutableAttributedString alloc] initWithString:@"" attributes: self.defaultAttributes];
        }
        _parseJob = [[NuParseJob alloc] initWithSource:_attrString.mutableString id:nil stamp:@"0"];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateResult:) name:@"ResultUpdate" object:_parseJob];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleEvaluationError:) name:@"EvaluationError" object:_parseJob];
        [_parseJob parse];
    }
    return _parseJob;
}

- (void)dealloc
{
    
    //NSLog(@"sourcestorage %@ deallocated", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSFont *)defaultFont
{
    if (!_defaultFont)
        _defaultFont = [NSFont fontWithName:@"Menlo Regular" size: self.fontSize];
    return _defaultFont;
}

- (NSDictionary *)defaultAttributes
{
    if (!_defaultAttributes)
        _defaultAttributes = @{NSFontAttributeName : self.defaultFont};
    return _defaultAttributes;
}

- (NSString *)string
{
    return [_attrString string];
}

- (NSUInteger)length
{
    return [_attrString length];
}

- (NSRange)range
{
    return NSMakeRange(0, _attrString.length);
}

- (NSDictionary *) lineInfoForLine: (NSInteger) line
{
    return [self lineInfoForLocation:[self.parseJob.lineInfo location:line]];
}

- (NSDictionary *) lineInfoForLocation: (NSInteger) location
{
    NSInteger line = [self.parseJob.lineInfo lineAt:location];
    NSInteger lineStart = [self.parseJob.lineInfo location:line];
    NSInteger lineEnd = [self.parseJob.lineInfo location:line + 1]-1;
    NSInteger codeStart = [self.parseJob.lineInfo codeIn:line];
    if (codeStart == NSNotFound) codeStart = lineEnd;
    return @{@"line":@(line),
             @"code":@(codeStart),
             @"start": @(lineStart),
             @"end":@(lineEnd)};
}



- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    if (location > self.length)
    {
        NSLog(@"location our of bounds");
        return @{};
    }
    else
     return [_attrString attributesAtIndex:location effectiveRange:range];
 
}


- (void)undoReplaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    self.parseJob.preventEvaluation = YES;
    [self replaceCharactersInRange:range withString:string];
    self.parseJob.preventEvaluation = NO;
}


- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    if (range.location + range.length > self.length)
    {
        NSLog(@"range out of bounds");
        return;
    }
    [[self.undoManager prepareWithInvocationTarget:self]
          undoReplaceCharactersInRange:NSMakeRange(range.location, string.length)
                        withString:[[_attrString  string] substringWithRange:range]];
    
    [self.parseJob updateAt:range.location delete:range.length insert:string];
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:[string length] - range.length];
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    [_attrString setAttributes:self.defaultAttributes range:NSMakeRange(0, _attrString.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

- (void)setFontSize:(CGFloat)fontSize
{
    _fontSize = fontSize;
    _defaultAttributes = nil;
    _defaultFont = nil;
    if (_attrString)
    {
        [_attrString setAttributes:self.defaultAttributes range:NSMakeRange(0, _attrString.length)];
        [self edited:NSTextStorageEditedAttributes range:NSMakeRange(0, _attrString.length) changeInLength:0];
    }
}

- (void) processIndentDeltas
{
    @autoreleasepool {
        NuCell *indentDeltas = [self.parseJob indentDeltas];
        self.parseJob.indenting = YES;
        NuCell *indentList = (NuCell *)indentDeltas.cdr;
        //[self beginEditing];
        while (indentList && indentList != (NuCell *)[NSNull null])
        {
            NSInteger location = [[indentList.car car] integerValue];
            NSInteger delta = [[[indentList.car cdr] car] integerValue];
            if (delta < 0)
            {
                [self replaceCharactersInRange:NSMakeRange(location, -delta) withString:@""];
            }
            else if (delta > 0)
            {
                if (delta > 256) delta = 256;
                
                [self replaceCharactersInRange:NSMakeRange(location, 0) withString:[NuSourceStorage spaces: delta]];
            }
            indentList = indentList.cdr;    }
        self.parseJob.indenting = NO;
        //[self endEditing];
    }
}

- (void) updateResult: (NSNotification *) notification
{
    //NSLog(@"Notification %@", notification);
    if ([notification.name isEqualToString:@"ResultUpdate"])
    {
        //NSLog(@"ResultUpdate for %@", notification.userInfo[@"parser"]);
        [self.resultParserSetToUpdate addObject:notification.userInfo[@"parser"]];
    }
}

- (void) handleEvaluationError: (NSNotification *) notification
{
    if ([notification.name isEqualToString:@"EvaluationError"])
    {
        if (! self.currentEvaluationErrors)
            self.currentEvaluationErrors = [[NSMutableArray alloc]init];
        [self.currentEvaluationErrors addObject: notification.userInfo[@"error"] ];
        [self processSyntaxHighlightingWithErrors:YES];
        [self edited:NSTextStorageEditedAttributes range:self.range changeInLength:0];
    }
}

 
- (void) processTextChanges: (NSMutableArray *) changes
{
    [changes sortUsingComparator:^NSComparisonResult(TextChange * tc1, TextChange * tc2) {
        NSInteger first = tc1.location;
        NSInteger second = tc2.location;
        if ( first > second ) {
            return (NSComparisonResult)NSOrderedAscending;
        } else if ( first < second ) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }}];
    for (TextChange *tc in changes) {
        [self replaceCharactersInRange:tc.range withString:tc.string];
    }

}

- (void)processResults
{
    // do this only if there are not any result updates going on
    if (!self.parseJob.preventEvaluation)
    {
        //@autoreleasepool {
            NSMutableArray *changes = [[NSMutableArray alloc]init];
            NSMutableArray *parserArray = [[NSMutableArray alloc] init];
            
            // first checking, wether there are invalid results
            // and adding them to the to be updated parsers
            // optimizable
            for (NuObjectParser *parser in self.parseJob.rootParser.descendants) {
                if ([self.resultParserSetToUpdate containsObject:parser])
                    [parserArray addObject: parser];
                
                else if (parser.logEvaluationResultEnabled && !parser.resultIsValid) {
                    [parserArray addObject:parser];
                }
            }
            
            // for every parser to be updated, get the according update change
            for (id parser in parserArray)
            {
                [changes addObject:[parser proposedResultUpdate]];
            }
            
            // now the display parsers without corresponding result parsers should be removed
            NSMutableArray *parserCollection = self.parseJob.rootParser.descendants;
            NSMutableArray *superfuidDisplayParsers = [[NSMutableArray alloc]init];
            
            // first get all the display parsers
            for (NuObjectParser *parser in parserCollection)
            {
                if ([parser isKindOfClass:[NuResultDisplayParser class]])
                    [superfuidDisplayParsers addObject:parser];
            }
            
            // remove all display parsers in use
            // probably optimizable
            for (NuObjectParser *parser in parserCollection)
            {
                if (parser.logEvaluationResultEnabled)
                {
                    [superfuidDisplayParsers removeObject:[parser displayParser]];
                }
            }
            
            // ad this changes to the changes "batch"
            for (NuResultDisplayParser *dp in superfuidDisplayParsers) {
                [changes addObject:dp.removalTextChange];
            }
            
            // now batch process the text changes
            self.parseJob.preventEvaluation = YES;
            [self.undoManager beginUndoGrouping];
            [self processTextChanges:changes];
            
            
            // after that get all (only the new ones would be better) display parsers
            // and split them in to multiple lines (if they are single lined)
            // should and will be optimized.
            // this should be done in NuParseJob similar to indentation
            parserCollection = self.parseJob.rootParser.descendants;
            
            for (NuObjectParser* parser in parserCollection)
            {
                if ([parser isKindOfClass:[NuResultDisplayParser class]]
                    // this works most of the time,
                    // because the unsplitted ounes are often single lined
                    // an exception are herestrings, they don't get split this way.
                    && parser.line == parser.endLine)
                    [self splitLinesIn:parser];
            }
            
            [self.undoManager endUndoGrouping];
            
            // reset the result parser set.
            self.resultParserSetToUpdate = [[NSMutableOrderedSet alloc] init];
            self.parseJob.preventEvaluation = NO;
        //}
    }
}


- (NSColor *) syntayColorForType: (NSString *) type
{
    NSColor *color= _syntaxColorDictionary[type];
    return color ? color : [NSColor blackColor];
}

- (void) removeSyntaxHighlighting
{
    [_attrString addAttribute:NSForegroundColorAttributeName
                        value:[NSColor blackColor]
                        range:self.range];
}

- (void) removeErrorMarks
{
    [_attrString  removeAttribute:NSToolTipAttributeName range:NSMakeRange(0, self.length)];
    [_attrString  removeAttribute:NSUnderlineColorAttributeName range:NSMakeRange(0, self.length)];
    [_attrString  removeAttribute:NSUnderlineStyleAttributeName range:NSMakeRange(0, self.length)];
}

- (void) processSyntaxHighlightingWithErrors: (BOOL) highlightErrors
{
    [self beginEditing];
    [self removeSyntaxHighlighting];
    [self removeErrorMarks];
    NSMutableArray *parserCollection = self.parseJob.rootParser.descendants;
    [parserCollection addObject:self.parseJob.rootParser];
    NSMutableArray *errors = [[NSMutableArray alloc] init];
    for (NuObjectParser  *parser in parserCollection)
    {
        if (parser.atom)
        {
            //NSLog(@"color parser %@", parser);
            [_attrString  addAttribute: NSForegroundColorAttributeName
                          value:[self syntayColorForType:parser.type]
                          range:parser.range];
        }
        if (parser.error)
        {
            [errors addObject: parser.error];
        }
    }
    if (highlightErrors)
    {
        if (self.currentEvaluationErrors)
        {
            if (self.parseJob.currentExceptions)
                [errors addObjectsFromArray:self.currentEvaluationErrors];
            else
                self.currentEvaluationErrors = nil;
        }
        [errors sortUsingComparator:^NSComparisonResult(NuError *error1, NuError *error2) {
            NSInteger first = error1.parser.depth;
            NSInteger second = error2.parser.depth;
            if ( first < second ) {
                return (NSComparisonResult)NSOrderedAscending;
            } else if ( first > second ) {
                return (NSComparisonResult)NSOrderedDescending;
            } else {
                return (NSComparisonResult)NSOrderedSame;
            }
        }];
        for (NuError *error in errors) {
            NSRange range;
            NuObjectParser *parser = error.parser;
            
            if ([parser isKindOfClass:[NuEndOfFileParser class]])
            {
                NSInteger location;
                NSInteger length = parser.depth - 1;
                if (parser.previous)
                    location = parser.previous.end - length;
                else
                    location = parser.parent.location - length + 1;
                
                if (location + length > self.length )
                {
                    location = self.length - length;
                }
                if (location < 0)
                {
                    location = 0;
                    length = self.length;
                }
                range = NSMakeRange(location, length);
                
                //NSLog(@"range %li %li previous %@ parent %@",range.location, range.length, parser.previous, parser.parent);
                
                [_attrString  addAttribute: NSToolTipAttributeName
                                     value:[error.description cutAt:1000] // in some cases the description is just too long
                                     range:range];
                [_attrString  addAttribute: NSUnderlineStyleAttributeName
                                     value:@(NSUnderlineStyleDouble|NSUnderlinePatternSolid)
                                     range:range];
                [_attrString  addAttribute: NSUnderlineColorAttributeName
                                     value:[NSColor redColor]
                                     range:range];
                
            }
            else
            {
                range = error.range.location == NSNotFound ? parser.range : error.range;
                [_attrString  addAttribute: NSToolTipAttributeName
                                     value:error.description
                                     range:range];
                [_attrString  addAttribute: NSUnderlineStyleAttributeName
                                     value:@(NSUnderlineStyleDouble|NSUnderlinePatternSolid)
                                     range:range];
                [_attrString  addAttribute: NSUnderlineColorAttributeName
                                     value:[self syntayColorForType:parser.type]  
                                     range:range];
            }
        }
        [self endEditing];
    }
}

- (void) splitLinesIn: (NuObjectParser *) parser
{
}

@end

@implementation NuCodeEditor


+ newWithFrame:(NSRect)frameRect sourceStorage: (NuSourceStorage *) sourceStorage
{
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [sourceStorage addLayoutManager:layoutManager];
    NSTextContainer *textContainer = [[NSTextContainer alloc] init];
    [layoutManager addTextContainer:textContainer];
    NuCodeEditor *codeEditor = [[NuCodeEditor alloc] initWithFrame:frameRect textContainer:textContainer];

    return codeEditor;
}

- (void) setup
{
    if ([self.textStorage isKindOfClass:[NuSourceStorage class]])
    {
        [self setFont: [self.sourceStorage defaultFont]];
    }
    [self setEditable:YES];
    [self setAllowsUndo:NO];
    [self setSelectable:YES];
    [self setDrawsBackground:YES];
    [self setRichText:NO];
    [self setAutomaticDashSubstitutionEnabled:NO];
    [self setAutomaticQuoteSubstitutionEnabled:NO];
    _replaceTabs = YES;
    _tabLength = 4;
    _autoIndentEnabled = YES;
    _syntaxHighlightingEnabled = YES;
    _parensHighlightingEnabled = YES;
    _errorHighlightingEnabled = YES;
    _focusShadingEnabled = NO;
    _depthColoringEnabled = NO;
    _uncolorIndentationEnabled = NO;
    _autoCompletionEnabled = YES;
    _smartParensEnabled = YES;
    _currentListParser = nil;
    _legacyParserEnabled = NO;
    _numberDraggingEnabled = NO;
    _contextEditorsEnabled = YES;
    _liveEvaluationEnabled = YES;
    self.cdarIndent = 2.0;
    [self setUsesFindBar:YES];
    [self setUsesFindBar:YES];
    [self setIncrementalSearchingEnabled:YES];
    [self setAutomaticSpellingCorrectionEnabled:NO];
    [self setContinuousSpellCheckingEnabled:NO];
    [self setupWithNu];
}

// method to be overriddenby editor.nu
- (void) setupWithNu {}

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{
    self = [super initWithFrame:frameRect textContainer:container];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        
        if (![self.textStorage isKindOfClass:[NuSourceStorage class]])
        {
            [self.layoutManager replaceTextStorage:[[NuSourceStorage alloc] init] ];
            [self setup];
            [self.textContainer setContainerSize:NSMakeSize(20000, 20000)];
            [self.textContainer setWidthTracksTextView:NO];
            self.frame = NSMakeRect(0, 0, 3000, 3000);
        }

        
    }
    return self;
}


static NSDictionary *_neutralBackground;
static NSDictionary *_parensHighlight;
static NSMutableDictionary *_shadesOfGray;
static NSMutableDictionary *_rainbowColors;
static CGFloat _rainbowColorSaturation;
static NSInteger _rainbowColorSteps;
static NSInteger _rainbowColorOffset;

+ (void)initialize
{
    _rainbowColorSaturation = 0.08;
    _rainbowColorSteps = 7.0;
    _rainbowColorOffset = 5.0;
    _shadesOfGray = [[NSMutableDictionary alloc ]init];
    _rainbowColors = [[NSMutableDictionary alloc ]init];
}

+ (NSRange) notFoundRange {return NSMakeRange(NSNotFound, 0);}
/*
+ (NSInteger) deviceIndependentFlags {return NSDeviceIndependentModifierFlagsMask;}
*/

+ (NSDictionary *) neutralBackground
{
    if (!_neutralBackground) _neutralBackground = @{NSBackgroundColorAttributeName : [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.0] };
    return _neutralBackground;
}

+ (NSDictionary *) parensHighlight
{
    if (!_parensHighlight) _parensHighlight = @{NSBackgroundColorAttributeName : [NSColor colorWithCalibratedRed:1.0 green:0.90 blue:0.18 alpha:1.0]};
    return _parensHighlight;
}


+ (NSDictionary *) shadeOfGray: (NSInteger) level
{
    NSDictionary *gray;
    if (!(gray  = _shadesOfGray[@(level)]))
    {
        CGFloat cv = 1.0 - level * 0.05;
        gray = @{NSBackgroundColorAttributeName : [NSColor colorWithCalibratedRed:cv green:cv blue:cv alpha:1.0]};
        _shadesOfGray [@(level)] = gray;
    }
    return gray;
}

+ (NSDictionary *) rainbowColor: (NSInteger) level
{
    
    NSDictionary *color;
    if (!(color  = _rainbowColors[@(level)]))
    {
        CGFloat cv = ((level + _rainbowColorOffset) % _rainbowColorSteps) / (CGFloat)_rainbowColorSteps;
        color = @{NSBackgroundColorAttributeName : [NSColor colorWithCalibratedHue:cv saturation:_rainbowColorSaturation brightness:0.97 alpha:1.0]};
        _rainbowColors [@(level)] = color;
    }
    return color;
}

/*
- (void)complete:(id)sender
{
    //[self.sourceStorage.undoManager beginUndoGrouping];
    [super complete:sender];
    //[self.sourceStorage.undoManager endUndoGrouping];
}
*/

- (void) undoableSelectionChangeTo: (NSRange) range
{
    //NSLog(@"undoable sel from %li %li to %li %li", self.selectedRange.location, self.selectedRange.length, range.location, range.length);
    [[self.sourceStorage.undoManager prepareWithInvocationTarget:self] undoableSelectionChangeTo:self.selectedRange];
    [self setSelectedRange:range];
}

- (void) beginEditing
{    
    [self.sourceStorage.undoManager groupByIdleTime];
    [self.sourceStorage.undoManager beginUndoGrouping];
    [[self.sourceStorage.undoManager prepareWithInvocationTarget:self] undoableSelectionChangeTo:self.selectedRange];
    //self.sourceStorage.currentEvaluationErrors=nil;
    [self.sourceStorage beginEditing];
}

- (void) endEditing
{
    [self.sourceStorage endEditing];
    [self didChangeText];
    [self.sourceStorage.undoManager endUndoGrouping];
}

- (void) changeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)string
{
    [self beginEditing];
    [self.sourceStorage replaceCharactersInRange:affectedCharRange withString:string];
    [self endEditing];
}

/*  everything NSTextview inserts or deletes throug user interaction goes through this
    we use this as a way to inject programmatic changes as a reaction to user input */
- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)string
{
    
    if  ([super shouldChangeTextInRange:affectedCharRange replacementString:string]
         && (string = [self processChangesInRange: affectedCharRange string: string]) )
    {
        [self changeTextInRange:affectedCharRange replacementString:string];
    }
    return NO;
}

// to be overridden by editor.nu
// can return a possibly changed string
- (NSString *) processChangesInRange: (NSRange) affectedCharRange string: (NSString *)string { return string;}

// to be overridden by editor.nu
// can return a possibly changed location
- (NSRange) selectionShouldChange: (NSRange)charRange {return charRange;}

- (void) selectionDidChangeTo: (NSRange) range {}

- (void)setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag
{
    //NSLog(@"range %li %li affinity %li sts %hhi", charRange.location, charRange.length,affinity,stillSelectingFlag);
    if (!stillSelectingFlag)
        charRange = [self selectionShouldChange:charRange];
    [super setSelectedRange:charRange affinity:affinity stillSelecting:stillSelectingFlag];
    if (!stillSelectingFlag)
        [self selectionDidChangeTo: charRange];
    
}


// will be replaced by the variant written in Nu.
- (void) cursorRelatedColoring {}

/*
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedCharRange granularity:(NSSelectionGranularity)granularity
{
    
    return [super selectionRangeForProposedRange:proposedCharRange granularity:granularity];
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
    return [super completionsForPartialWordRange:charRange indexOfSelectedItem:index];
}

*/
- (void) whiteIndentationFor: (NuObjectParser *) parser
{
    LineInfo *lineInfo = self.sourceStorage.parseJob.lineInfo;
    for (NSInteger line = parser.line + 1; line <= parser.endLine; line++) {
        NSInteger start = [lineInfo location:line];
        if (start > 0) start --;
        NSInteger codeStart = [lineInfo codeIn:line];
        NSInteger lineEnd = [lineInfo location:line + 1] -1;
        if (codeStart > lineEnd) codeStart = lineEnd;
        [self.layoutManager setTemporaryAttributes: NuCodeEditor.neutralBackground
                                 forCharacterRange: NSMakeRange(start, codeStart - start)];
    }
}

- (void) shadeFocusFor: (NuObjectParser *) parser
{
    NSArray *parserStack = [self.sourceStorage.parseJob.rootParser parserStackAt:self.selectedRange.location];
    NSInteger topList = [parserStack[0] isKindOfClass:[NuListParser class]]? 0 : 1;
    for(NSInteger i = parserStack.count - 1; i >= topList; i--)
    {
        [self.layoutManager setTemporaryAttributes: [NuCodeEditor shadeOfGray:i - topList]
                                 forCharacterRange: [parserStack[i] range]];
    }
}

- (void) focus: (NuObjectParser *) parser level: (NSInteger) level
{
    [self focus:parser.parent  level: level + 1];
    [self.layoutManager setTemporaryAttributes: [NuCodeEditor shadeOfGray:level]
                                 forCharacterRange: parser.range];
}

- (void) colorDescendantsOf: (NuListParser *) parser
{
    NuObjectParser *child = parser.lastChild;
    while (child) {
        if ([child isKindOfClass:[NuListParser class]])
        {
            NuListParser *listParser= (NuListParser *)child;
            [self.layoutManager setTemporaryAttributes: [NuCodeEditor rainbowColor:listParser.depth]
                                     forCharacterRange: listParser.range];
            [self colorDescendantsOf:listParser];
        }
        child = child.previous;
    }
}

- (void) removeBackgroundColors
{
    [self.layoutManager setTemporaryAttributes: NuCodeEditor.neutralBackground
                             forCharacterRange: NSMakeRange(0, self.sourceStorage.length)];
}

- (void) highlightParensFor: (NuObjectParser *) currentParser
{
    if (![currentParser isKindOfClass:[NuListParser class]]) currentParser = currentParser.parent;
    if (currentParser == self.sourceStorage.parseJob.rootParser) return;
    [self.layoutManager setTemporaryAttributes: NuCodeEditor.parensHighlight
                             forCharacterRange: NSMakeRange(currentParser.location, [[[currentParser class] trigger] length])];
    [self.layoutManager setTemporaryAttributes: NuCodeEditor.parensHighlight
                             forCharacterRange: NSMakeRange(currentParser.end - 1, 1)];
}

- (void)setSourceStorage:(NuSourceStorage *)sourceStorage
{
    [self.layoutManager replaceTextStorage:sourceStorage];
    [self didChangeText];
}

- (NuSourceStorage *) sourceStorage
{
    if ([self.textStorage isKindOfClass:[NuSourceStorage class]])
        return (NuSourceStorage *)self.textStorage;
    else
        return nil;
}

- (IBAction)undo:(id)sender
{
    [self.sourceStorage.undoManager undo];

    if (self.syntaxHighlightingEnabled) [self.sourceStorage processSyntaxHighlightingWithErrors:self.errorHighlightingEnabled];
}

- (IBAction)redo:(id)sender
{
    [self.sourceStorage.undoManager redo];
    if (self.syntaxHighlightingEnabled) [self.sourceStorage processSyntaxHighlightingWithErrors:self.errorHighlightingEnabled];
}

/*
- (void)setMessage:(NSMutableString *)message
{
    _message = [message cutAt:400];
}
*/
- (void) setMessageForLocation: (NSNumber *) location
{
    
}

- (void) processChangesInSourceWithEval: (BOOL) eval
{
    [self.sourceStorage.undoManager beginUndoGrouping];
    //[self.sourceStorage removeSuperfluidDisplayParsers];
    if (eval && self.liveEvaluationEnabled) [self.sourceStorage.parseJob evaluateLiveParsers];
    [self.sourceStorage processResults];
    if (self.autoIndentEnabled) [self.sourceStorage processIndentDeltas];
    if (self.syntaxHighlightingEnabled) [self.sourceStorage processSyntaxHighlightingWithErrors:self.errorHighlightingEnabled];
    [self setMessageForLocation:@(self.selectedRange.location - 1)];
    [super didChangeText];
    [self.sourceStorage.undoManager endUndoGrouping];
}

- (void)didChangeText
{
    [self processChangesInSourceWithEval:YES];
}

- (void)setSyntaxHighlightingEnabled:(BOOL)syntaxHighlighting
{
    _syntaxHighlightingEnabled = syntaxHighlighting;
    [self.sourceStorage beginEditing];
    if (syntaxHighlighting) {
        [self.sourceStorage processSyntaxHighlightingWithErrors:self.errorHighlightingEnabled];
    }
    else
    {
        [self.sourceStorage removeSyntaxHighlighting];
    }
    [self.sourceStorage endEditing];
    [self setNeedsDisplay:YES];
}

- (void)setErrorHighlightingEnabled:(BOOL)errorHighlighting
{
    _errorHighlightingEnabled = errorHighlighting;
    [self.sourceStorage beginEditing];
    if (self.syntaxHighlightingEnabled) {
        [self.sourceStorage processSyntaxHighlightingWithErrors:self.errorHighlightingEnabled];
    }
    [self.sourceStorage endEditing];
    [self setNeedsDisplay:YES];
}

- (void)setAutoIndentEnabled:(BOOL)autoIndent
{
    _autoIndentEnabled = autoIndent;
    if (autoIndent)
    {
        [self didChangeText];
    }
}

- (void)setFontSize:(CGFloat)fontSize
{
    self.sourceStorage.fontSize = fontSize;
    [self didChangeText];
}

- (CGFloat)fontSize
{
    if (self.sourceStorage)
        return self.sourceStorage.fontSize;
    else
        return 11.0;
}

- (void)setDepthColoringEnabled:(BOOL)levelColoring
{
    _depthColoringEnabled = levelColoring;
    [self cursorRelatedColoring];
}

- (void)setLevelColorSaturation:(CGFloat)levelColorSaturation
{
    _rainbowColors = [[NSMutableDictionary alloc]init];
    _rainbowColorSaturation = levelColorSaturation;
    [self cursorRelatedColoring];
}

- (CGFloat)levelColorSaturation
{
    return _rainbowColorSaturation;
}

- (void)setLevelColorSteps:(NSInteger)levelColorSteps
{
    _rainbowColors = [[NSMutableDictionary alloc]init];
    _rainbowColorSteps = levelColorSteps > 0 ? levelColorSteps : 1 ;
    [self cursorRelatedColoring];
}

- (NSInteger)levelColorSteps
{
    return _rainbowColorSteps;
}

- (void) setLevelColorOffset:(NSInteger)levelColorOffset
{
    _rainbowColors = [[NSMutableDictionary alloc]init];
    _rainbowColorOffset = levelColorOffset;
    [self cursorRelatedColoring];
}

- (void)setFocusShadingEnabled:(BOOL)focusShading
{
    _focusShadingEnabled = focusShading;
    [self cursorRelatedColoring];
}

- (void)setUncolorIndentationEnabled:(BOOL)uncolorIndentation
{
    _uncolorIndentationEnabled = uncolorIndentation;
    [self cursorRelatedColoring];
}

- (void)setParensHighlightingEnabled:(BOOL)parensHighlighting
{
    _parensHighlightingEnabled = parensHighlighting;
    [self cursorRelatedColoring];
}

- (void)setCdarIndent:(CGFloat)cdarIndent

{
    if (self.sourceStorage.parseJob)
    {
        self.sourceStorage.parseJob.cdarIndent = (NSInteger)cdarIndent;
     
       [self.sourceStorage.parseJob indentAll];
        [self didChangeText];
    }
}

- (CGFloat)cdarIndent
{
    if (self.sourceStorage.parseJob)
    {
        return (CGFloat) self.sourceStorage.parseJob.cdarIndent;
    }
    else
        return 2.0;
}

- (void)setLegacyParserEnabled:(BOOL)legacyParser
{
    if (legacyParser != _legacyParserEnabled)
    {
        _legacyParserEnabled = legacyParser;
        if (legacyParser)
        {
            self.sourceStorage.parseJob.registry = [NuLegacyParserClassRegistry shared];
        }
        else
        {
            self.sourceStorage.parseJob.registry = [NuParserClassRegistry shared];
        }
        [self.sourceStorage.parseJob parse];
        [self didChangeText];
    }
}


@end
