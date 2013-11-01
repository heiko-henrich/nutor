

#import "Parser.h"

@implementation  NutorParser

@synthesize jobs = _jobs;
@synthesize defaultJob = _defaultJob;

//static NutorParser *_shared;

+ (NutorParser *) shared
{
    /*
    if (!_shared)
        _shared = [[NutorParser alloc] init];
    return _shared;
     */
    return (NutorParser *)[Nu sharedParser];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _jobs = [[NSMutableDictionary alloc] init ];
        _defaultJob = nil;
    }
    return self;
}

- (void) reset
{
    _defaultJob = nil;
}

- (BOOL)incomplete
{
    return self.defaultJob.incomplete;
}

- (NSInteger) state
{
    return self.defaultJob.state;
}

- (id)parse:(NSString *)string
{
    NuCell *code ;
    // to get nush running properly there has to be a \n after each string
    string = [string stringByAppendingString:@"\n"];
    if (!self.defaultJob)
    {
        self.defaultJob = [[NuParseJob alloc] initWithSource:string.mutableCopy id: nil stamp:@"0"];
        code = [self.defaultJob parse];
    }
    else
    {
        //if (self.defaultJob.state == PARSE_HERESTRING || self.defaultJob.state == PARSE_REGEX)
        //    string = [@"\n" stringByAppendingString: string];
        code = [self.defaultJob updateAt:self.defaultJob.source.length delete:0 insert:string];
    }
    if (self.defaultJob.incomplete)
        return [NSNull null];
    else
        [self reset];
        return code;
}

- (id) parse:(NSString *)string asIfFromFilename:(const char *) filename;
{
    NSString* fname = [NSString stringWithCString:filename encoding:NSUTF8StringEncoding];
	return [self parse:string for:fname stamp:@"0"];
}

/*
-  (void) evalWithException: (NSMutableDictionary *) d
{
    
    @try {
        id code = d[@"code"];
        id result = [code evalWithContext:self.context];
        if(result) d[@"result"]= result;
        //        NSLog(@"Code %@ result %@", code, result);
        d[@"error"] = @(NO);
    }
    @catch (id exception) {
        d[@"result"]= exception;
        d[@"error"] = @(YES);
    }
    
}
*/

- (NuCell *)parse:(NSString *)string for:(NSString *)sourceID stamp:(id)stamp
{
    NuParseJob *job = self.jobs[sourceID];
    if (job) {
        // later, if a job is executed in a seperate thread, this thread could be cancelled
        job.stamp = stamp;
        job.source = string.mutableCopy;
    }
    else  {
        job = [[NuParseJob alloc] initWithSource:string.mutableCopy id: sourceID stamp:stamp];
        self.jobs [sourceID] = job;
    }
    @try {
        return [job parse];
    }
    @catch (NSException *exception) {
        // exceptions with ios emulator are a big sh...
        @throw exception;
    }
}

- (NuCell *) update: (NSString *) sourceID
                 at: (NSInteger) location
             delete: (NSInteger) deletionLength
             insert: (NSString *) string
              stamp: (NSString *) stamp
{
    NuParseJob *job = self.jobs[sourceID];
    if (job)
    {
        job.stamp = stamp;
        @try {
            
            return [job updateAt:location delete:deletionLength insert:string];
        }
        @catch (NSException *exception) {
            // exceptions with ios emulator suck ...
            return nil;
        }
    }
    else
    {
        @throw @"No job, no update.";
    }
}
/*
- (NuCell *)indentAt: (NSInteger)  location for:(NSString *)senderTag stamp:(NSString *)stamp
{
    NuParseJob *job = self.jobs[senderTag];
    if (job)
    {
        if (job.stamp == stamp)
        {
            @try {
                [job alignLineAt: location];
            }
            @catch (NSException *exception) {
                // exceptions with ios emu...
                return nil;
            }
            return [job indentDeltas];
        }
        else return nil;
    }
    else
    {
        @throw @"No job, no indent.";
    }

}
*/
static NSInteger _senderTagCounter = 0;

+ (NSString *)generateSourceID
{
    return [NSString stringWithFormat:@"P%li",(unsigned long)_senderTagCounter];
}



@end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation Nu (hack)

+ (void) initialize
{
    [Nu exchangeClassMethod:@selector(oldParser) withMethod:@selector(parser)];
    [Nu exchangeClassMethod:@selector(oldSharedParser) withMethod:@selector(sharedParser)];
}

+ (NuParser *)oldParser
{
    return [[NutorParser alloc] init];
}

+ (NuParser *)oldSharedParser
{
    static NuParser *sharedParser = nil;
    if (!sharedParser) {
        sharedParser = [[NutorParser alloc] init];
    }
    return sharedParser;
    
}

@end

@implementation Nu_alt_parse_operator

// parse operator; parses a string into Nu code objects
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id parser = [[NutorParser alloc] init] ;
    return [parser parse:[[cdr car] evalWithContext:context]];
}

@end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TextChange

- (id)init
{
    if (self = [super init])
    {
        _location = NSNotFound;
        _length = 0;
        _string = nil;
    }
    return self;
}

- (id)initWithLocation: (NSInteger) location
                length: (NSInteger) length
                string: (NSMutableString *) string
{
    if (self = [super init])
    {
        _location = location;
        _length = length;
        _string = string;
    }
    return self;
}



- (id)initWithRange: (NSRange) range
             string: (NSMutableString
                      *) string
{
    if (self = [super init])
    {
        self.range = range;
        _string = string;
    }
    return self;
}


+ (TextChange *) withLocation: (NSInteger) location
                       length: (NSInteger) length
                       string: (NSMutableString *) string
{
    return [[TextChange alloc] initWithLocation:location length:length string:string];
}

+ (TextChange *)withRange:(NSRange)range string:(NSMutableString *)string
{
    return [[TextChange alloc] initWithRange:range string:string];
}

- (NSRange)range {return NSMakeRange(_location, _length);}
- (void)setRange:(NSRange)range
{
    _location = range.location;
    _length = range.length;
}
- (NSInteger)end {return _location + _length;}
- (void) setEnd:(NSInteger)end
{
    if (_location != NSNotFound)
        _length = end - _location;
}

@end



@implementation LineInfo

@synthesize string = _string;
@synthesize lines = _lines;
@synthesize codes = _codes;
@synthesize indents = _indents;

- (id)initWithString: (NSString *) string
{
    self = [super init];
    if (self)
    {
        _string = string;
        _lines = [[NSMutableArray alloc] initWithCapacity:50];
        _codes = [[NSMutableArray alloc] initWithCapacity:50];
        _indents = [[NSMutableArray alloc] initWithCapacity:50];
    }
    return self;
}

- (LineInfo *) parse
{
    // not sure about this
    //@autoreleasepool {
        NSInteger lineStart = 0;
        NSInteger codeStart = 0;
        BOOL indent = YES;
        for (NSInteger i = 0; i < _string.length; i++) {
            unichar c = [self characterAt: i];
            if (c == '\n') {
                [_lines addObject:@(lineStart)];
                [_indents addObject:@(NSNotFound)];
                if (indent)
                    [_codes addObject:@(NSNotFound)];
                else
                    [_codes addObject:@(codeStart)];
                lineStart = i + 1;
                codeStart = i + 1;
                indent = YES;
            }
            else if (indent && (c == ' ' || c == '\t'))
                codeStart ++;
            else indent = NO;
        }
        [_lines addObject:@(lineStart)];
        [_indents addObject:@(NSNotFound)];
        if (indent)
            [_codes addObject:@(NSNotFound)];
        else
            [_codes addObject:@(codeStart)];
        
        [_lines addObject:@(1 + _string.length)];
        [_indents addObject:@(NSNotFound)];
    [_codes addObject:@(NSNotFound)];
    //}
    return self;
}

- (NSInteger) count
{
    return _lines.count - 1;
}


-(unichar)characterAt:(NSInteger)i
{
    if (i < [_string length] )
    {
        //NSLog(@"char: %i index %i",[_string characterAtIndex:i], i );
        
        return [self.string characterAtIndex:i];
    }
    else return 0;
}



- (BOOL) is: (NSInteger) location in: (NSInteger) line
{
    return (location >= [_lines[line] integerValue] && location < [_lines[line + 1] integerValue]);
}

- (NSInteger) findLocation: (NSInteger) location between: (NSInteger) start and: (NSInteger) end
{
    if (start > end)
        return NSNotFound;
    NSInteger m = (start + end) / 2;
    if ([self is: location in: m])
        return m;
    NSInteger line = [self findLocation:location between:start and: m - 1];
    if (line != NSNotFound)
        return line;
    else
        return  [self findLocation:location between:m + 1 and: end];
}

- (NSInteger) lineAt: (NSInteger) location
{
    return [self findLocation: location between: 0 and: _lines.count - 2];
}

- (NSRange) linesInRange: (NSRange ) range
{
    NSInteger firstLine = [self lineAt:range.location];
    if (range.length == 0)
        return NSMakeRange(firstLine, 0);
    else
        return NSMakeRange(firstLine,
                           [self findLocation: range.location + range.length
                                      between: firstLine
                                          and: _lines.count - 2] - firstLine);
}

- (void) updateAt: (NSInteger) location  delete: (NSInteger) deletionLength  insert: (NSInteger) insertionLength
{
    //@autoreleasepool {
        NSInteger delta = insertionLength - deletionLength;
        NSRange deletedLines = [self linesInRange:NSMakeRange(location, deletionLength)];
        NSRange linesToRemove = NSMakeRange(deletedLines.location + 1, deletedLines.length);
        [_lines removeObjectsInRange:linesToRemove];
        [_codes removeObjectsInRange:linesToRemove];
        [_indents removeObjectsInRange:linesToRemove];
        
        for (NSInteger lineToMove = deletedLines.location + 1; lineToMove < _lines.count; lineToMove ++) {
            _lines[lineToMove] = @([_lines[lineToMove] integerValue] + delta);
            NSInteger codeStart = [_codes[lineToMove] integerValue];
            if (codeStart != NSNotFound)
                _codes[lineToMove] = @(codeStart + delta);
        }
        
        NSInteger lineIndex = deletedLines.location;
        
        NSInteger lineStart = [_lines[lineIndex] integerValue];
        NSInteger endLineStart = [_lines [deletedLines.location  + 1] integerValue];
        
        NSInteger codeStart = lineStart;
        BOOL indent = YES;
        for (NSInteger i = lineStart; i < endLineStart-1; i++) {
            unichar c = [self characterAt:i];
            if (c == '\n') {
                [_lines insertObject: @(NSNotFound) atIndex:lineIndex + 1];
                [_indents insertObject:@(NSNotFound) atIndex:lineIndex + 1];
                [_codes insertObject:@(NSNotFound) atIndex:lineIndex + 1];
                _lines [lineIndex] = @(lineStart);
                if (indent)
                    _codes [lineIndex] = @(NSNotFound);
                else
                    _codes [lineIndex] = @(codeStart);
                lineIndex ++;
                lineStart = i + 1;
                codeStart = i + 1;
                indent = YES;
            }
            else if (indent && (c == ' ' || c == '\t'))
                codeStart ++;
            else indent = NO;
        }
        _lines [lineIndex] = @(lineStart);
        if (indent)
            _codes [lineIndex] = @(NSNotFound);
        else
            _codes [lineIndex] = @(codeStart);
    //}
}

- (NSRange) range: (NSInteger) line
{
    if (line < 0 || line >= self.count) return NSMakeRange(NSNotFound, 0);
    NSInteger location = [_lines [line] integerValue];
    return NSMakeRange(location, [_lines [line + 1] integerValue ] - location);
}

- (NSRange) rangeAt: (NSInteger) location
{
    return [self rangeAt: [self lineAt: location]];
}

- (NSInteger) columnFor: (NSInteger) location in: (NSInteger) line
{
    if (line < 0 || line >= _lines.count || location > _string.length) return NSNotFound;
    return location - [_lines [line] integerValue];
}

- (NSArray *) lineColAt: (NSInteger) location
{    
    NSInteger line = [self lineAt: location];
    
    return @[@(line), @([self columnFor:location in:line])];
}
- (NSArray *) lineColForRange: (NSRange) range
{
    NSArray *start = [self lineColAt: range.location] ;
    NSArray *end = [self lineColAt:range.location + range.length];
    
    return @[ start[0], start[1] , end[0], end[1] ];
}

- (NSInteger) codeColumnIn: (NSInteger) line
{
    return [self columnFor:[_codes[line] integerValue] in:line ];
}

- (NSInteger) location: (NSInteger) line
{
    if (line >= _lines.count) return NSNotFound;
    else
        return [_lines[line] integerValue];
}

- (NSInteger) endOf: (NSInteger) line
{    
    if (line >= _lines.count -1) return NSNotFound;
    else
        return [_lines[line + 1] integerValue] - 1;

}

- (NSInteger) codeIn: (NSInteger) line
{
    if (line >= _codes.count - 1) return NSNotFound;
    else
        return [_codes[line] integerValue];

}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NSString (parser)

- (NSString *)cutAt: (NSInteger) i
{
    if (self.length > i)
        return [[self substringToIndex:i] stringByAppendingString:@"..."];
    else
        return self;
}

- (LineInfo *) lineInfo
{
    return [[[LineInfo alloc] initWithString:self] parse];
}

- (NuSymbol *) symbol
{
    return [[NuSymbolTable sharedSymbolTable] symbolWithString:self];
}


+ (NSString *) stringWithUnichar:(unichar) value {
    NSString *str = [NSString stringWithFormat: @"%C", value];
    return str;
}



@end

////////////////////////////////////////////////////////////////////////////////////////////////////
/*
@implementation NSNull(parser)

- (id)handleUnknownMessage:(id)cdr withContext:(NSMutableDictionary *)context
{
    NSLog(@"message sent to NSNull");
    return nil;
}

@end
*/
////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuError

- (id)init
{
    self = [super init];
    if (self)
    {
        _name = nil;
        _reason = nil;
        _userInfo = nil;
        _parser = nil;
        _sourceID =nil;
        _exception = nil;
        _stamp = nil;
    }
    return self;
}

+ (NuError *) errorWithName: (NSString *) name
                     reason: (NSString *) reason
                     parser: (NuObjectParser *) parser
                      range: (NSRange) range
                   sourceID: (id) sourceID
                      stamp: (id) stamp
{
    NuError *error = [[NuError alloc]init];
    error.name = name;
    error.reason = reason;
    error.parser = parser;
    error.range = range;
    error.sourceID  = sourceID;
    return error;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ : %@", self.name, self.reason];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuParseJob

@synthesize stamp = _stamp;
@synthesize rootParser = _rootParser;
@synthesize root = _root;
@synthesize lineInfo = _lineInfo;
@synthesize autoIndent = _autoIndent;
@synthesize cdarIndent = _cdarIndent;
@synthesize resultStamp = _resultStamp;
@synthesize sourceID = _sourceID;
@synthesize source = _source;

static NSString * _zerosString ;

+ (void)initialize
{
    NSMutableString * tempZeroString = [@"" mutableCopy];
    for (NSInteger i = 0; i < 256; i++) {
        [tempZeroString appendCharacter: '\0'];
    }
    _zerosString = [NSString stringWithString:tempZeroString];
}


- (id)init
{
    self = [super init];
    if (self)
    {
        _stamp = nil;
        _lineInfo = nil;
        _autoIndent = YES;
        _source = nil;
        _sourceID = nil;
        _cellProvider = nil;
        _indenting = NO;
        _preventEvaluation = NO;
        _cdarIndent = 2;
        _registry = [NuParserClassRegistry shared];
        _context = [[Nu sharedParser] context];
        _resultParsersToUpdate = [[NSMutableArray alloc] init];
        _currentExceptions = nil;
        _resultStamp = 0;
        _incomplete = NO;
        _state = PARSE_NORMAL;
    }
    return  self;
}
/* not working 
- (id)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    self.stamp = [coder decodeObjectForKey:@"stamp"];
    self.sourceID = [coder decodeObjectForKey:@"id"];
    self.source = [coder decodeObjectForKey:@"source"];
    return self;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
    [coder encodeObject:self.sourceID forKey:@"id"];
    [coder encodeObject:self.stamp forKey:@"stamp"];
    [coder encodeObject:self.source forKey:@"source"];
}
*/
- (void)setSource:(NSMutableString *)string
{
    _source = string;
    self.lineInfo = [[LineInfo alloc] initWithString:self.source];
    [self.lineInfo parse];
}

- (NSMutableString *)source
{
    return _source;
}

- (id) initWithSource: (NSMutableString *) string
                   id: (id) sourceID
                stamp: (id) stamp
{
    self = [self init];
    self.source = string;
    self.stamp = stamp;
    self.sourceID = sourceID;
    return self;
}


/* delegate method for rootParser*/
- (NuCell *)newCell
{
    return [[NuCell alloc] init];
}

- (NuCell *)newCellWithComments
{
    return [[NuCellWithComments alloc] init];
}

- (BOOL)autoIndent {return _autoIndent;}

- (void)setAutoIndent:(BOOL)autoIndent
{
    if (autoIndent && !_autoIndent)
    {
        _autoIndent = YES;
        [self.rootParser alignChildren];
    }
    else _autoIndent = autoIndent;
}

- (id <NuCellProvider>) cellProvider
{
    if (_cellProvider)
        return _cellProvider;
    else
        return self;    
}


- (NuCell *) parse
{
    if (!self.source) return nil;
    // probably not so good, to have a root parser as an instance varaible
    // produces a retain cycle
    self.rootParser = [[NuRootParser alloc] initWithJob:self
                                           cellProvider:[self cellProvider]
                                               registry:self.registry
                                            symbolTable:[NuSymbolTable sharedSymbolTable]];
    self.root = self.rootParser.cell;
    self.incomplete = NO;
    self.state = PARSE_NORMAL;
    //@autoreleasepool {
        
        
        [self.rootParser parse];
        //NSLog(@"rootparser %@", self.rootParser);
        //NSLog(@"self.root.car %@", self.root.car);
        if (self.autoIndent && !self.indenting)
        {
            [self.rootParser alignChildren];
        }
    //}
    return self.root.car;
    
}

- (NuCell *) updateAt: (NSInteger) location  delete: (NSInteger) deletionLength  insert: (NSString *) string
{
    // not sure with autorelease. I think the poo gets drained automatically at the end of RunLoop, when editor is idle 
    //@autoreleasepool {
        if (!self.source) return nil;
        if (location > self.source.length)
        {
            location = self.source.length;
            NSLog(@"error updating out of bounds");
        }
        [_source replaceCharactersInRange:NSMakeRange(location, deletionLength) withString:string];//
        [self.lineInfo updateAt: location delete: deletionLength insert: string.length];
        self.incomplete = NO;
        self.state = PARSE_NORMAL;
        NSRange affectedRange = [self.rootParser updateAt: location  deleted: deletionLength  inserted: string.length];
        
        if (self.autoIndent && !self.indenting)
        {
            NuObjectParser *affectedParser = [self.rootParser parserContaining:affectedRange];
            if (![affectedParser isKindOfClass:[NuListParser class]]) affectedParser = affectedParser.parent;
            while (affectedParser.parent && affectedParser.line == affectedParser.parent.line)  affectedParser = affectedParser.parent;
            //affectedParser = nil;
            if (!affectedParser) affectedParser = self.rootParser;
            [affectedParser alignChildren];
        }
        return self.root.car;
    //}
}


- (void) alignLineAt: (NSInteger) location
{
    NSInteger line = [self.lineInfo lineAt: location];
    NSInteger lineStart = [self.lineInfo location:line];
    if (lineStart <= 0)
        [self.rootParser alignChildren];
    else
    {
        // the top parser at the last newline is a list parser for sure (almost)
        NuObjectParser *parser = [self.rootParser parserAt: lineStart - 1];
        //NSLog(@"location %i linestart %i parser %@", location, lineStart, parser);
        [parser alignChildren];
    }
}

- (void)indent:(NSInteger)line to:(NSInteger)indentColumn
{
    if (indentColumn < 0) indentColumn = 0;
    //NSLog(@"Indent line %li to %li", line, indentLocation);
    self.lineInfo.indents[line] = @(indentColumn);
}

- (NSInteger) indentAt:(NSInteger)line
{
    return [self.lineInfo.indents[line] integerValue];
}

- (void) indentAll
{
    
    [self.rootParser alignChildren];
}

- (NuCell *) indentDeltas
{
    NuCell *deltas = [NuCell cellWithCar:@"indents".symbol cdr:[NSNull null]];
    NuCell *cursor = deltas;
    NSInteger count = self.lineInfo.indents.count;
    for (NSInteger line = count - 1;  line >= 0; line --)
    {
        NSInteger indent = [self indentAt:line];
        if (indent != NSNotFound)
        {
            NSInteger codeCol = [self.lineInfo codeColumnIn:line];
            if (codeCol == NSNotFound)
                codeCol = [self.lineInfo columnFor:[self.lineInfo location:line + 1] - 1 in:line];
            if (codeCol != indent) // NSNotFound case deleted
            {                
                cursor.cdr = [[NuCell alloc] init];
                cursor = cursor.cdr;
                cursor.car = [NuCell cellWithCar:@([self.lineInfo location: line])
                                             cdr:[NuCell cellWithCar:@(indent - codeCol)
                                                                 cdr:[NSNull null]]];
            }
            [self indent: line to: NSNotFound];
        }
    }
    return deltas;
}

- (void) evaluateLiveParsers
{
    if (!self.indenting && !self.preventEvaluation)
    {
        [self prepareForEvaluation];
        [self.rootParser.descendants enumerateObjectsWithOptions:NSEnumerationReverse  usingBlock:^(NuObjectParser *parser, NSUInteger idx, BOOL *stop) {
            if ([parser isKindOfClass:[NuLiveEvaluationParser class]] && ![parser error])
                [(NuLiveEvaluationParser *)parser evaluate];
        }];
    }
}

- (NSUInteger)resultStamp
{
    return ++ _resultStamp;
}

- (void)updateResultFor:(id)parser
{
    if (!self.indenting && !self.preventEvaluation)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ResultUpdate"
                                                            object:self
                                                          userInfo:@{@"parser": parser,
                                                                     @"time"  : [NSDate date],
                                                                     @"stamp" : @(self.resultStamp)}];
    }
    //[self.resultParsersToUpdate addObject:parser];
}

- (void)prepareForEvaluation
{
    _currentExceptions = nil;
}

- (void) exceptionHappened: (NuDebuggingException *) exception parser: (NuObjectParser *) parser
{
    if (!self.currentExceptions)
        self.currentExceptions = [[NSMutableDictionary alloc] init];
    if (!self.currentExceptions [exception])
    {
        self.currentExceptions [exception] = parser;
        
        NuError *error = [self error:@"Evaluation Error" parser:parser reason:exception.reason];
        error.exception = exception;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EvaluationError"
                                                            object:self
                                                          userInfo:@{@"parser": parser,
                                                                     @"error" : error,
                                                                     @"time"  : [NSDate date],
                                                                     @"stamp" : @(self.resultStamp)}];
    }
    
    
}

- (NSMutableSet *) symbolStrings
{
    NSMutableSet *sstrs = [[NSMutableSet alloc] init];
    NSArray *parserArray = self.rootParser.descendants;
    for (NuObjectParser *parser in parserArray)
    {
        if ([parser isKindOfClass:[NuSymbolAndNumberParser class]] && [parser.cell.car isKindOfClass:[NuSymbol class]])
        {
            [sstrs addObject:(((NuSymbol *)parser.cell.car).stringValue)];
        }
    }
    return sstrs;
}


- (NuError *) error: (NSString *) name  parser: (NuObjectParser *) parser reason: (NSString *) reason
{
    NuError *error =   [NuError errorWithName:name
                            reason:reason
                            parser:parser
                             range:NSMakeRange(NSNotFound, 0)
                          sourceID:self.sourceID
                             stamp:self.stamp];
    return error;
}
/*
- (NuError *) error: (NSString *) name
             parser: (NuObjectParser *) parser
              range: (NSRange) range
             reason: (NSString *) reason
{
    NuError *error =  [NuError errorWithName:name
                            reason:reason
                            parser:parser
                             range:range
                          sourceID:self.sourceID
                             stamp:self.stamp];
    return error;
}
*/

+ (NSString *)stringWithZeros
{
    return _zerosString;
}

- (NSString *)sourceAt: (NSInteger) location length: (NSInteger) length
{
    return [self sourceForRange: NSMakeRange(location, MAX(0, length))];
}

-(NSString *)sourceForRange:(NSRange)rangeInSource
{
    NSString *retStr;
    NSRange stringRange = NSMakeRange(0, self.source.length);
    NSRange intersection = NSIntersectionRange(stringRange, rangeInSource);
    if (NSEqualRanges(rangeInSource, intersection))
        // everything ok, requested range is in string;
        retStr = [self.source substringWithRange:intersection];
    else
    {
        // we append a string with zeros (I know, that's dirty)
        // this will give the parser a chance to match the end of File
        if (NuParseJob.stringWithZeros.length > rangeInSource.length - intersection.length)
            retStr = [[self.source substringWithRange:intersection]
                      stringByAppendingString:
                      [NuParseJob.stringWithZeros substringToIndex:rangeInSource.length - intersection.length]];
        else retStr = NuParseJob.stringWithZeros;
    }
    return retStr;
}


- (NSInteger)firstLocationOfCharactersInSet:(NSCharacterSet *)set starting:(NSInteger)location 
{
    //NSLog(@"search location %i", location);
    NSRange r = [self.source
                 rangeOfCharacterFromSet:set
                 options:  NSLiteralSearch
                 range: NSIntersectionRange (NSMakeRange(location, self.source.length),
                                             NSMakeRange(0, self.source.length))];
    if (r.location == NSNotFound) {
        r.location = self.source.length;
        r.length = 0;
    }
    //NSLog(@"found at %i", r.location);
    return r.location;
}

- (NSInteger)firstLocationOfCharactersInSet:(NSCharacterSet *)set backwardFrom:(NSInteger)location
{
    //NSLog(@"search location %i", location);
    NSRange r = [self.source
                 rangeOfCharacterFromSet:set
                 options:  NSBackwardsSearch
                 range: NSIntersectionRange (NSMakeRange(0, location),
                                             NSMakeRange(0, self.source.length))];
    if (r.location == NSNotFound) {
        r.location = 0;
        r.length = 0;
    }
    //NSLog(@"found at %i", r.location);
    return r.location;
}

- (NSRange) rangeOfString: (NSString *) string starting: (NSInteger) location
{
    //NSLog(@"search location %i", location);
    NSRange r = [self.source
                 rangeOfString:string
                 options: NSLiteralSearch
                 range: NSIntersectionRange (NSMakeRange(location, self.source.length),
                                             NSMakeRange(0, self.source.length))];
   /* if (r.location == NSNotFound) {
        r.location = self.source.length;
        r.length = 0;
    }*/
    //NSLog(@"found at %i", r.location);
    return r;
}


-(unichar)char:(NSInteger)i{
    return [self characterAt:i] ;
}

-(unichar)characterAt:(NSInteger)i
{
    if (i < [_source length] )
    {
        //NSLog(@"char: %i index %i",[_string characterAtIndex:i], i );
        
        return [self.source characterAtIndex:i];
    }
    else return 0;
}

static int nu_octal_digit_value(unichar c)
{
    int x = (c - '0');
    if ((x >= 0) && (x <= 7))
        return x;
    [NSException raise:@"NuParseError" format:@"invalid octal character: %C", c];
    return 0;
}

static unichar nu_hex_digit_value(unichar c)
{
    int x = (c - '0');
    if ((x >= 0) && (x <= 9))
        return x;
    x = (c - 'A');
    if ((x >= 0) && (x <= 5))
        return x + 10;
    x = (c - 'a');
    if ((x >= 0) && (x <= 5))
        return x + 10;
    [NSException raise:@"NuParseError" format:@"invalid hex character: %C", c];
    return 0;
}

static unichar nu_octal_digits_to_unichar(unichar c0, unichar c1, unichar c2)
{
    return nu_octal_digit_value(c0)*64 + nu_octal_digit_value(c1)*8 + nu_octal_digit_value(c2);
}

static unichar nu_hex_digits_to_unichar(unichar c1, unichar c2)
{
    return nu_hex_digit_value(c1)*16 + nu_hex_digit_value(c2);
}

static unichar nu_unicode_digits_to_unichar(unichar c1, unichar c2, unichar c3, unichar c4)
{
    unichar value = nu_hex_digit_value(c1)*4096 + nu_hex_digit_value(c2)*256 + nu_hex_digit_value(c3)*16 + nu_hex_digit_value(c4);
    return value;
}


-(NSInteger) parseEscapeAt:(NSInteger *)index
{
    unichar c = [self characterAt:++*index];
    if (c == 0)
    {
        [NSException raise:@"NuParseError" format:@"escape character at the end of source"];
        return 0;
    }
    switch(c) {
        case 'n': c=0x0a;  ++*index; break;
        case 'r': c=0x0d;  ++*index; break;
        case 'f': c=0x0c;  ++*index; break;
        case 't': c=0x09;  ++*index; break;
        case 'b': c=0x08;  ++*index; break;
        case 'a': c=0x07;  ++*index; break;
        case 'e': c=0x1b;  ++*index; break;
        case 's': c=0x20;  ++*index; break;
        case '0': case '1': case '2': case '3': case '4':
        case '5': case '6': case '7': case '8': case '9':
        {
            char c1 = [self characterAt:++*index];
            char c2 = [self characterAt:++*index];
            ++*index;
            c =nu_octal_digits_to_unichar(c, c1, c2);
            break;
        }
        case 'x':
        {
            char c1 = [self characterAt:++*index];
            char c2 = [self characterAt:++*index];
            ++*index;
            c = nu_hex_digits_to_unichar(c1, c2);
            break;
        }
        case 'u':
        {
            char c1 = [self characterAt:++*index];
            char c2 = [self characterAt:++*index];;
            char c3 = [self characterAt:++*index];;
            char c4 = [self characterAt:++*index];;
            ++*index;
            c=nu_unicode_digits_to_unichar(c1, c2, c3, c4);
            break;
        }
        case 'c': case 'C':
        {
            // control character.  Unsupported, fall through to default.
        }
        case 'M':
        {
            // meta character. Unsupported, fall through to
        }
        default:
            ++*index;
    }
    return c ;
}


- (NSString *) parseEscapesIn:(NSString *)string
{
    @try {
        NSMutableString *parsedString = [@"" mutableCopy];
        
        NSInteger i = 0;
        while (i < string.length) {
            
            unichar c = [string characterAtIndex:i];
            if (c == '\\' && i < string.length - 1)
            {
                
                c = [string characterAtIndex:++i];
                
                switch(c) {
                    case 'n': c=0x0a; break;
                    case 'r': c=0x0d; break;
                    case 'f': c=0x0c; break;
                    case 't': c=0x09; break;
                    case 'b': c=0x08; break;
                    case 'a': c=0x07; break;
                    case 'e': c=0x1b; break;
                    case 's': c=0x20; break;
                        
                    case '0': case '1': case '2': case '3': case '4':
                    case '5': case '6': case '7': case '8': case '9':
                    {
                        char c1 = [string characterAtIndex:++i];
                        char c2 = [string characterAtIndex:++i];
                        c =nu_octal_digits_to_unichar(c, c1, c2);
                        break;
                    }
                    case 'x':
                    {
                        char c1 = [string characterAtIndex:++i];
                        char c2 = [string characterAtIndex:++i];
                        c = nu_hex_digits_to_unichar(c1, c2);
                        break;
                    }
                    case 'u':
                    {
                        char c1 = [string characterAtIndex:++i];
                        char c2 = [string characterAtIndex:++i];;
                        char c3 = [string characterAtIndex:++i];;
                        char c4 = [string characterAtIndex:++i];;
                        c=nu_unicode_digits_to_unichar(c1, c2, c3, c4);
                        break;
                    }
                    case 'c': case 'C':
                    {
                        // control character.  Unsupported, fall through to default.
                    }
                    case 'M':
                    {
                        // meta character. Unsupported, fall through to
                    }
                }
            }
            i++;
            [parsedString appendCharacter:c];
        }
        return parsedString;
        
    }
    @catch (NSException *exception) {
        @throw exception;
    }
}

-(NSInteger) parseCharacterLiteralAt:(NSInteger *) index
{
    bool isACharacterLiteral = false;
    NSInteger characterLiteralValue = 0;
    if ([self characterAt:*index+1] != '\\') {
        if ([self characterAt:*index+2] == '\'') {
            isACharacterLiteral = true;
            characterLiteralValue = [self characterAt:*index+1];
            *index = *index + 3;
        }
        else if (isalnum([self characterAt:*index+1]) &&
                 isalnum([self characterAt:*index+2]) &&
                 isalnum([self characterAt:*index+3]) &&
                 isalnum([self characterAt:*index+4]) &&
                 ([self characterAt:*index+5] == '\'')) {
            characterLiteralValue =
            ((([self characterAt:*index+1]*256
               + [self characterAt:*index+2])*256
              + [self characterAt:*index+3])*256
             + [self characterAt:*index+4]);
            isACharacterLiteral = true;
            *index = *index + 6;
        }
    }
    else {
        // look for an escaped character
        ++*index;
        NSInteger escapechar = [self parseEscapeAt:index];
        isACharacterLiteral = true;
        if (([self characterAt:*index] == '\'')) {
            *index += 1; // move past the closing single-quote
        }
        else {
            [NSException raise:@"NuParseError" format:@"missing close quote from character literal"];
        }

        if (escapechar != NSNotFound) {
            characterLiteralValue = escapechar;
            // make sure that we have a closing single-quote
        }
        else
            [NSException raise:@"NuParseError" format:@"no valid character literal"];
    }
    
    if (!isACharacterLiteral) {
        return NSNotFound;
    }
    return characterLiteralValue;
}

+ (id) regexWithString: (NSString *) string
{
    // If the first character of the string is a forward slash, it's a regular expression literal.
    if (([string characterAtIndex:0] == '/') && ([string length] > 1)) {
        NSInteger lastSlash = [string length];
        NSInteger i = lastSlash-1;
        while (i > 0) {
            if ([string characterAtIndex:i] == '/') {
                lastSlash = i;
                break;
            }
            i--;
        }
        // characters after the last slash specify options.
        NSInteger options = 0;
        NSInteger j;
        for (j = lastSlash+1; j < [string length]; j++) {
            unichar c = [string characterAtIndex:j];
            switch (c) {
                case 'i': options += NSRegularExpressionCaseInsensitive; break;
                case 's': options += NSRegularExpressionDotMatchesLineSeparators; break;
                case 'x': options += NSRegularExpressionAllowCommentsAndWhitespace; break;
                case 'm': options += NSRegularExpressionAnchorsMatchLines; break; // multiline
                default:
                    [NSException raise:@"NuParseError" format:@"unsupported regular expression option character: %C", c];
            }
        }
        NSString *pattern = [string substringWithRange:NSMakeRange(1, lastSlash-1)];
        return [NSRegularExpression regularExpressionWithPattern:pattern
                                                         options:options
                                                           error:NULL];
    }
    else {
        return nil;
    }
}


@end


@implementation NuParserClassRegistry

static NuParserClassRegistry *_sharedRegistry = nil;

@synthesize dictionary = _dictionary;
@synthesize defaultParser =_defaultParser;


static NSCharacterSet * _nonWhiteSpaces;
static NSCharacterSet * _commentCharacters;
static NSCharacterSet * _endOfAtomCharacters;
static NSCharacterSet * _stringSpecialCharacters;
static NSCharacterSet * _interpolatingStringSpecialCharacters;
static NSCharacterSet * _interpolatingHeredocSpecialCharacters;
static NSCharacterSet * _neInterpolatingStringSpecialCharacters;
static NSCharacterSet * _neInterpolatingHeredocSpecialCharacters;
static NSCharacterSet * _endOfStringCharacters;
static NSCharacterSet * _nonWSbutNL;

+ (void) initialize
{
    _nonWSbutNL = [[NSCharacterSet characterSetWithCharactersInString:@" \t"] invertedSet];
    _nonWhiteSpaces = [[NSCharacterSet characterSetWithCharactersInString:@" \t\n\r"] invertedSet];
    _commentCharacters = [NSCharacterSet characterSetWithCharactersInString:@"#;"];
    _endOfAtomCharacters = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\"()[]{}|:.\0"];
    _stringSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\\n\"\0"];
    _interpolatingStringSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\\n\"\0#"];
    _interpolatingHeredocSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\\n\0#"];
    _neInterpolatingStringSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\n\"\0#"];
    _neInterpolatingHeredocSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\n\0#"];
    _endOfStringCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\n\"\0"];
}

+ (NSCharacterSet *) nonWhiteSpaces {return _nonWhiteSpaces;}
+ (NSCharacterSet *) commentCharacters {return _commentCharacters; }
+ (NSCharacterSet *) endOfAtomCharacters { return _endOfAtomCharacters; }
+ (NSCharacterSet *) stringSpecialCharacters { return _stringSpecialCharacters; }
+ (NSCharacterSet *) nonWSbutNL {return _nonWSbutNL;}

+ shared
{
    if (!_sharedRegistry) {
        _sharedRegistry = [[NuParserClassRegistry alloc] init];
    }
    return _sharedRegistry;
}

- (void) setup
{
    self.defaultParser = [NuSymbolAndNumberParser class];
    [self register:[NuListParser class]];
    [self register:[NuArrayParser class]];
    [self register:[NuEndOfFileParser class]];
    [self register:[NuEndOfArrayParser class]];
    [self register:[NuEndOfListParser class]];
    [self register:[NuEndOfBlockParser class]];
    [self register:[NuInterpolationStringParser class]];
    [self register:[NuNonescapedIpStringParser class]];
    [self register:[NuEscapedIpStringParser class]];
    [self register:[NuStringParser class]];
    [self register:[NuEscapedStringParser class]];
    [self register:[NuNonescapedStringParser class]];
    [self register:[NuHeredocParser class]];
    [self register:[NuQuoteAndCharacterParser class]];
    [self register:[NuDotParser class]];
    [self register:[NuColonParser class]];
    [self register:[NuArrowParser class]];
    [self register:[NuInterpolatingHeredocParser class]];
    [self register:[NuEscapedIpHeredocParser class]];
    [self register:[NuQuasiquoteParser class]];
    [self register:[NuQuasiquoteEvalParser class]];
    [self register:[NuQuasiquoteSpliceParser class]];
    [self register:[NuRegexParser class]];
    [self register:[NuIgnoreNextItemParser class]];
    [self register:[NuExtraneousParensParser class]];
    [self register:[NuExtraneousBracketsParser class]];
    [self register:[NuBlockParser class]];
    [self register:[NuInlineEvaluationParser class]];
    [self register:[NuLiveEvaluationParser class]];
    [self register:[NuPrefixResultLoggingParser class]];
    [self register:[NuPostfixResultLoggingParser class]];
    [self register:[NuTriggerForResultLoggingListParser class]];
    [self register:[NuResultDisplayParser class]];
    [self register:[NuLongSymbolParser class]];
    // special case, to get the symbol "/" and not a regex
    [self registerDefaultParserFor:@"/ "];
    [self registerDefaultParserFor:@"% "];
    // this is necessary to get <=, < and the NuLongSymbolParser
    // I can't stand these exceptions, ...
    [self registerDefaultParserFor:@"<= "];
    self.dictionary[@"<="] = [NuLongSymbolParser class];
    [self registerDefaultParserFor:@"< "];
    //[self registerDefaultParserFor:@".. "];
}

- (id)init
{
    self = [super init];
    if (self) {
        _dictionary = [[NSMutableDictionary alloc] init];
        [self setup];
    }
    return self;
}

- (void)register:(id)parserClass
{
    NSString *trigger = [parserClass trigger];
    self.dictionary [[parserClass trigger]] = parserClass ;
    for(NSInteger i = 1 ; i < trigger.length; i++)
    {
        // getParser looks first for shorter trigger strings
        // so to reach the longer ones, the shorter ones have to
        // be in the dictionary
        NSString *substring = [trigger substringToIndex:i];
        if (!self.dictionary [substring])
            [self registerDefaultParserFor: substring];
    }
}

- (void) registerDefaultParserFor: (NSString *) trigger
{
    self.dictionary [trigger] = self.defaultParser;
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuLegacyParserClassRegistry

static NuParserClassRegistry *_sharedLegacyRegistry = nil;

+ shared
{
    if (!_sharedLegacyRegistry) {
        _sharedLegacyRegistry = [[NuLegacyParserClassRegistry alloc] init];
    }
    return _sharedLegacyRegistry;
}

- (void)setup
{
    
    self.defaultParser = [NuSymbolAndNumberParser class];
    [self register:[NuListParser class]];
    [self register:[NuEndOfFileParser class]];
    [self register:[NuEndOfListParser class]];
    [self register:[NuLegacyStringParser class]];
    [self register:[NuLegacyEscapedStringParser class]];
    [self register:[NuLegacyNonescapedStringParser class]];
    [self register:[NuLegacyHeredocParser class]];
    [self register:[NuQuoteAndCharacterParser class]];
    [self register:[NuQuasiquoteParser class]];
    [self register:[NuQuasiquoteEvalParser class]];
    [self register:[NuQuasiquoteSpliceParser class]];
    [self register:[NuRegexParser class]];
    [self register:[NuExtraneousParensParser class]];
    [self register:[NuExtraneousBracketsParser class]];
    // special case, to get the symbol "/" and not a regex
    [self registerDefaultParserFor:@"/ "];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuCell (parser)

- (void)setParser:(NuObjectParser *)parser
{
    [self setAssignedAssociatedObject:parser forKey:@"parser"];
}

- (NuObjectParser *)parser
{
    return [self associatedObjectForKey:@"parser"];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuObjectParser
{
    NSArray *_lineCol;
    NSInteger _endLine;
}

@synthesize cell = _cell;
@synthesize location = _location;
@synthesize length = _length;
@synthesize parent = _parent;
@synthesize root = _root;
@synthesize comments = _comments;
@synthesize previous = _previous;
@synthesize cellIgnored = _cellIgnored;

/* moved to NuParserClassRegistry
static NSCharacterSet * _nonWhiteSpaces;
static NSCharacterSet * _commentCharacters;
static NSCharacterSet * _endOfAtomCharacters;
static NSCharacterSet * _stringSpecialCharacters;
static NSCharacterSet * _interpolatingStringSpecialCharacters;
static NSCharacterSet * _interpolatingHeredocSpecialCharacters;
static NSCharacterSet * _neInterpolatingStringSpecialCharacters;
static NSCharacterSet * _neInterpolatingHeredocSpecialCharacters;
static NSCharacterSet * _endOfStringCharacters;
static NSCharacterSet * _nonWSbutNL;

+ (void) initialize
{
    _nonWSbutNL = [[NSCharacterSet characterSetWithCharactersInString:@" \t"] invertedSet];
    _nonWhiteSpaces = [[NSCharacterSet characterSetWithCharactersInString:@" \t\n\r"] invertedSet];
    _commentCharacters = [NSCharacterSet characterSetWithCharactersInString:@"#;"];
    _endOfAtomCharacters = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\"()[]{}|:.\0"];
    _stringSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\\n\"\0"];
    _interpolatingStringSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\\n\"\0#"];
    _interpolatingHeredocSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\\n\0#"];
    _neInterpolatingStringSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\n\"\0#"];
    _neInterpolatingHeredocSpecialCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\n\0#"];
    _endOfStringCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\n\"\0"];
}
*/

// will soon be moved to NuParserClassRegistry
+ (NSCharacterSet *) nonWhiteSpaces {return _nonWhiteSpaces;}
+ (NSCharacterSet *) commentCharacters {return _commentCharacters; }
+ (NSCharacterSet *) endOfAtomCharacters { return _endOfAtomCharacters; }
+ (NSCharacterSet *) stringSpecialCharacters { return _stringSpecialCharacters; }
+ (NSCharacterSet *) nonWSbutNL {return _nonWSbutNL;}

- (id) init
{
    self = [super init];
    if (self) {
        _cell = nil;
        _location = NSNotFound;
        _length = 0;
        _previous = nil;
        _parent = nil;
        _root = nil;
        _comments = nil;
        _cellIgnored = NO;
        _logEvaluationResultEnabled = NO;
        _result = nil;
        [self resetMemoization];
    }
    return self;
}

- (void) resetMemoization
{
    _endLine = NSNotFound;
    _lineCol = nil;
    _error = nil;
}

- (id)initWithRoot:(NuRootParser *)root
            parent:(NuListParser *)parent
          previous:(NuObjectParser *)previous
          location:(NSInteger)location
          comments:(NSString *)comments
{
    self = [self init];
    self.root = root;
    self.parent = parent;
    self.previous = previous;
    self.location = location;
    if (comments) {
        self.comments = comments;
        self.cell = [self.root.cellProvider newCellWithComments];
        [(NuCellWithComments *) self.cell setComments: comments]; }
    else {
        self.cell = [self.root.cellProvider newCell]; }
    self.cell.parser = self;
    self.result = self.root.invalidResultSymbol;
    // parser ready to parse!
    return self;
}


- (void) parse
{    
    @throw @"Class too abstract to parse anything";
}

- (NSRange) updateAt:(NSInteger)abslocation deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    //NSLog(@"updating Parser %@", self);
    [self parse];
    //NSLog(@"updated Parser %@", self);
    return self.range;
}

- (void) clearEvaluationErrors
{
    if ([self.error.name isEqualToString:@"Evaluation Error"]) self.error = nil;
}

- (id) evalWithContext:(NSMutableDictionary *)context
{
    id result;
    [self clearEvaluationErrors];
    BOOL debugging = [NuDebugging state];
    [NuDebugging setState:YES];
    @try {
        [NuCell resetLastParent];
        result = [self.cell.car evalWithContext:context];
    }
    @catch (NuException *exception) {
        // this should be done now by the exception itself
        //NuObjectParser * parser = [[[[exception evaluationStack] objectAtIndex:0] objectForKey:@"cell"] parser];
        //[[parser parent] markError: @"Evaluation Error" reason: [exception reason]];
    }
    @catch (NSException *exception) {
        [self markError:@"Evaluation Error" reason: [exception description]];
        result = nil;
    }
    [NuDebugging setState:debugging];
    return result;
}

- (BOOL) stillValid
{
    return (self.class == [self.parent matchingParserClassAt:self.location]);
}

- (BOOL) stillValidWithChangesAt: (NSInteger) location
                         deleted: (NSInteger) deletionLength
                        inserted: (NSInteger) insertionLength
{
    return self.stillValid;
}

- (id) path
{
    return [NuCell cellWithCar: @(self.positionInList) cdr: self.parent.path];
}

- (int) depth
{
    return  self.parent.depth + 1;
}

- (NSArray *) key
{
    return [[NuCell cellWithCar:self.type cdr:self.path] array];
}

- (BOOL)atom
{
    if ((id)self.cell == [NSNull null])
        return NO;
    else
        return [self.cell.car atom];
}

/*
- (void)markError:(NSString *)name reason:(NSString *)reason range: (NSRange) range
{
    _error = [self.root.job error:name parser:self range: range reason:reason];
}
*/
- (NSInteger)end {
    return self.location + self.length;
}

- (NSInteger)length
{
    return _length;
}

- (void)setLength:(NSInteger)length
{
    _length = length;
    _endLine = NSNotFound;
}

- (void)setEnd:(NSInteger)end
{
    self.length = end - self.location;
}


- (NSRange) range {
    return NSIntersectionRange(NSMakeRange(self.location, self.length), NSMakeRange(0, self.root.job.source.length)) ;
}

- (void) moveBy: (NSInteger) delta
{
    self.location += delta;
}

- (NSInteger) column
{
    if (!_lineCol) _lineCol = [self.root.job.lineInfo lineColAt:self.location];
    return [_lineCol[1] integerValue];
}

- (NSInteger) line
{
    if (!_lineCol) _lineCol = [self.root.job.lineInfo lineColAt:self.location];
    return [_lineCol[0] integerValue];
}

- (NSInteger) endLine
{
    if (_endLine == NSNotFound)
    {
        if (self.end <= self.location)
            _endLine = self.line;
        else
            _endLine = [self.root.job.lineInfo lineAt:self.end - 1];    }
    return _endLine;
}

- (void)setLocation:(NSInteger)location
{
    _lineCol = nil;
    _endLine = NSNotFound;
    _location = location;
}

- (NSInteger)location { return  _location; }

- (int) positionInList
{
    if (self.previous)
        return self.previous.positionInList + 1;
    else
        return 0;
}

- (NuObjectParser *) lastNotIgnoredPrevious
{
    if (self.previous)
    {
        if (!self.previous.cellIgnored)
           return self.previous;
        else
            return self.previous.lastNotIgnoredPrevious;
    }
    else return nil;    
}

- (BOOL)cellIgnored {return _cellIgnored;}

- (void)setCellIgnored:(BOOL)cellIgnored
{
    if (!_cellIgnored && cellIgnored)
    {
        _cellIgnored = YES;
        NuObjectParser *previous = self.lastNotIgnoredPrevious;
        if (previous)
        {
            if ([self.cell isKindOfClass:[NuCell class]] && self.cell.cdr)
            {
                previous.cell.cdr = self.cell.cdr;
            }
            else previous.cell.cdr = [NSNull null];
        }
        else
        {
            self.parent.cell.car = self.cell.cdr;
        }
    }
    else if (_cellIgnored && !cellIgnored)
    {
        _cellIgnored = NO;
        NuObjectParser *previous = self.lastNotIgnoredPrevious;
        if (previous)
        {
            if (previous.cell.cdr)
            {
                self.cell.cdr = previous.cell.cdr;
                previous.cell.cdr = self.cell;
            }
        }
        else
        {
            self.parent.cell.car = self.cell;
        }
    }
}

- (void)markError:(NSString *)name reason:(NSString *)reason
{
    self.error = [self.root.job error:name parser:self reason:reason] ;
}

- (void) logEvaluationError:(NuDebuggingException *)exception
{
    
    [self.root.job exceptionHappened: exception parser: self];
}

- (void)logEvaluationResult:(id)result
{
    self.result = result;
    //NSLog(@"Result : %@",[result asNuExpression]);
    [self.root.job updateResultFor:self];
}

- (BOOL) resultIsValid
{
    return self.result != self.root.invalidResultSymbol;
}

- (void) invalidateResult
{
    self.result = self.root.invalidResultSymbol;
}

- (BOOL)displayParserWithinRange
{
    return NO; // can't be true for simple object parsers
}

- (NuResultDisplayParser *)displayParser
{
    NSInteger location = self.end;
    [self.root processWhiteSpacesAndCommentsWith:&location];
    NuObjectParser *followingParser = [self.root parserAt:location];
    if ([followingParser isKindOfClass:[NuResultDisplayParser class]])
        return (NuResultDisplayParser *) followingParser;
    else
        return nil;
}

- (NSRange) possibleDisplayParserRange
{
    NuResultDisplayParser *display;
    if ((display = [self displayParser]))
    {
        return  display.rangeIncludingSpaces;
    }
    else
    {
        return NSMakeRange(self.end, 0);
    }
}

- (TextChange *)proposedResultUpdate
{
    TextChange* textChange;
    // could be optimized if an existing display parser is reused
    if (self.displayParser && self.displayParser.lastChild) {
        
        textChange = [TextChange withRange: self.displayParser.lastChild.range
                                    string:[NSMutableString stringWithString:[[self result] asNuExpression]]];
    }
    else
    {
        textChange = [TextChange withRange:[self possibleDisplayParserRange]
                                    string:[NSMutableString stringWithFormat:@" => %@", [[self result] asNuExpression]]];
        
        if (![[NuParserClassRegistry endOfAtomCharacters] characterIsMember:[self.root.job characterAt: textChange.end]])
        {
            [textChange.string appendString:@" "];
        }
    }
    return textChange;
}


- (TextChange *)removalTextChange
{
    NSRange range = self.rangeIncludingSpaces;
    NSString *delimiter;
    if ([[NuParserClassRegistry endOfAtomCharacters] characterIsMember:[self.root.job characterAt:range.location + range.length]])
        delimiter = @"";
    else
        delimiter = @" ";
    return [TextChange withRange:range string:delimiter];
}

- (TextChange *) newlineInsertionTextChange
{
    return [TextChange withLocation:self.previous ? self.previous.end : self.withOffset
                             length:0
                             string:@"\n"];
}

- (TextChange *) newlineDeletionTextChange
{
    NSInteger start = self.previous ? self.previous.end : self.withOffset;
    return [TextChange withLocation: start
                             length: self.location - start
                             string: [[NuParserClassRegistry endOfAtomCharacters]
                                      characterIsMember: [self.root.job characterAt: self.location]] ? @"" : @" "];
}

- (NSMutableArray *)parserStackAt:(NSInteger)pos
{
    if (pos >= self.location && pos < self.end)
        return @[self].mutableCopy;
    else
        return nil;
}

- (NuObjectParser *) parserAt: (NSInteger) location
{
    if (location >= self.location && location < self.end)
        return self;
    else
        return nil;
}

- (NuObjectParser *) parserContaining: (NSRange) range
{
    if (self.location <= range.location && range.location + range.length <= self.end)
        return self;
    else
            return nil;
}

- (NSMutableArray *)descendants { return nil; }

- (NSMutableArray *) parents
{
    if (self.parent) {
        NSMutableArray *parents =  [self.parent parents];
        [parents addObject:self];
        return parents;
    }
    else
        return @[self].mutableCopy;
}

- (NSArray *)tree {return @[self];}


- (NSString *) source
{
    return [self.root.job sourceAt:self.location length:self.length];
}


- (void) alignChildren {}

- (BOOL) isFirstParserInLine
{
    if (self.previous)
        return self.previous.endLine < self.line;
    else
        return self.parent.line < self.line;
       // return self.column == [self.root.job.lineInfo codeColumnIn: self.line];
}

- (BOOL) isLabel { return NO; }


- (NSInteger) desiredColumn
{
    NSInteger indent = [self.root.job indentAt: self.line];
    if (indent != NSNotFound)
    {
        return self.column - [self.root.job.lineInfo codeColumnIn: self.line] + indent;
    }
    else return self.column;
}

- (NSRange)rangeIncludingSpaces
{
    NSInteger location;
    if (self.previous)
        location = self.previous.end;
    else
        location = self.parent.withOffset;
    NSInteger end = [self.root.job firstLocationOfCharactersInSet:[NuObjectParser nonWSbutNL] starting:self.end];
    return NSMakeRange(location, end - location);
}

- (void)alignWith:(NuObjectParser *)parserToAlign
{
    //NSLog(@"align: to col %li\nself : %@\nwith : %@",(unsigned long)parserToAlign.desiredColumn, self, parserToAlign);
    [self.root.job indent: self.line to: parserToAlign.desiredColumn];
}

/*
- (void) stackOpenSexprColumnsAt: (NSInteger)pos with: (NuStack *) stack { }
                   
- (NSInteger) parensAt: (NSInteger) pos
{
    return 0;
}
*/

- (NuCell *) proposeNewlineChanges
{
    return nil;
}

- (NuObjectParser *) first
{
    if (self.previous)
        return self.previous.first;
    else
        return self;
}


- (NuObjectParser *) parserNr: (int) nr
{
    int count = self.positionInList;
    NuObjectParser *parser;
    if (nr > count)
    {
        if ((parser = self.parent.lastChild))
        {
            count = parser.positionInList;
            if (nr > count) return nil;
        }
        else return nil;
    }
    else parser = self;
    while (count > nr){
        parser = parser.previous;
        count --;
    }
    return parser;
}


- (NSInteger) withOffset
{
    return  self.location + [self class].trigger.length;
}

- (NuObjectParser *) nextPreviousParser { return nil; }

+ (NSString *)trigger {return nil;}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ = %@, line: %li, col: %li loc: %li,  length: %li, end: %li, endline: %li depth %i type %@",
            [super description],
            [self.cell isKindOfClass:[NuCell class]] ?
                [[self.cell.car description] cutAt: 20]
              : @"<NULL>",
            (unsigned long)self.line,
            (unsigned long)self.column,
            (unsigned long)self.location, (unsigned long)self.length,
            (unsigned long)self.end,
            (unsigned long)self.endLine,
            self.depth,
            self.type];
}

- (NSString *) type { return @"?"; }
/*
- (NSString *)parserInfo
{
    return [NSString stringWithFormat:@"%@ %li %li", self.type, (unsigned long)self.location, (unsigned long)self.length];
}

- (NSString *)parseTreeInfo
{
    return [NSString stringWithFormat: @"(%@)", self.parserInfo];
}
*/
@end


////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuListParser
{
    BOOL _labelMemoized;
    BOOL _alignMemoized;
    NSMutableArray *_descendants;
}


@synthesize lastChild = _lastChild;
@synthesize parserToAlign = _parserToAlign;
@synthesize labelInFirstLine = _labelInFirstLine;


- (id)init
{
    self = [super init];
    if (self)
    {
        _lastChild = nil;
        _parserToAlign = nil;
        _labelInFirstLine = nil;
        _unfinishedHereString = NO;
        _displayParserWithinRange = NO;
    }
    return self;
}

- (void) resetMemoization
{    
    _labelMemoized = NO;
    _alignMemoized = NO;
    _descendants = nil;
    [super resetMemoization];
}

- (id)specialCarObject { return nil; }

- (int) count { return self.lastChild.positionInList; }



- (NuParserClassRegistry *) registry { return self.root.registry; }

- (Class) defaultParserClass { return self.registry.defaultParser; }

- (Class) endOfListParserClass { return [NuEndOfListParser class]; }

- (Class) matchParserClassWithTrigger: (NSString *) trigger
{
    if ([trigger isEqualToString:self.endOfListParserClass.trigger])
        return self.endOfListParserClass;
    else return [self registry].dictionary [trigger] ;
}

- (Class) matchingParserClassAt: (NSInteger) location
{
    Class matchingParserClass = nil;
    Class winningParserClass = nil;
    NSInteger tokenLength = 1;
    // the longest matching start token wins the price.
    while ((matchingParserClass =  [self matchParserClassWithTrigger:
                                    [self.root.job sourceAt: location
                                                     length: tokenLength ]]))  {
        winningParserClass = matchingParserClass;
        tokenLength ++;
    }
    if (!winningParserClass) winningParserClass = [self defaultParserClass];
    return winningParserClass;
}

- (Class) matchingParserClassAfter:(NSInteger)location
{
    [self processWhiteSpacesAndCommentsWith:&location];
    return [self matchingParserClassAt:location];
}

- (NSString *)processWhiteSpacesAndCommentsWith: (NSInteger *) indexp;
{
    BOOL parsing = YES;
    NSMutableString *comments = [@"" mutableCopy];
    NSInteger index = *indexp;
    
    do {
        index = [self.root.job firstLocationOfCharactersInSet:NuObjectParser.nonWhiteSpaces starting:index];
        if ([NuObjectParser.commentCharacters characterIsMember:[self.root.job characterAt: index ]  ])
        {
            NSInteger endOfComment = [self.root.job firstLocationOfCharactersInSet:[NSCharacterSet newlineCharacterSet] starting:index];
            if ([self.root.job characterAt:endOfComment] == '\0') self.root.job.state = PARSE_COMMENT;
            [comments appendString:[self.root.job sourceAt:index + 1 length:endOfComment - index]];
            index = endOfComment + 1;
        }
        else
        {
            *indexp = index;
            parsing = NO;
        }
    } while (parsing);
    
    if ([comments isEqualToString:@"" ])
        return  nil;
    else
         return comments;
}


- (NuObjectParser *)  parseInSpecialCar
{
    id object;
    if ((object = self.specialCarObject)) {
        NuObjectParser *parser = [[NuSpecialObjectParser  alloc] initWithObject: object
                                                                           root: self.root
                                                                         parent: self
                                                                       previous: nil
                                                                       location: self.withOffset
                                                                       comments: nil];
        [parser parse];
        self.cell.car = parser.cell;
        self.end = parser.end;
        self.lastChild = self;
        return parser;
    }
    else return nil;
}

- (NuObjectParser *) parseInItemWithParser: (NuObjectParser *) parser
{
    [parser parse];
    if (parser.nextPreviousParser)
    {
        parser = parser.nextPreviousParser;
    }
    if (!parser.cellIgnored)
    {
        NuObjectParser *previous = parser.lastNotIgnoredPrevious;
      if (previous)
        previous.cell.cdr = parser.cell;
      else
        self.cell.car = parser.cell;
    }
    return parser;
}

- (NuObjectParser *) parseInItemAt: (NSInteger) location
                          previous: (NuObjectParser *) previous
                          comments: (NSString *) comments
{
    if ([previous isKindOfClass:[NuEndOfListParser class]]) return nil;
    else
    {
        Class parserClass = [self matchingParserClassAt:location];
        NuObjectParser *parser = [[parserClass alloc  ]initWithRoot: self.root
                                                             parent: self
                                                           previous: previous
                                                           location: location
                                                           comments: comments];
        return [self parseInItemWithParser: parser];
    }
}

- (NuObjectParser *) parseInItemAfter: (NSInteger) location previous: (NuObjectParser *) previous
{
    if ([previous isKindOfClass:[NuEndOfListParser class]]) return nil;
    else
    {
        NSString *comments = [self processWhiteSpacesAndCommentsWith: &location];
        return [self parseInItemAt:location previous:previous comments:comments];
    }
}


- (NuObjectParser *) parseInItemAfterPrevious: (NuObjectParser *) previous
{
    NSInteger location;
    if (previous)
        location = previous.end;
    else
        location = self.withOffset;
    return [self parseInItemAfter:location previous:previous];
}

- (NuObjectParser *) consParser: (NuObjectParser *) parser after: (NuObjectParser *) previous
{
    parser.previous = previous;
    parser.parent = self;
    parser.root = self.root;
    if (self.end < parser.end)
        self.end = parser.end;
    while (parser.cellIgnored) {
        parser = [parser parserNr:[parser positionInList] + 1];
    }
    if (!parser.cellIgnored)
    {
        if (previous.cellIgnored) previous = previous.lastNotIgnoredPrevious;
        if (previous)
            previous.cell.cdr = parser.cell;
        else
            self.cell.car = parser.cell;
    }
    return parser;
}

- (NuObjectParser *) parseIn: (NSInteger) count itemsAfter:  (NSInteger) location previous: (NuObjectParser *) previous
{
    
    if (count > 0)
    {
        NuObjectParser *parser = [self parseInItemAfter:location previous:previous];
        
        if (parser && ![parser isKindOfClass:[NuEndOfListParser class]]
                   && ![parser isKindOfClass:[NuPostfixListParser class]])
        {
            do
            {
                //NSLog(@"ListParser %@ count %i, previous %@ current %@",  self,count, previous, parser);
                previous = parser;
                if (!previous.cellIgnored) count --;
            }
            while (count > 0 && (parser = [self parseInItemAfterPrevious: previous])
                             && ![parser isKindOfClass:[NuEndOfListParser class]]
                             && ![parser isKindOfClass:[NuPostfixListParser class]]);
        }
        
    }
    return previous;
}


- (void) parse
{
    [self resetMemoization];
    self.unfinishedHereString = NO;
    NuObjectParser *previous = [self parseInSpecialCar];
    NuObjectParser *parser;
    //NSLog(@"ListParser %@ previous %@ current %@", self, previous, parser);
    while ((parser = [self parseInItemAfterPrevious: previous]))
    {
        //NSLog(@"ListParser %@ previous %@ current %@", self, previous, parser);
        previous = parser;
    }
    self.lastChild = previous;
    self.end = self.lastChild ? self.lastChild.end : self.withOffset;
}

- (NSArray *) children
{
    NSMutableArray *children = [[NSMutableArray alloc] init];
    NuObjectParser *child = self.lastChild;
    while (child) {
        [children insertObject:child atIndex:0];
        child = child.previous;
    }
    return children;
}

- (NSArray *) tree
{
    NSMutableArray * subTrees = [[NSMutableArray alloc] init ];
    [subTrees addObject:self];
    for (NuObjectParser * child in self.children) {
        [subTrees addObject:child.tree];
    }
    return subTrees;
}

- (NuObjectParser *) childNr: (NSInteger) nr
{
    NuObjectParser *parser = self.lastChild;
    int count = parser.positionInList;
    if (nr > count) return nil;
    while (count > nr){
        parser = parser.previous;
        count --;
    }
    return parser;
}


- (NuObjectParser *) childAt: (NSInteger) location
{
    if (location < self.location || location >= self.end) return nil;
    NuObjectParser *parser = self.lastChild;
    while (parser) {
        if (location >= parser.location && location < parser.end) {
            //NSLog(@"parser at %i : %@", location, parser);
            return parser;
        }
        else
            parser = parser.previous;
    }
    return nil;
}


- (NuObjectParser *) childContaining: (NSInteger) location
{
    if (location < self.withOffset || location >= self.end) return nil;
    NuObjectParser *parser = self.lastChild;
    while (parser) {
        if (location >= parser.withOffset && location < parser.end) {
            //NSLog(@"parser at %i : %@", location, parser);
            return parser;
        }
        else
            parser = parser.previous;
    }
    return nil;
}

// finds a child which contains location
// whereby location == parser.end is possible
- (NuObjectParser *) childAround: (NSInteger) location
{
    NuObjectParser *parser = self.lastChild;
    while (parser) {
        if (location >= parser.location && location <= parser.end) {
            //NSLog(@"parser at %i : %@", location, parser);
            return parser;
        }
        else
            parser = parser.previous;
    }
    return nil;
}


- (NuObjectParser *) childBefore: (NSInteger) location
{
    if (location < self.location)
        return nil;
    NuObjectParser *parser = self.lastChild;
    while (parser && parser.previous) {
        if (location > parser.previous.end )
        {
            //NSLog(@"parser before %i : %@", location, parser.previous);
            return parser.previous;
        }
        else
            parser = parser.previous;
    }
    return nil;
}



- (NuObjectParser *) childAtOrBefore: (NSInteger) location
{
    if (location < self.location)
        return nil;
    NuObjectParser *parser = self.lastChild;
    while (parser) {
        if (location >= parser.location )
        {
            //NSLog(@"parser before %i : %@", location, parser.previous);
            return parser;
        }
        else
            parser = parser.previous;
    }
    return nil;
}

- (NuObjectParser *) childAfter: (NSInteger) location
{
    if (location > self.lastChild.location) return nil;
    NuObjectParser *parser = self.lastChild.previous;
    NuObjectParser *followingParser = self.lastChild;
    while (parser) {
        if ((location > parser.location ||
             location >= parser.end) // important to exclude parser with 0 length like special object parser
            && location <= followingParser.location) {
            //NSLog(@"parser after %i : %@", location, followingParser);
            return followingParser;
        }
        else
            followingParser = parser;
            parser = parser.previous;
    }
    // we're at the first parser
    // to prevent 
    if (location <= followingParser.location)
        return followingParser;
    else
        return  nil;
}



- (NuObjectParser *) parserAt: (NSInteger) location
{
    if (location >= self.location && location < self.end)
    {
        NuObjectParser *child = self.lastChild;
        NuObjectParser *parser;
        while (child) {
            //NSLog(@"parserAt %@ \n self %@", child, self);
            if  ((parser = [child parserAt:location]))
                return parser;
            else
                child = child.previous;
        }
        return self;
    }
    else return nil;
}

- (NuObjectParser *)parserContaining:(NSRange)range
{    
    if (self.location < range.location && range.location + range.length < self.end)
    {
        NuObjectParser *child = self.lastChild;
        NuObjectParser *parser;
        while (child) {
            if  ((parser = [child parserContaining:range]))
                return parser;
            else
                child = child.previous;
        }
        return self;
    }
    else return nil;
}

- (NSMutableArray *) parserStackAt: (NSInteger) pos
{
    NuObjectParser *child;
    if ((child = [self childAt:pos]))
    {
        NSMutableArray *parserStack = [child parserStackAt:pos];
        [parserStack addObject: self];
        return parserStack;
    }
    else
        return [super parserStackAt: pos];
}
/*
- (NSInteger) parensAt: (NSInteger) pos
{
    if (pos >= self.withOffset && pos < self.end)
    {
        NuObjectParser *child = [self childAt:pos];
        if (child)
            return [child parensAt:pos] + 1;
        else
            return 1;
        
    }
    else return 0;
}

- (void)stackOpenSexprColumnsAt:(NSInteger)pos with:(NuStack *)stack
{
    if (pos >= self.withOffset && pos < self.end)
    {
        [stack push: [self.root.job.lineInfo lineColAt: self.location] ];
        NuObjectParser *child = [self childAt: pos];
        if (child)
        {
            [child stackOpenSexprColumnsAt:pos with:stack];
        }
    }
}
*/
- (void)setParserToAlign:(NuObjectParser *)parserToAlign
{
    _alignMemoized = YES;
    _parserToAlign = parserToAlign;
}

- (NuObjectParser *) parserToAlign
{
    if (!_alignMemoized)  // memoizing needs an extra Bool, because nil is a valid value ...
    {
        // the align parser isn't memoized, find it
        if (self.endLine == self.line)
            // the list is just one line, so
            _parserToAlign = nil;
        else
        {
            _parserToAlign = [self.lastChild parserNr:1];
            NSNumber *specialIndent = [self.root specialIndentWithCar: _parserToAlign.previous.cell.car];
            if (specialIndent)
            {
                _parserToAlign = [[NuAlignParser alloc ] initWithRoot:self.root
                                                               parent:self
                                                             location:_parserToAlign.location
                                                                column:self.desiredColumn +  self.class.trigger.length
                                                                                          + specialIndent.integerValue];
            }
            
        /*    else if ([_parserToAlign isKindOfClass:[NuEndOfListParser class ]])
                _parserToAlign = nil;*/
            
        }
        _alignMemoized = YES;
    }
    return _parserToAlign;
}

- (void)setLabelInFirstLine:(NuObjectParser *)labelInFirstLine
{
    _labelMemoized = YES;
    _labelInFirstLine = labelInFirstLine;
}

- (NuObjectParser *) labelInFirstLine
{
    if (!_labelMemoized) // memoizing needs an extra Bool, because nil is a valid value ...
    {
        NSInteger scndLineLocation = [self.root.job.lineInfo location: self.line + 1];
        NuObjectParser *lastParserInLine = [self childAtOrBefore: scndLineLocation -1];
        
        _labelInFirstLine = nil;
        NuObjectParser *child = lastParserInLine;
        while (child) {
            if (child.isLabel)
                _labelInFirstLine = child;
            child = child.previous;
        }
        _labelMemoized = YES;
    }
    return _labelInFirstLine;
}

- (NSInteger) secondParserIndent
{
    return self.root.job.cdarIndent;
}

- (void) alignEverythingElse
{
    // probably this method could be combined with the following method
    // things evolved over time, and got sometimes more complicated than
    // necessary, i think.
    
    NSInteger indent;
    NSInteger standardIndent= 0;
    NSInteger secondItemLine= NSNotFound; // NSNotFound is very big ...
    NSInteger firstItemLine = NSNotFound;
    NuObjectParser *first;
    if (self.parserToAlign)
    {
        standardIndent = self.parserToAlign.desiredColumn; // align with the second item
        secondItemLine = self.parserToAlign.line;
        if (self.parserToAlign.previous) {
            firstItemLine = self.parserToAlign.previous.line;
        }
    }
    else if ((first = self.lastChild.first))
    {
        firstItemLine = first.line;
    }
    
    for (NSInteger line = self.line + 1; line <= self.endLine; line ++) {
        if ([self.root.job indentAt:line] == NSNotFound)
        {
            if ([self.root.job characterAt:[self.root.job.lineInfo codeIn:line] ] == '#')
                // hash comments don't get indented, i thought is a good idea ...?
                indent = 0;
            else if (line <= firstItemLine)
                // align with the list paren or so ...
                indent = self.desiredColumn + self.class.trigger.length; 
            else if (line <= secondItemLine)
                // align with the standard indent for the second Item
                indent = self.parserToAlign.previous.desiredColumn + self.secondParserIndent;
            else
                indent = standardIndent;
            [self.root.job indent:line to:indent];
        }
    }
}

- (void) alignChildren
{
    if ([self.root.job.lineInfo lineAt:self.end] != self.line)
    {
        NuObjectParser *child = self.lastChild;
        NuStack * parserStack = [[NuStack alloc ] init];
        do [parserStack push: child]; while ((child = child.previous));
        
        NuObjectParser *labelInFirstLine = [self labelInFirstLine];
        while ((child = parserStack.pop)) 
        {
            if (child.isFirstParserInLine)
            {
                if ([child isKindOfClass: [NuEndOfListParser class]]) {
                    if (child.column  == [self.root.job.lineInfo codeColumnIn: child.line])
                        [child alignWith:self];
                }
                else if (!child.previous)
                {
                    // if the first line ends with the beginning of the list,
                    // align with the offset location
                    // this is kind of a hack
                    [child alignWith:[[NuAlignParser alloc ] initWithRoot:self.root
                                                                   parent:self
                                                                 location:self.withOffset
                                                                   column:self.desiredColumn + self.class.trigger.length]];
                }
                else if (child.isLabel && labelInFirstLine)
                    // align with the first label in the first line
                    [child alignWith: labelInFirstLine];
                
                else if (child == self.parserToAlign)
                {
                    // means child is second parser in List, so align with first one
                    if (self.secondParserIndent > 0)
                        [child alignWith:[[NuAlignParser alloc ] initWithRoot:self.root
                                                                       parent:self
                                                                     location:child.location
                                                                       column:child.previous.desiredColumn + self.secondParserIndent]] ;
                    else
                        [child alignWith: child.previous];
                }
                else
                {
                    // align with the second item in list,
                    // forget aligning with the labels in the first line
                    [child alignWith: self.parserToAlign];
                    labelInFirstLine = nil;
                }
            }
            
            [child alignChildren];
        }
        [self alignEverythingElse];
        
    }
}
- (void)moveBy:(NSInteger)delta
{
    [super moveBy:delta];
    NuObjectParser *parser = self.lastChild;
    do
        [parser moveBy:delta];
    while ((parser = parser.previous));

}

- (NSMutableArray *)descendants
{
    if (!_descendants)
    {
        _descendants = [[NSMutableArray alloc]init];
        NuObjectParser *child = self.lastChild;
        while (child) {
            NSArray *grandChildren = child.descendants;
            if (grandChildren)
                [_descendants addObjectsFromArray:grandChildren];
            [_descendants addObject:child];
            child = child.previous;
        }
    }
    return _descendants;
}

- (NSRange) updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    if (self.unfinishedHereString)
    {
        [self parse];
        return self.range;
    }
    // lets save the errors
    NuError *error = self.error;
    [self resetMemoization];
    self.error = error; // I know, Iknow. I was too lazy do write another reset routine...
    
    //NSLog(@"updating %@, at: %i del: %i, ins: %i", self, location, deletionLength, insertionLength);
    NSInteger delta = insertionLength - deletionLength;
    NSInteger dirtyUntil = location + insertionLength;
    NSInteger updateEnd;
    NSRange affectedRange = NSMakeRange(0, NSNotFound);
    NSInteger index;
    
    // looking for a child parser to update
    NuObjectParser *parser = [self childAround:location ];
    if (parser.location == location && parser.previous && parser.previous.end == location)
        // if 2 parser are close together at location, prefer the parser before
        parser = parser.previous;
    
    // looking for the next clean parser in the list, which needs neither updating or new parsing
    NuObjectParser *nextCleanParser = [self childAfter: dirtyUntil - delta];
    
    if (nextCleanParser)
    {
        // I don't like this, but these dot and colon parsers need to have special treatment.
        // It's just ugly, but it works.
        if ([[self matchingParserClassAt:nextCleanParser.location + delta] isSubclassOfClass:[NuInfixParser class]])
            nextCleanParser=nil;
        
    }
    
    //NSLog(@"next clean parser %@", nextCleanParser);
    if (nextCleanParser)
    {
        if (nextCleanParser == parser)
            parser = nil;
        
        NuObjectParser *parserToMove = self.lastChild;
        do {
            [parserToMove moveBy:delta];
            if (parserToMove == nextCleanParser) break;
        }
        while ((parserToMove = parserToMove.previous));
        
        self.end += delta;
        
        updateEnd = nextCleanParser.location;
    }
    else
        updateEnd = NSNotFound;
    //NSLog(@"update end %i", updateEnd);
    

    //NSLog(@"updatable parser %@", parser);
    if (parser)
    {
        // there is a parser at the update location start
        // first looking wether the old parser still works
        if ([parser stillValidWithChangesAt:location deleted:deletionLength inserted:insertionLength])
        {
            
            // the old parser can be reused and an update message is sent to it
            // so the problem is "delegated" to another level in the tree
            // NSUInteger oldCarLength = parser.carLength;
            affectedRange = [parser updateAt:location deleted:deletionLength inserted:insertionLength];
            index = parser.end;
        }
        else
            // we have to start over
            parser = nil;
    }
    
    if (!parser)
    {
        // we're in a comment or whitespace or at the beginning of the list, so
        // get the parser before the update location
        parser = [self childBefore: location];
        if (parser)
        {
            // if there is any put the index after it
            index =  parser.end;
        }
        else
            // otherwise the first index after the trigger (usually '('),
            // so self doesn't get parsed as a child (I hope this works also for subclasses)
            index = self.withOffset;
    }
    
    if (![parser isKindOfClass:[NuEndOfListParser class]]) {
        NuObjectParser *previous = parser;
        BOOL parsing = YES;
        do {
            // parse commenst etc. and get a new parser for the next token
            
            //NSLog(@"index before comments %i", index);
            
            NSString *comments = [self processWhiteSpacesAndCommentsWith: &index];
            
            //NSLog(@"index after comments %i", index);
            // self.index points now at the start of the next token
            if (index == updateEnd)
            {
                // we're done and reached the end without complication (I hope so)
                // the next clean parser if there is any gets concatenated to the parser before
                // (if there is none the message is send to nil, which is fine)
                if (nextCleanParser) {
                    nextCleanParser.comments = comments;
                    [self consParser: nextCleanParser  after: previous];
                    // self.lastParserInList and self.end stay the same
                }
                else
                    // no next parser means end of list, cell.cdr has to be NSNull.null not nil
                    previous.cell.cdr = NSNull.null;
                parsing = NO;
                if (affectedRange.length == NSNotFound)
                    affectedRange = NSMakeRange(location, insertionLength);
            }
            else
            {
                /*  optimizations possible */
               /* if (index > dirtyUntil)
                {
                    // this means the updated list is longer than expected (index > updateEnd)
                    // or a child item is smaller than expected (index < updateEnd)
                    // recycle parser from an global parser list
                }*/
                
                parser = [self parseInItemAt:index previous:previous comments:comments];
                index = parser.end;
                
                // the list is over either with an  EndOfListParser (means the cell is empty or NSNull)
                // or an parser after an EndOfListParser, which means, the returned parser is nil
                // somehow a bit strage, i don't know, lets see how things evolve
                if ((!parser || !parser.cell ||  parser.cell == (NuCell *)[NSNull null]) && !parser.cellIgnored)
                {
                    // we are at the end of the list
                    // unfortunally too early, so the parent has to continue the work
                    // it could be possible to work here with temporary parens,
                    // but this seems complicated and has also to work well with an not yet existing editor
                    if (!previous) self.cell.car = (NuCell *)[NSNull null];
                    self.lastChild = parser? parser : previous;
                    NSInteger oldLength = self.length;
                    self.end = self.lastChild ? self.lastChild.end : self.withOffset;
                    parsing = NO;
                    if (oldLength > self.length)
                        affectedRange = NSMakeRange(self.location, oldLength);
                    else
                        affectedRange = self.range;
                }
                previous = parser;
            }
        } while (parsing) ;
    }
    else affectedRange = self.range;
    //NSLog(@"updated Parser %@", self
    if (self.logEvaluationResultEnabled) {
        self.logEvaluationResultEnabled = [self checkForResultLoggingTrigger];
    }
    return affectedRange;
}

- (BOOL) checkForResultLoggingTrigger
{
    NuObjectParser *child = self.lastChild;
    while (child) {
        if ([child isKindOfClass:[NuTriggerForResultLoggingListParser class]])
        {
            if ( [(NuTriggerForResultLoggingListParser *)child isAtRightPlace])
            {
                return YES;
            }
            else
            {
                [child markError: @"Syntax Error"  reason:@"End Of List expected"];
                return NO;
            }
        }
        child = child.previous;
    }
    return NO;
}


- (NSRange) leftParenRange
{
    return NSMakeRange(self.location, self.withOffset - self.location);
}


- (NSRange) rightParenRange
{
    if ([self.lastChild isKindOfClass:[NuEndOfListParser class]] && self.lastChild.end == self.end)
        return self.lastChild.range;
    else
        return NSMakeRange(self.end, 0);
}

- (void)clearEvaluationErrors
{
    [super clearEvaluationErrors];
    NuObjectParser *child = self.lastChild;
    while (child) {
        [child clearEvaluationErrors];
        child = child.previous;
    }
}

- (NuResultDisplayParser *)displayParser
{
    if (self.displayParserWithinRange)
    {
        if ([self.lastChild.previous isKindOfClass:[NuResultDisplayParser class]])
            return (NuResultDisplayParser *) self.lastChild.previous;
        else
            return  nil;
    }
    else
        return [super displayParser];
}

- (NSRange)possibleDisplayParserRange
{
    if (self.displayParserWithinRange)
    {
        NuResultDisplayParser *display;
        if ((display = [self displayParser]))
        {
            return  display.rangeIncludingSpaces;
        }
        else
        {
            if (self.lastChild.previous)
                return NSMakeRange(self.lastChild.previous.end, 0);
            else
                return NSMakeRange(self.lastChild.location, 0);
        }
        
        
    }
    else return [super possibleDisplayParserRange];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, count: %i", [super description], self.count];
}

- (NSString *)type { return @"list"; }

/*
- (NSString *)parseTreeInfo
{
    NSMutableString * result = [NSMutableString stringWithFormat: @"(%@", self.parserInfo];
    NuStack *infos =[[NuStack alloc] init];
    NuObjectParser *child = self.lastChild;
    while (child) {
        [infos push: child.parseTreeInfo];
        child = child.previous;
    }
    NSString *info;
    while ((info = infos.pop))
        [result appendString: info];
    [result appendString:@")"];
    return result;
}
 */

+ (NSString *) trigger { return @"("; }

@end


////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuEndOfListParser

- (id)initWithRoot:(NuRootParser *)root
              parent:(NuListParser *)parent
            previous:(NuObjectParser *)previous
            location:(NSInteger)location
            comments:(NSString *)comments
{
    self = [self init];
    self.root = root;
    self.parent = parent;
    self.previous = previous;
    self.location = location;
    self.comments = comments;
    self.cell = (NuCell *) NSNull.null;
    return self;
}

- (NSInteger) length { return self.class.trigger.length; }

- (void) parse {
    [self resetMemoization];
    self.cell = (NuCell *) NSNull.null;
}

+ (NSString *)trigger { return @")"; }

@end


////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuSilentEndOfListParser

- (NSInteger) length { return 0; }

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuAlignParser

- (NSInteger)column { return self.desiredColumn; }

- (id)initWithRoot:(NuRootParser *)root
            parent:(NuListParser *)parent
          location:(NSInteger) location
          column:(NSInteger)column
{
    self = [super init];
    self.location = location;
    self.desiredColumn = column;
    self.length = 0;
    self.parent = parent;
    self.root = root;
    self.cell = nil;
    return self;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuFixedLengthListParser

- (Class)endOfListParserClass { return [NuSilentEndOfListParser class]; }

- (int)listLength { return 2; }

- (BOOL) atom {return NO;}

// should have its own update method
// until then this parser should be parsed again on update ...
//- (BOOL)stillValid { return NO; }

- (void) parse
{
    [self resetMemoization];
    //NSLog(@"previous fix length parser: %@", self.previous);
    int count = self.listLength;
    NuObjectParser *previous = [self parseInSpecialCar];
    if (previous) count --;
    self.lastChild = [self parseIn:count itemsAfter:self.withOffset previous:previous];
    self.end = self.lastChild ? self.lastChild.end : self.withOffset;
    //NSLog(@"ListParser %@ count %i, previous %@ current %@",  self,count, previous, parser);
}


- (NSRange) updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    if (self.unfinishedHereString)
    {
        [self parse];
        return self.range;
    }
    // lets save the errors
    NuError *error = self.error;
    [self resetMemoization];
    self.error = error; // I know, Iknow. I was too lazy do write another reset routine...
    
    NSInteger delta = insertionLength - deletionLength;
    NSInteger dirtyUntil = location + insertionLength;
    NSInteger updateEnd;
    NSRange affectedRange;
    NSInteger index;
    
    // looking for a child parser to update
    NuObjectParser *parser = [self childAround:location ];
    if (parser.location == location && parser.previous && parser.previous.end == location)
        // if 2 parser are close together at location, prefer the parser before
        parser = parser.previous;
    
    // looking for the next clean parser in the list, which needs neither updating or new parsing
    NuObjectParser *nextCleanParser = [self childAfter: dirtyUntil - delta];
    
    if (nextCleanParser)
    {
        // I don't like this, but these dot and colon parsers need to have special treatment.
        // It's just ugly, but it works.
        unichar c = [self.root.job characterAt:nextCleanParser.location + delta];
        if (c == '.' || c == ':'  || nextCleanParser.positionInList >= self.listLength - 1 ) nextCleanParser = nil;
    }
    
    //NSLog(@"next clean parser %@", nextCleanParser);
    if (nextCleanParser)
    {
        if (nextCleanParser == parser)
            parser = nil;
        
        NuObjectParser *parserToMove = self.lastChild;
        do {
            [parserToMove moveBy:delta];
            if (parserToMove == nextCleanParser) break;
        }
        while ((parserToMove = parserToMove.previous));
        
        self.end += delta;
        
        updateEnd = nextCleanParser.location;
    }
    else
        updateEnd = NSNotFound;
    //NSLog(@"update end %i", updateEnd);
    
    
    //NSLog(@"updatable parser %@", parser);
    if (parser)
    {
        // there is a parser at the update location start
        // first looking wether the old parser still works
        if ([parser stillValidWithChangesAt:location deleted:deletionLength inserted:insertionLength])
        {
            
            // the old parser can be reused and an update message is sent to it
            // so the problem is "delegated" to another level in the tree
            // NSUInteger oldCarLength = parser.carLength;
            affectedRange = [parser updateAt:location deleted:deletionLength inserted:insertionLength];
            index = parser.end;
        }
        else
            // we have to start over
            parser = nil;
    }
    
    if (!parser)
    {
        // we're in a comment or whitespace or at the beginning of the list, so
        // get the parser before the update location
        parser = [self childBefore: location];
        if (parser)
        {
            // if there is any put the index after it
            index =  parser.end;
        }
        else
            // otherwise the first index after the trigger (usually '('),
            // so self doesn't get parsed as a child (I hope this works also for subclasses)
            index = self.withOffset;
    }
    
    if (parser.positionInList < self.listLength  && ![parser isKindOfClass:[NuEndOfListParser class]]) {
        NuObjectParser *previous = parser;
        BOOL parsing = YES;
        do {
            // parse commenst etc. and get a new parser for the next token
            
            //NSLog(@"index before comments %i", index);
            
            NSString *comments = [self processWhiteSpacesAndCommentsWith: &index];
            
            //NSLog(@"index after comments %i", index);
            // self.index points now at the start of the next token
            if (index == updateEnd)
            {
                // we're done and reached the end without complication (I hope so)
                // the next clean parser if there is any gets concatenated to the parser before
                // (if there is none the message is send to nil, which is fine)
                if (nextCleanParser) {
                    nextCleanParser.comments = comments;
                    [self consParser: nextCleanParser  after: previous];
                    // self.lastParserInList and self.end stay the same
                }
                else
                    // no next parser means end of list, cell.cdr has to be NSNull.null not nil
                    previous.cell.cdr = NSNull.null;
                parsing = NO;
                affectedRange = NSMakeRange(location, insertionLength);
            }
            else
            {
                /*  optimizations possible 
                if (index > dirtyUntil)
                {
                    // this means the updated list is longer than expected (index > updateEnd)
                    // or a child item is smaller than expected (index < updateEnd)
                    // recycle parser from an global parser list
                }*/
                if (!previous)
                    previous = [self parseInSpecialCar];
                
                if (!previous || previous.positionInList < self.listLength-1)
                {
                    parser = [self parseInItemAt:index previous:previous comments:comments];
                    index = parser.end;
                }
                else parser = nil;                
                // the list is over either with an  EndOfListParser (means the cell is empty or NSNull)
                // or an parser after an EndOfListParser, which means, the returned parser is nil
                // somehow a bit strage, i don't know, lets see how things evolve
                if ((!parser || parser.positionInList >= self.listLength - 1 || !parser.cell ||  parser.cell == (NuCell *)[NSNull null]) && !parser.cellIgnored)
                {
                    // we are at the end of the list
                    // unfortunally too early, so the parent has to continue the work
                    // it could be possible to work here with temporary parens,
                    // but this seems complicated and has also to work well with an not yet existing editor
                    if (!previous) self.cell.car = (NuCell *)[NSNull null];
                    self.lastChild = parser? parser : previous;
                    self.end = self.lastChild ? self.lastChild.end : self.withOffset;
                    parsing = NO;
                    affectedRange = self.range;
                }
                previous = parser;
            }
        } while (parsing) ;
    }
    else affectedRange = self.range;
    //NSLog(@"updated Parser %@", self);
    return affectedRange;
}

+ (NSString *)trigger {return nil;} // to make shure it is subclassed ...

@end


////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuInfixParser

- (BOOL)stillValid
{
    return NO;
}


/*
- (BOOL)stillValidWithChangesAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    NSInteger delta = insertionLength - deletionLength;
    NSInteger dirtyUntil = location + insertionLength;
    NSInteger loc = self.lastChild.first.end;
    if (loc + delta > dirtyUntil)
    {        
        loc += delta;
    }
    return [self.class isEqualTo: [self matchingParserClassAfter:loc + delta] ];
}
*/

- (NSRange)updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    [self parse];
    return self.range;
}

- (void)parse
{
    [self resetMemoization];
    NuObjectParser * parserToTransfer = self.previous; // this is the parser in the previous cell
    NuObjectParser * lastParserBeforeInfix = parserToTransfer;
    // mabe some ignored Items
    while (parserToTransfer.cellIgnored) {
        parserToTransfer = parserToTransfer.previous;
    }
    
    if (!parserToTransfer || [parserToTransfer isKindOfClass:[NuSpecialObjectParser class]]) {
        // if dot is before a hidden object or at the beginning of an list
        // provide an error
        self.end = self.location + self.class.trigger.length;
        [self markError: @"Syntax Error" reason:@"Infix/Postfix reader macro at the start of a list."];
    }
    else
    {
        NSInteger nextLocation = self.location + self.class.trigger.length;
        self.location = parserToTransfer.location;
        self.end = nextLocation;
        self.cell.car = parserToTransfer.cell;
        self.previous = parserToTransfer.previous;
        parserToTransfer.parent = self;
        parserToTransfer.previous = nil;
        self.lastChild = [self parseIn: self.listLength - 1 itemsAfter: nextLocation previous:lastParserBeforeInfix];
        if (self.lastChild.end > self.end)
            self.end = self.lastChild.end;
    }
}

// the trigger lives in the middle of the parser so wihtOffset is just the beginning of the first item
- (NSInteger)withOffset {return self.location; }

@end


////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuDotParser

- (int)listLength {return 2;}
+ (NSString *)trigger { return @"."; }

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuColonParser

- (int)listLength {return 3;}
+ (NSString *)trigger { return @":"; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuPostfixListParser

- (BOOL)stillValidWithChangesAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    NSInteger delta = insertionLength - deletionLength;
    NSInteger dirtyUntil = location + insertionLength;
    if (self.end + delta > dirtyUntil)
    {
        Class matchingClass =[self.parent matchingParserClassAt:self.lastChild.location + delta];
        return (self.class == matchingClass || [matchingClass isSubclassOfClass:[NuEndOfPostfixListParser class]]);
    }
    else
        return NO;
}

- (void) parse
{
    
    [self resetMemoization];
    if (!self.previous ||  [self.previous isKindOfClass:[NuSpecialObjectParser class]])
    {
        self.end = self.withOffset;
        [self markError: @"Syntax Error" reason:@"Arrow at the start of a list." ];
    }
    else
    {
        NuObjectParser * firstParser = self.first;
        self.cell.car = firstParser.cell;
        self.parent.cell.car = self.cell;
        // end the list before here
        NuObjectParser * previous = self.previous;
        previous.cell.cdr = [NSNull null];
        // set self at the position of the first cell in the car
        
        NuObjectParser *eolparser = [[NuEndOfArrowListParser alloc] initWithRoot:self.root
                                                                          parent:self
                                                                        previous:previous
                                                                        location:self.location
                                                                        comments:nil];
        
        // make every cell in list child of self
        NuObjectParser * childParser = previous;
        while (childParser) {
            childParser.parent = self;
            childParser = childParser.previous;
        }
        
        self.location = self.parent.withOffset;
        self.previous = nil;
        
        [self consParser:eolparser after:previous];
        self.lastChild = eolparser;
        self.end = eolparser.end;
        
        if (self.parent.logEvaluationResultEnabled &&
            self.parent.displayParserWithinRange) {
            self.logEvaluationResultEnabled = YES;
            self.displayParserWithinRange = YES;
            self.parent.logEvaluationResultEnabled = NO;
            self.parent.displayParserWithinRange = NO;
        }
        
    }
}

- (NSInteger)withOffset { return self.location; }

+ (NSString *)trigger {return nil;} // to make shure it is subclassed ...

@end

@implementation NuEndOfPostfixListParser

- (void)alignWith:(NuObjectParser *)parser
{
    id firstParser = self.first;
    NuObjectParser *secondParser;
    if ([firstParser isKindOfClass:[NuArrowParser class]])
    {
        [super alignWith:[firstParser lastChild]];
    }
    else if ((secondParser = [self parserNr:1]) && ![secondParser isKindOfClass:[NuEndOfListParser class]])
    {
        [self.root.job indent: self.line to: secondParser.desiredColumn - 3];
        
    }
    
    else [super alignWith:parser];
}

+ (NSString *)trigger { return nil; }

@end



///////////////////////////////////////////////////////////////////////////////////

@implementation NuArrowParser


- (Class) endOfListParserClass { return [NuEndOfArrowListParser class]; }

+ (NSString *)trigger { return @"<-"; }

@end

@implementation NuEndOfArrowListParser

+ (NSString *)trigger { return @"<-"; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuHiddenPrefixParser

- (int)listLength {return 1;}

- (void) hide
{
    NuObjectParser * lnip;
    if (self.lastChild && ((id) self.lastChild.cell != [NSNull null] ||
                           ((lnip = self.lastChild.lastNotIgnoredPrevious) &&  lnip.cell != (NuCell *) [NSNull null])))
    {
        self.error = nil;
        self.cell.car = self.lastChild.cell.car;
    }
    else
    {
        [self markError: @"Syntax Error"  reason:@"Prefix not possible at the end of a list"];
    }
}

- (void)parse
{
    [super parse];
    [self hide];
}

- (NSRange)updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    NSRange range = [super updateAt:location deleted:deletionLength inserted:insertionLength];
    [self hide];
    return range;
}


+ (NSString *)trigger {return nil;}

@end


///////////////////////////////////////////////////////////////////////////////////

@implementation NuHiddenPostfixParser

- (int)listLength {return 1;}

- (void) hide
{
    if (self.lastChild && (id) self.lastChild.cell != [NSNull null])
    {
        self.cell.car = self.lastChild.cell.car;
    }
    else
    {
        [self markError: @"Syntax Error"  reason:@"Postfix not possible at the start of a list"];
    }
}

- (void)parse
{
    [super parse];
    [self hide];
}

- (NSRange)updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    NSRange range = [super updateAt:location deleted:deletionLength inserted:insertionLength];
    [self hide];
    return range;
}


+ (NSString *)trigger {return nil;}

@end

///////////////////////////////////////////////////////////////////////////////////
    
@implementation NuSpecialObjectParser

@synthesize object = _object;

- (id)init
{
    self = [super init];
    _object = nil;
    return  self;
}

- (NSInteger)length { return 0; }

- (NuObjectParser *)initWithObject: (id) object
                                root:(NuRootParser *)root
                              parent:(NuListParser *)parent
                            previous:(NuObjectParser *)previous
                            location:(NSInteger)location
                            comments:(NSString *)comments
{
    
    self = [self initWithRoot:root
                       parent:parent
                     previous:previous
                     location:location
                     comments:comments];
    self.object = object;
    // parser ready to parse!
    return self;

}

- (BOOL)stillValid
{
    return YES;
}

- (void) parse
{
    
    [self resetMemoization];
    self.cell.car = self.object;
}

- (NSString *)type { return @"symbol"; }

+ (NSString *)trigger { return @""; }

@end


///////////////////////////////////////////////////////////////////////////////////

@implementation NuRootParser
@synthesize job = _job;
@synthesize cellProvider = _cellProvider;
@synthesize registry = _registry;
@synthesize symbolTable = _symbolTable;
//@synthesize temporaryParenAllowed = _temporaryParenAllowed;
//@synthesize temporaryParens = _temporaryParens;
//@synthesize temporaryParenSet = _temporaryParenSet;

static NSDictionary *_specialIndent;

+ (void)initialize
{
    _specialIndent = @{@"class": @0,
                       @"function": @3};
}

- (id)specialCarObject { return [self.symbolTable symbolWithString:@"progn"]; }

- (id)init {
    self = [super init];
    _job = nil;
    _cellProvider = nil;
    _registry = nil;
    _symbolTable = nil;
    _invalidResultSymbol = nil;
    return  self;
}

- (NuRootParser *)initWithJob:(NuParseJob *)job
                     cellProvider:(id<NuCellProvider>)cellProvider
                         registry:(NuParserClassRegistry *) registry
                      symbolTable:(NuSymbolTable *)symbolTable
{
    self = [self init];
    self.job = job;
    self.root = self;
    self.parent = nil;
    self.location = 0;
    self.comments = nil;
    self.cellProvider = cellProvider;
    self.cell = [self.cellProvider newCell];
    self.registry = registry;
    self.symbolTable = symbolTable;
    self.invalidResultSymbol = [self.symbolTable symbolWithString:@"<invalid Result>"];
    [self.invalidResultSymbol setValue:self.invalidResultSymbol];
    return self;
}

- (NSInteger)secondParserIndent
{
    return 0;
}

- (NSNumber *)specialIndentWithCar: (id) symbol
{
    if ([symbol isKindOfClass:[NuSymbol class]])
        return _specialIndent[[symbol stringValue]];
    else return nil;
}

- (Class)endOfListParserClass { return [NuEndOfFileParser class]; }

- (NSInteger) location { return 0; }

- (int)depth { return 0; }

- (id) path { return [NSNull null]; }

+ (NSString *) trigger { return @""; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuEndOfArrayParser

+ (NSString *)trigger { return @"]"; }

@end


@implementation NuArrayParser


- (NSInteger) secondParserIndent
{
    return 0;
}

- (Class)endOfListParserClass { return [NuEndOfArrayParser class]; }

+ (NSString *)trigger {return @"[";}

- (id)specialCarObject { return [[NuSymbolTable sharedSymbolTable] symbolWithString:@"array"]; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuBlockParser

- (BOOL)stillValid {return NO;}

- (Class)endOfListParserClass { return [NuEndOfBlockParser class]; }

+ (NSString *)trigger {return @"{";}

- (id)specialCarObject { return [[NuSymbolTable sharedSymbolTable] symbolWithString:@"do"]; }

- (void)parse
{
    
    [self resetMemoization];
    NuObjectParser *previous = [self parseInSpecialCar];
    NuBlockArgumentParser *argumentParser =
      [[NuBlockArgumentParser alloc] initWithRoot:self.root
                                           parent:self
                                         previous:previous
                                         location:self.withOffset
                                         comments:nil];
    
    [self parseInItemWithParser:argumentParser];
    
    if ([argumentParser.lastChild isKindOfClass:[NuEndOfBlockParser class]])
    {
        NuObjectParser *parser = argumentParser.lastChild;
        while (parser) {
            parser.parent = self;
            parser.root = self.root;
            parser = parser.previous;
        }
        [self consParser:argumentParser.lastChild.first after:argumentParser];
        argumentParser.cell.car = [NSNull null];
        self.lastChild = argumentParser.lastChild;
        argumentParser.lastChild = nil;
        argumentParser.length = 0;
    }
    else
    {
        previous = argumentParser;
        NuObjectParser *parser;
        while ((parser = [self parseInItemAfterPrevious: previous]))
        {
            previous = parser;
        }
        self.lastChild = previous;
    }
    self.end = self.lastChild ? self.lastChild.end : self.withOffset;
}

@end

@implementation NuBlockArgumentParser

- (Class)endOfListParserClass {
    return [NuEndOfBlockArgumentParser class];
}

- (Class)matchParserClassWithTrigger:(NSString *)trigger
{
    if ([NuEndOfBlockParser.trigger isEqualToString:trigger])
    {
        return [NuEndOfBlockParser class];
    }
    else return [super matchParserClassWithTrigger:trigger];
}

+ (NSString *)trigger { return @""; }

@end

@implementation NuEndOfBlockArgumentParser

+ (NSString *)trigger { return @"|"; }

@end


@implementation NuEndOfBlockParser

+ (NSString *)trigger { return @"}"; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuSymbolAndNumberParser
/*
static NSNumberFormatter * _numberFormatter = nil;

+ (NSNumberFormatter *) numberFormatter
{
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setNumberStyle:NSNumberFormatterScientificStyle];
        [_numberFormatter setDecimalSeparator:@"."];
    }
    return _numberFormatter;
}
*/

static id _locale;

+ (id)locale
{
    if (!_locale)
        _locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    return _locale;
}

- (NSRange)updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    NSRange range =  [super updateAt:location deleted:deletionLength inserted:insertionLength];
    if (self.previous && self.previous.isLabel && self.isLabel)
    {
        // the label concetenation, Tims last change in Nu (Aug 2013) is not easy to solve with update.
        // the problem is, that a change in this parser (like changing a the last symbol in a row into a label)
        // could affect the parser before, which I hadn't taken in accont yet.
        [self.previous parse];
        if (self.previous.end == self.end) {
            // so if the previous reparsed parser ends the same than self
            // something is wrong.
            // so lets steal everything from previous and kill him. that should do it.
            NuObjectParser *previous = self.previous;
            range = previous.range;
            self.location = previous.location;
            self.end = previous.end;
            self.cell = previous.cell;
            self.previous = previous.previous;
            self.comments = previous.comments;
            previous.previous = nil;
            previous.parent = nil;
            previous.root = nil;
        }
    }
    return range;
}


static id numberFromString(NSString *string)
{
    const char *cstring = [string cStringUsingEncoding:NSUTF8StringEncoding];
    char *endptr;
    // If the string can be converted to a long, it's an NSNumber.
    long lvalue = strtol(cstring, &endptr, 0);
    if (*endptr == 0) {
        return [NSNumber numberWithLong:lvalue];
    }
    // If the string can be converted to a double, it's an NSNumber.
    double dvalue = strtod(cstring, &endptr);
    if (*endptr == 0) {
        // this could be possible and give more precission, but probably slower
        //return [NSDecimalNumber decimalNumberWithString:string locale:[NuSymbolAndNumberParser locale]];
        return [NSNumber numberWithDouble:dvalue];
    }
    return nil;
}

static NSCharacterSet *_endOfTagCharacterSet;

- (NSCharacterSet *)endOfTagCharacterSet
{
    if (!_endOfTagCharacterSet) {
        _endOfTagCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\"()[]{}\0"];
    }
    return _endOfTagCharacterSet;
}


- (void)parse
{
    NSInteger labelEnd;
    [self resetMemoization];
    NSInteger dotPosition = NSNotFound;
    NSInteger index;
    if ( [self.root.job characterAt:self.withOffset] == '&')
    {
        index = [self.root.job firstLocationOfCharactersInSet:[self endOfTagCharacterSet] starting:self.withOffset];
        NSString * atomString = [self.root.job sourceAt:self.withOffset length: index - self.withOffset];
        self.cell.car = [self.root.symbolTable symbolWithString:atomString];
    }
    else
    {
        index = [self.root.job firstLocationOfCharactersInSet:NuObjectParser.endOfAtomCharacters starting:self.withOffset];
        
        if ([self.root.job characterAt: index] == '.')
        {
            // in case of a dot parse the next part too, maybe the dot is a decimal point
            dotPosition = index;
            index = [self.root.job firstLocationOfCharactersInSet: NuObjectParser.endOfAtomCharacters
                                                         starting: index + 1];
        }
        if ([self.root.job characterAt:index] == ':')
        {
            
            do {
                index ++;
                labelEnd = index;
                index = [self.root.job firstLocationOfCharactersInSet:NuObjectParser.endOfAtomCharacters starting:labelEnd];
            } while ([self.root.job characterAt:index] == ':');
            index = labelEnd;
        }
        if (index == self.withOffset) index ++;
        NSString * atomString = [self.root.job sourceAt:self.withOffset length: index - self.withOffset];
        if (!atomString) atomString = @"";
        NSNumber * number = numberFromString(atomString);
        // if its a number, great.
        if (number) self.cell.car = number;
        else if (![self.root.registry.dictionary objectForKey: @"."]  ||  dotPosition == NSNotFound)
            // if theres no dot, also great;
            self.cell.car = [self.root.symbolTable symbolWithString:atomString];
        else
        {
            // the dot is a dot. we'll try again before the dot
            index = dotPosition;
            atomString =[self.root.job sourceAt:self.location
                                         length:index - self.location];
            //NSNumber * number = [[NuSymbolAndNumberParser numberFormatter] numberFromString:atomString];
            NSNumber * number = numberFromString(atomString);
            self.cell.car = number ? number : [self.root.symbolTable symbolWithString:atomString];
            
        }
    }
    self.end = index;
}

- (BOOL)stillValid
{
    unichar c = [self.root.job characterAt: self.location];
    return (([self.parent matchingParserClassAt:self.location] == [NuSymbolAndNumberParser class]) &&
            ![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c] &&
            ![NuObjectParser.commentCharacters characterIsMember:c]) &&
            ![NuObjectParser.endOfAtomCharacters characterIsMember:c];
}

- (BOOL) isLabel
{
    return [self.cell.car isKindOfClass:[NuSymbol class]] && [self.cell.car isLabel];
}

- (void)alignWith:(NuObjectParser *)parserToAlign
{
    if (self.isLabel && parserToAlign.isLabel)
    {
       [self.root.job indent: self.line to: parserToAlign.desiredColumn + parserToAlign.length - self.length];
    }
    else
        [self.root.job indent: self.line to: parserToAlign.desiredColumn];
}

- (id) evalSymbol
{
    @try {
        return [self.cell.car evalWithContext:self.root.job.context];
    }
    @catch (NSException *exception) {
        return nil;
    }
}

- (NSString *)type
{
    if ([self.cell.car isKindOfClass:[NSNumber class]])
        return @"number" ;
    else if ([self.cell.car isKindOfClass:[NuSymbol class]])
    {
        NuSymbol *symbol = self.cell.car;
    
        if (symbol.isLabel)
            return  @"label";
        else if ([symbol.value isKindOfClass:[NuOperator class]])
            return @"operator";
        // unfortunately this is too expensive:
        //else if ([[self evalSymbol] isKindOfClass:[NuMacro_0 class]])
        //      return @"macro";
        // maybe there is a different way.
        // I think it could be possible to collect context information in the symbol instance itself,
        // so a symbol can remember possible value classes ....
        else if ([symbol.value isKindOfClass:[NSObject class]])
            return @"object";
        else  return @"symbol";
    }
    else return @"?";
}

+ (NSString *)trigger { return  @""; }

@end
///////////////////////////////////////////////////////////////////////////////////

@implementation NuLongSymbolParser

- (BOOL)stillValid {return NO;}

- (NSRange)updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    [self parse];
    return self.range;
}

- (void)parse
{
    [self resetMemoization];
    BOOL parsing = YES;
    NSMutableString * parsedString = [@"<" mutableCopy];
    NSInteger lastStart = self.withOffset;
    NSInteger index;
    do
    {
        index = [self.root.job firstLocationOfCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n>\0\\"]
                                                     starting:lastStart];
        switch ([self.root.job characterAt: index]) {
            case '\n':
                [self markError: @"Syntax Error"
                         reason:@"Symbol ended by Newline" ];
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt: lastStart length: index - lastStart]];
                break;
                
            case '\0':
                [self markError: @"Syntax Error"  reason:@"Symbol not ended at the end of source" ];
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                break;
                
            case '>':
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart + 1]];
                index ++;
                break;
                
            case '\\':
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                @try {
                    
                    [parsedString appendCharacter:[self.root.job parseEscapeAt: &index]];
                }
                @catch (NSException *exception) {
                    [self.parent markError: @"Syntax Error"  reason:exception.description];
                    index++;
                }
                lastStart = index;
                break;
        }
    } while (parsing);
    self.end = index;
    self.cell.car = [self.root.symbolTable symbolWithString: parsedString];
}

- (NSString *)type {return @"symbol";}

+ (NSString *)trigger {return @"<";}

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuStringParser

- (void) parse
{
    
    [self resetMemoization];
    BOOL parsing = YES;
    NSMutableString * parsedString = [@"" mutableCopy];
    NSInteger lastStart = self.withOffset;
    NSInteger index;
    do
    {
        index = [self.root.job firstLocationOfCharactersInSet:NuObjectParser.stringSpecialCharacters
                                                         starting:lastStart];
        switch ([self.root.job characterAt: index]) {
            case '\n':
                [self markError: @"Syntax Error" 
                         reason:@"String ended by Newline" ];
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt: lastStart length: index - lastStart]];
                break;
                
            case '\0':
                self.root.job.incomplete = YES;
                self.root.job.state = PARSE_STRING;
               [self markError: @"Syntax Error"  reason:@"String not ended at the end of source" ];
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                break;
                
            case '"':
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                index ++;
                break;
                
            case '\\':
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                @try {
                    
                    [parsedString appendCharacter:[self.root.job parseEscapeAt: &index]];
                }
                @catch (NSException *exception) {
                    [self.parent markError: @"Syntax Error"  reason:exception.description];
                    index++;
                }
                lastStart = index;
                break;
        }
    } while (parsing);
    self.end = index;
    self.cell.car =  parsedString;
}

- (NSString *)type { return @"string"; }

+ (NSString *)trigger { return @"$\""; }

@end


///////////////////////////////////////////////////////////////////////////////////

@implementation NuEscapedStringParser
+ (NSString *)trigger { return @"+$\""; }
@end

@implementation NuNonescapedStringParser
- (NSCharacterSet *)stringSpecialCharacters { return _endOfStringCharacters; }
+ (NSString *)trigger { return @"-$\""; }
@end


///////////////////////////////////////////////////////////////////////////////////

@implementation NuHeredocParser


- (BOOL) escaped {return NO; }

- (BOOL)stillValid { return NO;}

- (void)alignChildren
{
    for (NSInteger line = self.line + 1; line <= self.endLine && line < self.root.job.lineInfo.count ; line ++)
    {
        NSInteger indent = [self.root.job.lineInfo codeColumnIn:line];
        //if (indent == NSNotFound) indent = 0;
        [self.root.job indent:line to: indent];
    }
}

- (void)parse
{
    
    [self resetMemoization];
    NSInteger index = self.withOffset;
    
    NSInteger identifierEnd =[self.root.job firstLocationOfCharactersInSet:NuObjectParser.endOfAtomCharacters
                                                            starting:index];
    NSString *identifier = [self.root.job sourceAt: index length: identifierEnd -  index];
    NSInteger stringStart = [self.root.job firstLocationOfCharactersInSet:[NSCharacterSet newlineCharacterSet]
                                                           starting:identifierEnd] + 1;
    NSRange endIdRange = [self.root.job rangeOfString: identifier starting: stringStart];
    NSString * string = [self.root.job sourceAt:stringStart length: endIdRange.location - stringStart];
    
    self.cell.car = self.escaped ? [self.root.job parseEscapesIn:string] : string;
    
    self.end = endIdRange.location + endIdRange.length;
    
}


+ (NSString *)trigger { return @"$<<-"; }

@end


@implementation NuEscapedHeredocParser

- (BOOL)escaped { return YES; }
+ (NSString *)trigger { return @"$<<+"; }

@end

///////////////////////////////////////////////////////////////////////////////////


@implementation NuLegacyStringParser
+ (NSString *)trigger { return @"\""; }
@end

@implementation NuLegacyEscapedStringParser
+ (NSString *)trigger { return @"+\""; }
@end

@implementation NuLegacyNonescapedStringParser
+ (NSString *)trigger { return @"-\""; }
@end

@implementation NuLegacyHeredocParser
+ (NSString *)trigger { return @"<<-"; }
@end

@implementation NuLegacyEscapedHeredocParser
+ (NSString *)trigger { return @"<<+"; }
@end

///////////////////////////////////////////////////////////////////////////////////


@implementation NuInterpolationStringParser



- (id)specialCarObject { return [[NuSymbolTable sharedSymbolTable] symbolWithString:@"+"]; }

- (BOOL)escaped { return YES; }

- (NSInteger) secondParserIndent {  return 0;}

- (BOOL)stillValid { return NO;}

- (NSRange) updateAt:(NSInteger)abslocation deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    //NSLog(@"updating Parser %@", self);
    [self parse];
    //NSLog(@"updated Parser %@", self);
    return self.range;
}


- (void) parse
{
    
    [self resetMemoization];
    NuObjectParser *previous = [self parseInSpecialCar];
    
    NuStringPartialParser *stringParser = [[NuStringPartialParser alloc]   initWithRoot:self.root
                                                                                 parent:self
                                                                               previous:previous
                                                                               location:self.location
                                                                               comments:nil];
    stringParser.escaped = self.escaped;
    stringParser.withOffset = previous.location;
    [self parseInItemWithParser:stringParser];
    
    if (!stringParser.terminatedByInterpolation)
    {
        self.cell.car = stringParser.cell.car;
        self.cell.cdr = [NSNull null];
        self.lastChild = nil;
        self.end = stringParser.end;
    }
    else
    {
        NuInterpolationParser *interpolationParser;
        do
        {
            interpolationParser = [[NuInterpolationParser alloc] initWithRoot:self.root
                                                                       parent:self
                                                                     previous:stringParser
                                                                     location:stringParser.end
                                                                     comments:nil];
            [self parseInItemWithParser:interpolationParser];
            
            if ([interpolationParser.lastChild isKindOfClass:[NuEndOfFileParser class]])
            {
                stringParser = nil;
                [self markError: @"Syntax Error"  reason:@"String not ended at the end of source" ];
            }
            else {
                stringParser = [[NuStringPartialParser alloc]  initWithRoot:self.root
                                                                     parent:self
                                                                   previous:interpolationParser
                                                                   location:interpolationParser.end
                                                                   comments:nil];
                stringParser.escaped = self.escaped;
                [self parseInItemWithParser:stringParser];
            }
            
            
        }   while (stringParser && stringParser.terminatedByInterpolation);
        
        self.lastChild = stringParser ? stringParser : interpolationParser;
        self.end = self.lastChild ? self.lastChild.end : self.withOffset;
    }

}

- (NSString *)type
{
    return [self.cell.car isKindOfClass:[NSString class]] ? @"string" : @"list";
}
/*
- (NSString *)parseTreeInfo
{
    if ([self.cell.car isKindOfClass:[NSString class]])        
        return [NSString stringWithFormat:@"(%@)", self.parserInfo];
    else
        return [super parseTreeInfo];
}
*/

+ (NSString *)trigger {return @"\""; }

@end


@implementation NuStringPartialParser

@synthesize terminatedByInterpolation = _terminatedByInterpolation;
@synthesize escaped = _escaped;
@synthesize withOffset = _withOffset;

- (id)init
{
    self = [super init];
    _terminatedByInterpolation = NO;
    _escaped = YES;
    _withOffset = NSNotFound;
    return self;
}


- (void)setWithOffset:(NSInteger)loc
{
    _withOffset = loc;
}

- (NSInteger)withOffset
{
    if (_withOffset == NSNotFound)
        return [super withOffset];
    else
        return _withOffset;
}


- (NSCharacterSet *)stringSpecialCharacters
{
    return self.escaped ? _interpolatingStringSpecialCharacters : _neInterpolatingStringSpecialCharacters;
}


- (void) parse
{
    
    [self resetMemoization];
    BOOL parsing = YES;
    NSMutableString * parsedString = [@"" mutableCopy];
    NSInteger lastStart = self.withOffset;
    NSInteger index;
    do
    {
        index = [self.root.job firstLocationOfCharactersInSet:self.stringSpecialCharacters
                                                     starting:lastStart];
        switch ([self.root.job characterAt: index]) {
            case '\n':
                [self.parent markError: @"Syntax Error"  reason:@"String ended by Newline" ];
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt: lastStart length: index - lastStart]];
                break;
                
            case '\0':
                self.root.job.incomplete = YES;
                self.root.job.state = PARSE_STRING;
                [self.parent markError: @"Syntax Error"  reason:@"String not ended at the end of source" ];
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                break;
                
            case '"':
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                index ++;
                break;
                
            case '#':
                if ([self.root.job characterAt:index+1] == '{' ){
                    self.terminatedByInterpolation = YES;
                    parsing = NO;
                    [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                    break;
                }
                else
                {
                    [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                    [parsedString appendCharacter:'#'];
                    lastStart = index + 1;
                    break;
                }
            case '\\':
                [parsedString appendString:[self.root.job sourceAt:lastStart length: index - lastStart]];
                @try {
                    
                    [parsedString appendCharacter:[self.root.job parseEscapeAt: &index]];
                }
                @catch (NSException *exception) {
                    [self.parent markError: @"Syntax Error"  reason:exception.description];
                    index++;
                }
                lastStart = index;
                break;
        }
    } while (parsing);
    self.end = index;
    self.cell.car =  parsedString;
}

+(NSString *)trigger { return @""; }

@end

@implementation NuInterpolationParser

- (id)specialCarObject { return [[NuSymbolTable sharedSymbolTable] symbolWithString:@"progn"]; }
- (Class)endOfListParserClass { return [NuEndOfBlockParser class] ; }
+ (NSString *)trigger {return @"#{";}

@end



@implementation NuEscapedIpStringParser

+(NSString *)trigger { return @"+\""; }

@end


@implementation NuNonescapedIpStringParser

- (BOOL)escaped {return NO;}

+ (NSString *)trigger { return @"-\""; }

@end


///////////////////////////////////////////////////////////////////////////////////

@implementation NuInterpolatingHeredocParser

- (id)specialCarObject { return [[NuSymbolTable sharedSymbolTable] symbolWithString:@"+"]; }

- (BOOL) escaped {return NO; }

- (NSInteger) secondParserIndent {  return 0;}

- (BOOL)stillValid { return NO;}

- (NuObjectParser *)parserToAlign
{
    return [[NuAlignParser alloc ] initWithRoot:self.root
                                         parent:self
                                       location:self.withOffset
                                         column:self.desiredColumn + self.class.trigger.length];
}

- (void)alignChildren
{
    if ([self.type isEqualToString: @"string"])
        for (NSInteger line = self.line + 1; line <= self.endLine; line ++)
        {
            NSInteger indent = self.desiredColumn + self.class.trigger.length;
            NSInteger codePos = [self.root.job.lineInfo codeIn:line];
            if (codePos != NSNotFound && [self.root.job characterAt:codePos ] == '_' && indent > 0)
            {
                indent --;
            }
            
            [self.root.job indent:line to: indent];
        }
    else [super alignChildren];
}


- (void)parse
{
    
    [self resetMemoization];
    NSInteger index = self.withOffset;
    NSInteger identifierEnd =[self.root.job firstLocationOfCharactersInSet:NuObjectParser.endOfAtomCharacters
                                                            starting:index];
    if (index == identifierEnd)
    {
        self.cell.car = @"";
        self.end = index;
        self.parent.unfinishedHereString = YES;
        [self markError: @"Syntax Error"  reason:@"No identifier" ];
        return;
    }
    NSString *identifier = [self.root.job sourceAt: index length: identifierEnd -  index];
    NSInteger stringStart = [self.root.job firstLocationOfCharactersInSet:[NSCharacterSet newlineCharacterSet]
                                                                 starting:identifierEnd-1] + 1;
    NSRange endIdRange = [self.root.job rangeOfString: identifier starting: stringStart];
    if (endIdRange.location == NSNotFound)
    {
        self.cell.car = @"";
        self.end = self.root.job.source.length;
        self.parent.unfinishedHereString = YES;
        [self markError: @"Syntax Error"  reason:@"No matching identifier found" ];
        return;
    }
    NSInteger indent = self.column + self.class.trigger.length;
    /*
    NSInteger firstNWSinLastLine = [self.root.job firstLocationOfCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@" \t"] invertedSet]
                                                              backwardFrom:endIdRange.location];
    
    
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember: [self.root.job characterAt:firstNWSinLastLine]])
    {
        indent = endIdRange.location - (firstNWSinLastLine + 1);
    }
    else
        indent = 0;*/

    NuObjectParser *previous = [self parseInSpecialCar];
    
    NuHeredocPartialParser *stringParser = [[NuHeredocPartialParser alloc] initWithRoot:self.root
                                                                                 parent:self
                                                                               previous:previous
                                                                               location:self.location
                                                                               comments:nil];
    stringParser.endOfString = endIdRange.location;
    stringParser.indent = indent;
    stringParser.escaped = self.escaped;
    stringParser.startWithNewLine = YES;
    stringParser.withOffset = stringStart;
    [self parseInItemWithParser:stringParser];
    
    if (!stringParser.terminatedByInterpolation)
    {
        self.cell.car = stringParser.cell.car;
        self.cell.cdr = [NSNull null];
        self.lastChild = nil;
    }
    else
    {
        do
        {
            NuInterpolationParser *interpolationParser = [[NuInterpolationParser alloc] initWithRoot:self.root
                                                                                              parent:self
                                                                                            previous:stringParser
                                                                                            location:stringParser.end
                                                                                            comments:nil];
            [self parseInItemWithParser:interpolationParser];
            
            stringParser = [[NuHeredocPartialParser alloc] initWithRoot:self.root
                                                                 parent:self
                                                               previous:interpolationParser
                                                               location:interpolationParser.end
                                                               comments:nil];
            stringParser.endOfString = endIdRange.location;
            stringParser.indent = indent;
            stringParser.escaped = self.escaped;
            // these are the default values, so ...
            // stringParser.startWithNewLine = NO;
            // stringParser.withOffset = interpolationParser.end;
            [self parseInItemWithParser:stringParser];
            
        }   while (stringParser.terminatedByInterpolation);
        
        self.lastChild = stringParser;
        self.lastChild.end = endIdRange.location + endIdRange.length;
    }
    self.end = endIdRange.location + endIdRange.length;
}

- (NSString *)type
{
    if ([self.cell.car isKindOfClass:[NSString class]])
        return @"string" ;
    else return [super type];
}

+ (NSString *)trigger { return @"<<-"; }

@end

@implementation NuHeredocPartialParser

@synthesize endOfString = _endOfString;
@synthesize indent = _indent;
@synthesize terminatedByInterpolation = _terminatedByInterpolation;
@synthesize escaped = _escaped;
@synthesize withOffset = _withOffset;

- (id)init
{
    self = [super init];
    _terminatedByInterpolation = NO;
    _indent = 0;
    _endOfString = NSNotFound;
    _escaped = NO;
    _withOffset = NSNotFound;
    _startWithNewLine = NO;
    return self;
}

- (void)setWithOffset:(NSInteger)loc
{
    _withOffset = loc;
}

- (NSInteger)withOffset
{
    if (_withOffset == NSNotFound)
        return [super withOffset];
    else
        return _withOffset;
}

- (NSCharacterSet *)stringSpecialCharacters
{
    return self.escaped ? _interpolatingHeredocSpecialCharacters : _neInterpolatingHeredocSpecialCharacters;
}


- (void)alignChildren
{
    for (NSInteger line = self.line + 1; line <= self.endLine; line ++)
    {
        NSInteger indent = self.parent.desiredColumn + self.parent.class.trigger.length;
        NSInteger codePos = [self.root.job.lineInfo codeIn:line];
        if (codePos != NSNotFound && [self.root.job characterAt:codePos ] == '_' && indent > 0)
        {
            indent --;
        }
        
        [self.root.job indent:line to: indent];
    }

}

- (void)parse
{
    
    [self resetMemoization];
    
    BOOL parsing = YES;
    NSMutableString * parsedString = [@"" mutableCopy];
    NSInteger searchStart = self.withOffset;
    NSInteger currentIndentLocation = self.startWithNewLine ? self.withOffset + self.indent : self.withOffset;
    NSInteger index;
    
    do
    {
        index = [self.root.job firstLocationOfCharactersInSet:self.stringSpecialCharacters
                                                     starting:searchStart];
        if (index > self.endOfString)
        {
            index = self.endOfString;
            if (index > currentIndentLocation)
            {
                NSInteger partialStart;
                if (searchStart > currentIndentLocation)
                    partialStart = searchStart;
                else
                    partialStart = currentIndentLocation;
                [parsedString appendString:[self.root.job sourceAt: partialStart length: index - partialStart]];
            }
            break;
        }
        
        switch ([self.root.job characterAt: index]) {
            case '\n':
                if (index > currentIndentLocation)
                {
                    NSInteger partialStart;
                    if (searchStart > currentIndentLocation)
                        partialStart = searchStart;
                    else
                        partialStart = currentIndentLocation;
                    [parsedString appendString:[self.root.job sourceAt: partialStart length: index - partialStart]];
                }
                [parsedString appendCharacter:'\n'];
                index++;
                currentIndentLocation = index + self.indent;
                searchStart = index;
                break;
                
            case '\0':
                self.root.job.incomplete = YES;
                self.root.job.state = PARSE_HERESTRING;
                [self.parent markError: @"Syntax Error"  reason:@"String not ended at the end of source" ];
                parsing = NO;
                if (index > currentIndentLocation)
                {
                    NSInteger partialStart;
                    if (searchStart > currentIndentLocation)
                        partialStart = searchStart;
                    else
                        partialStart = currentIndentLocation;
                    [parsedString appendString:[self.root.job sourceAt: partialStart length: index - partialStart]];
                }

                break;
                
            case '#':
                if ([self.root.job characterAt:index+1 ] == '{') {
                    self.terminatedByInterpolation = YES;
                    parsing = NO;
                    if (index > currentIndentLocation)
                    {
                        NSInteger partialStart;
                        if (searchStart > currentIndentLocation)
                            partialStart = searchStart;
                        else
                            partialStart = currentIndentLocation;
                        [parsedString appendString:[self.root.job sourceAt: partialStart length: index - partialStart]];
                    }

                    break;
                }
                else
                {
                    if (index > currentIndentLocation)
                    {
                        NSInteger partialStart;
                        if (searchStart > currentIndentLocation)
                            partialStart = searchStart;
                        else
                            partialStart = currentIndentLocation;
                        [parsedString appendString:[self.root.job sourceAt: partialStart length: index - partialStart]];
                    }

                    [parsedString appendCharacter:'#'];
                    searchStart = index + 1;
                    break;
                }
            case '\\':
                if (index > currentIndentLocation)
                {
                    NSInteger partialStart;
                    if (searchStart > currentIndentLocation)
                        partialStart = searchStart;
                    else
                        partialStart = currentIndentLocation;
                    [parsedString appendString:[self.root.job sourceAt: partialStart length: index - partialStart]];
                }
                @try {
                    
                    [parsedString appendCharacter:[self.root.job parseEscapeAt: &index]];
                }
                @catch (NSException *exception) {
                    [self.parent markError: @"Syntax Error"  reason:exception.description];
                    index++;
                }
                searchStart = index;
                break;
        }
    } while (parsing);
    self.end = index;
    self.cell.car =  parsedString;

}

+ (NSString *)trigger { return @""; }

@end

///////////////////////////////////////////////////////////////////////////////////


@implementation NuEscapedIpHeredocParser

- (BOOL)escaped { return YES; }
+ (NSString *)trigger { return @"<<+"; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuRegexParser

- (void)parse
{
    
    BOOL parsing = YES;
    NSMutableString * parsedString = [@"/" mutableCopy];
    NSInteger lastStart = self.withOffset;
    NSInteger index;
    do
    {
        
        [self resetMemoization];
        index = [self.root.job firstLocationOfCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\0/\\"]
                                                 starting:lastStart];
        switch ([self.root.job characterAt: index]) {
            case '\0':
                self.root.job.incomplete = YES;
                self.root.job.state = PARSE_REGEX;
                [self markError: @"Syntax Error"  reason:@"Regular expression not ended at the end of source" ];
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt: lastStart
                                                            length: index - lastStart]];
                break;
                
            case '/':
                parsing = NO;
                [parsedString appendString:[self.root.job sourceAt: lastStart
                                                            length: index - lastStart + 1]];
                index ++;
                break;
                
            case '\\':
                [parsedString appendString:[self.root.job sourceAt: lastStart
                                                            length: index - lastStart+2]];
                index += 2;
                lastStart = index;
                break;
        }
    } while (parsing);
    lastStart = index;
    index = [self.root.job firstLocationOfCharactersInSet:
             [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz"] invertedSet]
                                starting: index];
    [parsedString appendString:[self.root.job sourceAt:lastStart
                                                length: index - lastStart]];
    self.end = index;
    id regex = nil;
    @try {
        regex = [NuParseJob regexWithString: parsedString];
    }
    @catch (NSException *exception) {
        
        [self markError: @"Syntax Error"  reason:exception.reason];
    }
    self.cell.car = regex;
}

- (NSString *)type
{
    return @"regex";
}

+ (NSString *)trigger { return @"/"; }

@end


///////////////////////////////////////////////////////////////////////////////////

@implementation NuQuoteAndCharacterParser

@synthesize isCharacter;


- (void) putCharacterToCar: (NSInteger) character
{
    self.cell.car = [NSNumber numberWithInt:character];
}



-(BOOL) parseCharacterLiteral;
{
    
    if ([self.root.job characterAt:self.withOffset] == '\'') return NO;// succeeding quotes should be interpreted as reader macro
                                                                        // quote characters should be escaped

    NSInteger possibleEnd = [self.root.job firstLocationOfCharactersInSet:[NuObjectParser endOfAtomCharacters] starting:self.withOffset + 1];
    if ([self.root.job characterAt:possibleEnd - 1 ] == '\'')
    {
        NSInteger secondQuoteLocation = possibleEnd - 1;
        if ([self.root.job characterAt:self.withOffset] != '\\')
        {
            if (secondQuoteLocation == self.withOffset + 1)
            {
                [self putCharacterToCar:[self.root.job characterAt:self.withOffset]];
                self.end = self.withOffset + 2;
                return YES;
            }
            else if (secondQuoteLocation == self.withOffset + 4)
            {
                NSInteger a,b,c,d;
                if (isalnum(a = [self.root.job characterAt:self.withOffset]) &&
                    isalnum(b = [self.root.job characterAt:self.withOffset + 1]) &&
                    isalnum(c = [self.root.job characterAt:self.withOffset + 2]) &&
                    isalnum(d = [self.root.job characterAt:self.withOffset + 3]))
                {
                    [self putCharacterToCar: (a << 24 | b << 16 | c << 8 | d)];
                    self.end = self.withOffset + 5;
                    return  YES;
                }
                else
                {
                    self.cell.car = [NSNull null];
                    self.end = self.withOffset + 5;
                    [self markError:@"Syntax Error" reason:@"no valid four character integer"];
                    return YES;
                }
            }
            else
            {
                // this means there are 2 quote characters with no space in between
                // that couldn't get parsed as a chaacter
                // this is an error but should be interpreted as a try to make a character not as a quote reader macroe
                self.cell.car = [NSNull null];
                self.end = possibleEnd;
                
                [self markError:@"Syntax Error" reason:@"no character literal"];
                return YES;
            }
        }
        else
        {
            // now we have '\
            // this will always get interpreted as a character literal
            NSInteger c = [self.root.job characterAt:self.withOffset + 1];
            if (secondQuoteLocation == self.withOffset + 2)
            {
                
                switch(c) {
                    case 'n': c=0x0a;  break;
                    case 'r': c=0x0d;  break;
                    case 'f': c=0x0c;  break;
                    case 't': c=0x09;  break;
                    case 'b': c=0x08;  break;
                    case 'a': c=0x07;  break;
                    case 'e': c=0x1b;  break;
                    case 's': c=0x20;  break;
                }
                [self putCharacterToCar: c];
                self.end = self.withOffset + 3;
                return  YES;
            }
            else if (secondQuoteLocation == self.withOffset + 4)
            {
                switch (c) {
                    case '0': case '1': case '2': case '3': case '4':
                    case '5': case '6': case '7': case '8': case '9':
                    {
                        char c1 = [self.root.job characterAt:self.withOffset + 2];
                        char c2 = [self.root.job characterAt:self.withOffset + 3];
                        @try {
                            
                            c =nu_octal_digits_to_unichar(c, c1, c2);
                            [self putCharacterToCar: c];
                            self.end = self.withOffset + 5;
                            return  YES;
                            break;
                        }
                        @catch (NSException *exception) {
                            
                            self.cell.car = [NSNull null];
                            self.end = self.withOffset + 5;
                            [self markError:@"Syntax Error" reason:@"no valid octal code"];
                            return YES;
                        }
                    }
                        
                    case 'x':
                    {
                        char c1 = [self.root.job characterAt:self.withOffset + 2];
                        char c2 = [self.root.job characterAt:self.withOffset + 3];
                        
                        @try {
                            
                            c = nu_hex_digits_to_unichar(c1, c2);
                            [self putCharacterToCar: c];
                            self.end = self.withOffset + 5;
                            return  YES;
                        }
                        @catch (NSException *exception) {
                            
                            self.cell.car = [NSNull null];
                            self.end = self.withOffset + 5;
                            [self markError:@"Syntax Error" reason:@"no valid hex code"];
                            return YES;
                        }
                        break; // for the sake of completeness
                    }
                        
                    default:
                        
                        self.cell.car = [NSNull null];
                        self.end = self.withOffset + 5;
                        [self markError:@"Syntax Error" reason:@"no character code"];
                        return YES;
                        
                }
            }
            else if (secondQuoteLocation == self.withOffset + 6 && c == 'u')
                
            {
                char c1 = [self.root.job characterAt:self.withOffset + 2];
                char c2 = [self.root.job characterAt:self.withOffset + 3];
                char c3 = [self.root.job characterAt:self.withOffset + 4];
                char c4 = [self.root.job characterAt:self.withOffset + 5];
                
                @try {
                    c=nu_unicode_digits_to_unichar(c1, c2, c3, c4);
                    [self putCharacterToCar: c];
                    self.end = self.withOffset + 7;
                    return  YES;
                }
                @catch (NSException *exception) {
                    
                    self.cell.car = [NSNull null];
                    self.end = self.withOffset + 7;
                    [self markError:@"Syntax Error" reason:@"no valid hex code"];
                    return YES;
                }
            }
            else
            {
                self.cell.car = [NSNull null];
                self.end = [self.root.job firstLocationOfCharactersInSet:[NuObjectParser endOfAtomCharacters] starting:self.withOffset];
                [self markError:@"Syntax Error" reason:@"no valid escape sequence"];
                return YES;
            }
        }
    }
    return NO;
}

- (id)specialCarObject { return [self.root.symbolTable symbolWithString:@"quote"]; }

- (int)listLength { return 2; }

- (BOOL)stillValid {return NO;}

- (void)parse
{
    
    [self resetMemoization];
    if (!(self.isCharacter = [self parseCharacterLiteral]))
        [super parse];

}

- (BOOL)atom
{
    return self.isCharacter;
}

- (NSString *)type
{
    return self.isCharacter ? @"character" : @"quotation";
}

+ (NSString *)trigger { return @"'"; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuQuasiquoteParser

- (id)specialCarObject { return [[NuSymbolTable sharedSymbolTable] symbolWithString:@"quasiquote"]; }
- (int)listLength { return 2; }
+ (NSString *)trigger { return @"`"; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuQuasiquoteEvalParser

- (id)specialCarObject { return [[NuSymbolTable sharedSymbolTable] symbolWithString:@"quasiquote-eval"]; }
- (int)listLength { return 2; }
+ (NSString *)trigger { return @","; }

@end

///////////////////////////////////////////////////////////////////////////////////

@implementation NuQuasiquoteSpliceParser

- (id)specialCarObject { return [[NuSymbolTable sharedSymbolTable] symbolWithString:@"quasiquote-splice"]; }
- (int)listLength { return 2; }
+ (NSString *)trigger { return @",@"; }

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuEndOfFileParser

+ (NSString *)trigger { return @"\0"; }

- (void)parse
{
    [super parse];
    if (![self.parent isKindOfClass:[NuRootParser class]])
    {
        self.root.job.incomplete = YES;
        [self markError: @"Syntax Error"  reason:@"Open S-expression at the end of the source" ];
    }
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuIgnoreNextItemParser


+ (NSString *)trigger { return  @"~"; }

- (BOOL)atom {return YES;}

- (int)listLength {return 1;}

- (void)parse
{
    
    self.cellIgnored = YES;
    [super parse];
    if (!self.lastChild )
        [self markError: @"Syntax Error"  reason:@"Ignoring the end of list is not possible"];
}


@end

///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuInlineEvaluationParser
- (int)listLength {return 1;}

+ (NSString *)trigger { return  @"%"; }

- (void) evaluate
{
    if (!self.lastChild )
        [self markError: @"Syntax Error"  reason:@"Evaluating the end of list is not possible"];
    else  if (!self.root.job.preventEvaluation && !self.root.job.indenting)
    {
        for (id parser in self.descendants) {
            if ([parser respondsToSelector:@selector(invalidateResult)]) {
                [parser invalidateResult];
            }
        }
        self.cell.car = [self.lastChild evalWithContext:self.root.job.context];
        
    }
}


- (void)parse
{
    [super parse];
    [self evaluate];
}

- (NSRange)updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    NSRange range = [super updateAt:location deleted:deletionLength inserted:insertionLength];
    [self evaluate];
    return range;
}

@end


///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuLiveEvaluationParser

+ (NSString *)trigger {return @"^";}


//- (BOOL)cellIgnored {return YES;}

- (void) evaluate
{
    if (!self.lastChild )
        [self markError: @"Syntax Error"  reason:@"Evaluating the end of list is not possible"];
    else  if (!self.root.job.preventEvaluation && !self.root.job.indenting)
    {
        for (id parser in self.descendants) {
            if ([parser respondsToSelector:@selector(invalidateResult)]) {
                [parser invalidateResult];
            }
        }
       [self.lastChild evalWithContext:self.root.job.context];
        
    }
}



@end



///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuPrefixResultLoggingParser

- (int)listLength {return 1;}

- (void)hide
{
    [super hide];
    self.logEvaluationResultEnabled = YES;
}

+ (NSString *)trigger {return @"?";}

@end

@implementation NuPostfixResultLoggingParser

- (int) listLength {return 1;}

- (void)hide
{
    [super hide];
    self.logEvaluationResultEnabled = YES;
}


+ (NSString *)trigger {return @"-?";}


@end

@implementation NuTriggerForResultLoggingListParser

- (void)convertForDebugging:(BOOL) flag
{
    
    self.parent.logEvaluationResultEnabled = flag;
    self.parent.displayParserWithinRange = flag;
}

- (BOOL) isAtRightPlace
{
    Class nextParserClass = [self.parent matchingParserClassAfter:self.end];
    return [[nextParserClass class] isSubclassOfClass:[NuEndOfListParser class]]
         ||[[nextParserClass class] isSubclassOfClass:[NuPostfixListParser class]]
         ||[[nextParserClass class] isSubclassOfClass:[NuResultDisplayParser class]];
}

- (void)parse
{
    [self resetMemoization];
    self.end = self.withOffset;
    self.cell = nil;
    self.cellIgnored = YES;
    /*NuObjectParser *next = [self.parent parseIn:1 itemsAfter:self.end previous:self];
    if (next != self && ![next isKindOfClass:[NuResultDisplayParser class]])
        [self markError: @"Syntax Error"  reason:@"End Of List expected"];
    else
    {
        [self convertForDebugging];
    }
    self.nextPreviousParser = next;
     */
    if ([self isAtRightPlace])
    {
        [self convertForDebugging:YES];
    }
    else
    {
        [self markError: @"Syntax Error"  reason:@"End Of List expected"];
        [self convertForDebugging:NO];
    }
    
}

- (NSRange)updateAt:(NSInteger)location deleted:(NSInteger)deletionLength inserted:(NSInteger)insertionLength
{
    NSRange range = [super updateAt:location deleted:deletionLength inserted:insertionLength];
    
    if ([self isAtRightPlace])
    {
        [self convertForDebugging:YES];
    }
    else
    {
        [self markError: @"Syntax Error"  reason:@"End Of List expected"];
        [self convertForDebugging:NO];
    }
    return range;
}

- (NuObjectParser *)evaluatedParser {return self;}

+ (NSString *)trigger {return @"|?";}

@end





///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuResultDisplayParser

+ (NSString *)trigger {return @"=>";}

- (BOOL)atom {return NO;}

- (NSString *)type {return @"result";}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuErrorParser

- (NSString *) type {return @"error";}

- (void)parse
{    
    [self resetMemoization];
    self.end = self.withOffset;
    self.cell = [[NuCell alloc] init];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuExtraneousParensParser

+ (NSString *)trigger { return @")"; }

- (NuError *)error
{
    [self markError: @"Syntax Error"  reason:@"Paren has no matching partner"];
    return [super error];
}


@end

///////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NuExtraneousBracketsParser

+ (NSString *)trigger { return @"]"; }

- (NuError *)error
{
    [self markError: @"Syntax Error"  reason:@"Bracket has no matching partner"];
    return [super error];
}

@end



