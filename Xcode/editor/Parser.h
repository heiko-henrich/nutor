 //
//  Parser.h
//  Nu
//
//  Created by Heiko Henrich on 23.04.13.
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*!
    This file contains a proposal for a new Nu parser,
    which is suited for use in an editor.
    The main features of this parser are:
    -   a tight connection between source code and hte resulting code cell,
        so immediate feedback to the source code from the parsed and evlauated cells
        (like eg. syntax highlighting) is quite easy.
    -   "live parsing": it is possible to process incremental changes to the source code,
        so if theres's an update like a new inserted or deleted character,
        only the relevant part of the code tree is changed.
    -   auto indentation:
        every change to the source gets reflected in a proposal for changing the indentation
        acoording to lisp rules (similar to the things beautifier.nu is doing now)
    -   Extensibility:
        The OO-Design made it possiple to easily extend the syntax of Nu.
        This is not always a good thing.
        I couldn't resist to implement some extensions to Nu, which are sometimes more
        or less useful. So the current implementation is just to show off some things that are possible.
        What I like is the dot- and arrow-syntax, and a kind of indenting here strings.
        Also the possibility to probe and display intermediate evaluation results is quit fun
        in a live evaluation context.
    -   a kind of code database:
        The source code is stored together with the resulting code cell tree and the corresponding parser objects
        in a "parse job". these parse jobs can be stored in a dictionary.
    -   live evaluation:
        It is possible evaluate certain portions of code everytime, the code changes.
        In connection with the capability of desplaying intermediate evaluation results in the source code
        it's a (maybe not alwys useful) but fun way of coding, with immediate feedback.
        Furthermore, since the source code doesn't need to get reparsed all the time,
        changes  to functions, methods or quoted lists have an immediate effect.
        (Dangerous!)

    The base class of this parser is NuObjectParser. Every instance of it is responsible for parseing a certain 
    token or item of the source code like a string, a list or a symbol.
    Every token type has its own subclass of NuObjectParser.
    The most important subclass is NuList Parser,
    which is responsible for, you guess it, parsing lists.
    The list parser chooses the corrosponding classes of the children NuObjectParser instances and connects them together.
    Every parser has a parse and an update method
    and holds references to the parsed list cell (actually the car of this cell holds the parsed item)
    the parent and root parser and to the location in the source code
    and provides a method for aligning it's children in the source code.
    Every parsed cell gets a reference to the correspoinding parser object,
    so a connection from an evaluated cell to the source code is easily established.
 
    A NuParseJob object is the main entry point for this parser:
    It holds references to the source code, the parsed code cell tree, the parser tree,
    and provides  on the one hand methods for the extern use of the parser and on the other hand various helper
    methods used internally by the NuObjectParser subclasses.
 
    NutorParser is a subclass of NuParser and tries to emulate and extend it's behavour.
    It also maintains a ParseJob dictionry and looks for parsejobs correspoinding a certain sourceID.
    Could be extended to a kind of remote parser.
 
    NuParserClassRegistry defines the grammar:
    Basically it is a dictionary with a trigger (provided by the class method trigger) as a key
    and the correspoinding Parser class as value.
    Their is also a strict Nu syntax defined.
 
    There's a category of the Nu class,
    which overrides it in a way, that parser and sharedParser Methods are returning an instance of NutorParser
 
    This is my third iteration, developping a nu parser.
    Another approach could be more abstract, functional and rule based, maybe implementing a BNF like
    DSL in Nu. But this works (besides the to be discovered bugs) and
    regarding the simpolicity of Nu,
    it's already like shooting sparrows with cannons, like the germans say.
 
    TODOs
    -   Comments need their own NuObjectParser.
    -   indentChanges should send TextChange arrays.
    -   live evaluation and normal evaluation don't always work good together
    -   the charactersets provided by NuObjectParser class methods should go in an instance of NuParserClassRegistry.
    -   compiler directives to turn on "legacy" mode
 
    EXPERIMENTAL SYNTAX EXTENSIONS
    
    Trigger |   Meaning
    -------------------------------------
            |
    " -" +" |   string with parsed interpolation
            |
    $" $-"  |   strings without parsed interpoation
       $+"  |
            |
    <<- <<+ |   herestring (with parsed interpolation) and indentation:
            |   that means everything until the column, the identifier starts gets cut off
            |
    $<<-    |   herestrings without indentation and parsed interpolation
    $<<*    |
            |
        .   |   a dot joins two items to a list, which has the same result as the objc-dot-syntax
            |
        <-  |   .
            |
        :   |   joins three items together to build a list (not good)
            |
        [   |   array literal, ends with ']' (not good)
            |
        {   |   start of a Block, ends with '}' (also not so good)
            |
        |   |   in a Block this seperates the parameters form the code
            |
        <   |   start of a long symbol, which can contain whitespaces and all characters, ends with '>'
            |
        ~   |   ignores the following item: good to "comment out" a nu expression
            |
        ?   |   inserts the result of the evaluation of the following item into the code
            |
        -?  |   inserts the result of the evaluation of the previous item into the code
            |
        |?  |   inserts the result of the evaluation of the current list into the code
            |
        =>  |   the following item is an inserted result and gets ignored
            |
        %   |   immediately evaluates the folloing item in the parser context and inserts the resutl into the parsed code
            |
        ^   |   the following item gets evaluated in the destination context after the parsing of a change in the source code.
 
 
*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "Nu.h"

///////////////////////////////////////////////////////////////////////////////////////////

/*! protocol used by Nu ParseJob to provide fresh NuCells of any kind.
 Could for example deliver a cell with debugging capabilities (now solved differently ...) */
@protocol NuCellProvider <NSObject>

- (NuCell *) newCell;

- (NuCellWithComments *)newCellWithComments;


@end

#import "Debugger.h"

@class NuListParser;
@class NuObjectParser;
@class NuRootParser;
@class NuSpecialObjectParser;
@class NuEndOfListParser;
@class NuResultDisplayParser;
@class NuParseJob;
@class NuParserClassRegistry;


///////////////////////////////////////////////////////////////////////////////////////////

/*! this class suclasses NuParser and tries emulate all its functions 
    opens and parens don't work yet but could be implemented easily when ecessary ...
    also this parser provides some experimental extensions like dot-Notation  and some 
    changes in herestrings, like indentation and #{} parsing
    a "legacy" version is not a big deal ...*/
@interface NutorParser : NuParser


/*! a dictionary to store different parsejobs, like different files or other portions of code,
    to have the possibility to update them independently */
@property (nonatomic)NSMutableDictionary * jobs;

/*! a default job, used by parse: */
@property (nonatomic) NuParseJob *defaultJob;

- (id) init;
- (void) reset;
+ (NutorParser *) shared;


/*! parses for source code and stores it,
    if you want to update or reparse the same portion of code
    useful for a remote parser, also parse:asIfFromFile: uses thes mechanism.
    the source and the resulting code are stored as a ParseJob in a dictionary with sourceID as key
    for versioning there is also a stamp
    overrides NuParser parse:
    Parser errors through exception arn't yet implemented
 */
- (id) parse:(NSString *)string for: (NSString *) sourceID stamp: (id) stamp;


/*! just the overwritten main entry point of the super class 
     calls the method above
     but imitates the behaviour of NuParser 
     affects incomplete and state */
- (id) parse: (NSString *) string;


/*! just the overwritten main entry point of the super class
    calls the method above
    but imitates the behaviour of NuParser 
    does not deal with linenum and filenum as the superclass does 
    stores the source and resulting code  as a NuParserJob in self.jobs
    with the NSString version of filename as the key. */
- (id) parse:(NSString *)string asIfFromFilename:(const char *) filename;

/*! updates an already parsed source and reparses the changed parts 
    I didn't plan to do something like that, I didn't thought it was possible.
    But somehow after several iterations of coding it evolved that way.
    Uses: - live programming (you know the "bret victor demo"?)
          - keep syntax highlighting, indentation etc. in an editor up to date, 
            with very little computation cost. That's what I did. */
- (NuCell *) update: (NSString *) sourceID
                 at: (NSInteger) location
             delete: (NSInteger) deletionLength
             insert: (NSString *) string
              stamp: (NSString *) stamp;

/*! semi automatic indetation 
    retruns an list with proposed indetation changes for a given location in the source code. */
//- (NuCell *)indentAt: (NSInteger)  location for:(NSString *)senderTag stamp:(NSString *)stamp;

/*! models the behaviour of NuParser according open s-expr at the end of source */
- (BOOL)incomplete;


/*! models the behaviour of NuParser according the state of parsing at the end of souce */
#define PARSE_NORMAL     0
#define PARSE_COMMENT    1
#define PARSE_STRING     2
#define PARSE_HERESTRING 3
#define PARSE_REGEX      4
- (NSInteger) state;

/*! generates a unique (per session) sender tag */
+ (NSString *) generateSourceID;

@end
/*
///////////////////////////////////////////////////////////////////////////////////////////

@interface NuParser (hack)

+ (id) oldAlloc;

@end
*/

///////////////////////////////////////////////////////////////////////////////////////////

@interface Nu (hack)

+ (NuParser *)oldParser;
+ (NuParser *)oldSharedParser;

@end

@interface Nu_alt_parse_operator : NuOperator
@end


///////////////////////////////////////////////////////////////////////////////////////////

@interface TextChange : NSObject

@property (nonatomic) NSInteger location;
@property (nonatomic) NSInteger length;
@property (nonatomic) NSMutableString  *string;

+ (TextChange *) withLocation: (NSInteger) location
                       length: (NSInteger) length
                       string: (NSString *) string;
+ (TextChange *) withRange: (NSRange) range
                    string: (NSString *) string;
- (NSRange) range;
- (void) setRange: (NSRange) range;
- (NSInteger) end;
- (void) setEnd: (NSInteger) end;

@end



/*! a helper class to provide conversion between the location in a string and the corresponding line and column */
@interface LineInfo : NSObject

@property (nonatomic) NSString *string;
/*! an array with line starting points*/
@property (nonatomic) NSMutableArray *lines;
/*! an array with locations of the first non ws in line, NSNotFound if there is any */
@property (nonatomic) NSMutableArray *codes;
/*! an array for proposed indents */
@property (nonatomic) NSMutableArray *indents;

- (id)initWithString: (NSString *) string;
/*! parses th line info */
- (LineInfo *) parse;
/*! updates the lin info according to the changes made in string */
- (void) updateAt: (NSInteger) location  delete: (NSInteger) deletionLength  insert: (NSInteger) insertionLength;
/*! number of lines */
- (NSInteger) count;
- (BOOL) is: (NSInteger) location in: (NSInteger) line;
- (NSInteger) lineAt: (NSInteger) location;
- (NSRange) linesInRange: (NSRange ) range;
- (NSRange) range: (NSInteger) line;
- (NSRange) rangeAt: (NSInteger) location;
- (NSInteger) columnFor: (NSInteger) location in: (NSInteger) line;
/*! returns an arry with array[0] = line and array[1] = column
    (I miss multple return values in obj c (and nu too)) */
- (NSArray *) lineColAt: (NSInteger) location;
- (NSInteger) codeColumnIn: (NSInteger) line;
- (NSInteger) location: (NSInteger) line;
- (NSInteger) endOf: (NSInteger) line;
- (NSInteger) codeIn: (NSInteger) line;

@end

/*! an error object returned by a NuObjectParser to communicate syntax errors for the editor without generating exceptions
    could be used for execution errors and erceptions too*/
@interface NuError : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *reason;
@property (nonatomic) id userInfo;
@property (nonatomic,weak) NuObjectParser *parser; // weak, no strings attached ...
@property (nonatomic) NSRange range;
@property (nonatomic) id sourceID;
@property (nonatomic) id stamp;
@property (nonatomic) NuException *exception;

- (id)init;

+ (NuError *) errorWithName: (NSString *) name
                     reason: (NSString *) reason
                     parser: (NuObjectParser *) parser
                      range: (NSRange) range
                   sourceID: (id) sourceID
                      stamp: (id) stamp;

- (NSString *)description;

@end





///////////////////////////////////////////////////////////////////////////////////////////


/*! this is the main class of the new NuParser
    an instance of NuParseJob is reponsible for the parsing of a certain portion of source code
    that can be incrementally updated or changed as a whole
    it provides also indenting for use with an editor*/
@interface NuParseJob : NSObject <NuCellProvider>

/*! the source string. mut be mutable. line info gets parsed by assignment.*/
@property (nonatomic, strong) NSMutableString *source;

@property (nonatomic) LineInfo *lineInfo;

/*! a possibly unique source id, should be set by the owner */
@property (nonatomic) id sourceID;

@property (nonatomic)  id stamp;

/*! an optional cell provider (see above) if nil, NuParseJob delivers standard cells.
    could be used eg for delivering a kind of debugging cells .. */
@property (nonatomic, strong) id <NuCellProvider> cellProvider;

/*! the root object parser 
    is the root object af parser hirarchy corresponding to the parsed cell tree.
    every "parser" is reponsible for a part of the source code and parses exactly one
    NuCell. this root parser is a special subclass of NuListParser and the entry point 
    for parsing and updating. the parser tree is independent of the code tree
    so NuCells don't need to have references to the parsers. 
    Though by default there are references to cells as associated objects, 
    so it is possible to get meta information about the corresponding parser and the source.
    important for debugging.*/
@property (nonatomic) NuRootParser * rootParser;

/*! the parsed code tree. ready to be evaluated */
@property (nonatomic)  NuCell * root;

/*! the parser registry which defines the parsing rules 
    must be set before  calling parse
    defaults to [NuParserRegistry shared] */
@property (nonatomic) NuParserClassRegistry *registry;

/*! if YES, the parser generates an indentation proposal every time, the source has changed.
    get it by calling indentDeltas.
    indentation is quite dictatatorial (I'm german, that's the way we are ...).
    there are no options but cdarIndent below */
@property (nonatomic)  BOOL autoIndent;

/*! if (temporarilly) set YES, the parser doesn't generate indent information 
    in order to prevent recursive cycles. use this before sending indentDeltas back via updateAt: ... 
    could be soved more elegantly somehow ...*/
@property (nonatomic) BOOL indenting;
@property (nonatomic) BOOL preventEvaluation;


/*! the indentation works baically the way, that everything is aligned with the second item (cdar) in a list 
    if the cdar is in a separate line cdarIndent sets the number of spaces the cdar is indented.
    defaults to 2. some  lisp indentation rules require 0, which imho is less readable but doesn't
    get eg in the way of a let expression, which looks kind of strange otherwise.*/
@property (nonatomic) NSInteger cdarIndent;

/*! a context for inline evluation */
@property (nonatomic, weak) NSMutableDictionary *context;

@property (nonatomic) NSMutableArray *resultParsersToUpdate;

@property (nonatomic, readonly) NSUInteger resultStamp;

@property (nonatomic) NSMutableDictionary *currentExceptions;

- (void) prepareForEvaluation;

/*! will be set if there are open s-expressions or unfinished strings at the end of source */
@property (nonatomic) BOOL incomplete;

/*! if there are unfinished herestrings or regexes at the end of source state is set accordingly */
@property (nonatomic) NSInteger state;

/*! designated initializer */
- (id)init;
//- (id) initWithCoder: (NSCoder *) coder;
// - (void)encodeWithCoder: (NSCoder *)coder;
- (id) initWithSource: (NSMutableString *) string
                   id: (id) sourceID
                stamp: (id) stamp;

/*! parses the source, doesn't get automatically called by init*/
- (NuCell *) parse;

/*! the magic update method - updates lineinfo and indenting too */
- (NuCell *) updateAt: (NSInteger) location  delete: (NSInteger) deletionLength  insert: (NSString *) string;

/*! just returns an instance of NuError for this ParseJob 
    used by NuObjectParser subclasses, but could also used in conjuction with an catched exception*/
- (NuError *) error: (NSString *) name  parser: (NuObjectParser *) parser reason: (NSString *) reason;

/*! computes the indents of a single line and its descendants
    result can be obtained by indentDeltas*/
- (void) alignLineAt: (NSInteger) location;

/*! method to get the last indent changes as a list
    with format (indents (line indentchange) (line indentchange) ...)
    the list is ordered descending (it's more naturally to start inserting
    with the last line) , lines without change are omitted.
    after reading the indent-array  in lineInfo gets set to NSNotFound */
- (NuCell *) indentDeltas;

/*! just sets manually the indent of a line */
 - (void)indent:(NSInteger)line to:(NSInteger)indentColumn;

/*! returns the desired indent for a given line before calling indentDeltas 
    used by NuObjectParsers */
- (NSInteger) indentAt: (NSInteger) line;

/*! ivaluates all live evaluation parsers */
- (void) evaluateLiveParsers;

/*! (re-) indents all lines starting with the root parser */
- (void) indentAll;

/*! */
- (void) updateResultFor: (id) parser;


/*! helper methods for NuObjectParsers */
- (NSString *) sourceForRange: (NSRange) range;
- (NSString *)sourceAt: (NSInteger) location length: (NSInteger) length;
- (NSInteger) firstLocationOfCharactersInSet:(NSCharacterSet *) set starting: (NSInteger) location;
- (NSInteger)firstLocationOfCharactersInSet:(NSCharacterSet *)set backwardFrom:(NSInteger)location;
- (NSRange) rangeOfString: (NSString *) string starting: (NSInteger) location;
+ (NSString *) stringWithZeros;
+ (id) regexWithString: (NSString *) string;
- (NSInteger) parseEscapeAt:(NSInteger *)index;
- (NSString *) parseEscapesIn:(NSString *)string;
- (NSInteger) parseCharacterLiteralAt:(NSInteger *) i;
- (unichar) characterAt: (NSInteger) i;

@end


///////////////////////////////////////////////////////////////////////////////////////////

/*! this registry defines the rules for the parser 
    the registry is a dictionary with the parser classes which get selcted by a NuListParser 
    the keys of the dictionary are the triggering strings of each parser class eg "(" for a list parser or "\"" for a string parser*/
@interface NuParserClassRegistry : NSObject

/*! the designated initializer. calls setup */
- (id)init;

/*! sets up the the standard parser clases
    subclasses with different rules should overwrite this method*/
 - (void) setup;

/*! the shared standard parser object */
+ (NuParserClassRegistry *) shared;

/*! the parser class dictionary with triggering strings as keys */
@property (nonatomic) NSMutableDictionary * dictionary;

/*! the parser that gets instantiated if there is no triggering string found in the dictionary
    the default defaultparser is NuSymbolAndNumbeParser */
@property (nonatomic) Class defaultParser;

/*! to register a Parser class in the parser dictionarry with its own trigger provided by [ParserClass trigger] */
- (void) register: (Class) parserClass;

/*! to register the default parser for cases that are ambiguous:
    because always the longest matching parser trigger gets chosen,
    there have to be shorter matches, to reach the matches 
    for the longer triggers. eg. in order to  matche '-"' with the 
    string parser class '-' has to be looked up first */
- (void) registerDefaultParserFor: (NSString *) token;


/*! some useful character sets, will move to NuParserClassRegistry */
+ (NSCharacterSet *) nonWhiteSpaces;
+ (NSCharacterSet *) commentCharacters;
+ (NSCharacterSet *) endOfAtomCharacters;
+ (NSCharacterSet *) stringSpecialCharacters;
+ (NSCharacterSet *) nonWSbutNL;

@end

@interface NuLegacyParserClassRegistry : NuParserClassRegistry @end

///////////////////////////////////////////////////////////////////////////////////////////

/*! An extension of NuCell which sets the corresponding NuObjectParser object as an associatedObject 
    this extension is not necessary, the parser looks for an selctor(setParser:).
    if there isn't any it's ok.
    maybe this should get banned in a subclass */
@interface NuCell (parser)

- (void) setParser: (NuObjectParser *) parser;
- (NuObjectParser *) parser;

@end


///////////////////////////////////////////////////////////////////////////////////////////

/*! extensions for NSString */
@interface NSString (parser)

/*! if longer than i this cuts the string at i and inserts "..."
    used by description messages */
- (NSString *)cutAt: (NSInteger) i;

/*! sets up a lineInfo for ths string */
- (LineInfo *) lineInfo;

/*! creates a symbol with the string from [NuSymbolTable sharedSymbolTable] */
- (NuSymbol *) symbol;

+ (NSString *) stringWithUnichar: (unichar) value;

@end

///////////////////////////////////////////////////////////////////////////////////////////
/* I tried to establish the standard behaviour for objective c within Nu:
   When a message sent to nil, nil is returned.
   since nil is represented by NSNull.null this was supposed to do ist.
   it didn't work out, so i think, this must be done from within Nu.m .
@interface NSNull (parser)

- (id)handleUnknownMessage:(id)cdr withContext:(NSMutableDictionary *)context;

@end
*/

///////////////////////////////////////////////////////////////////////////////////////////

/*! this is the base class of this NuParser implementation 
    It's abstract and needs to be subclassed.
    An instance of NuObjectParser corresponds to a NuCell and the part of the source string which got parsed 
    complementing to NuCells, it has references to the parser of the previous and the parent cell as well as the root parser*/
@interface NuObjectParser : NSObject

/*! Base Cell. The to be parsed Item will be in the car. */
@property (nonatomic) NuCell * cell;

/*! parent parser for backtracking */
@property (nonatomic, weak) NuListParser * parent;

/*! previous parser in the current list. */
@property (nonatomic) NuObjectParser * previous;

/*! root parser */
@property (nonatomic, weak) NuRootParser * root;

// Range of the item in the car of cell
// The range of a list includes all items until the last cells cdr == null
@property (nonatomic) NSInteger location ;
@property (nonatomic) NSInteger length;
- (NSInteger) line;
- (NSInteger) column;
- (NSInteger) endLine;

/*! end sets length according to location and vv */
@property (nonatomic) NSInteger end ;

/*! Range of Item in car for convenience */
- (NSRange) range;

/*! moves the location of the parser by delta 
    subclasses namely NuListParser uptdate there children accordingly 
    no need to be in the header
- (void) moveBy: (NSInteger) delta;
*/

/*! if YES is returned, the cell gets ignored and the next parser tries to 
    connect its cell to the (next possible) previous parser */
@property (nonatomic) BOOL cellIgnored;

- (NuObjectParser *) lastNotIgnoredPrevious;

/*! comments before base cell to the base Cell */
@property (nonatomic) NSString * comments;

/*! returns when happened errors occured, otherwise nil */
@property (nonatomic)  NuError *error;

/*! marks an error for this parser */
- (void) markError: (NSString *) name reason: (NSString *) reason;

- (void) clearEvaluationErrors;

/*! called by when an esception meets a cell with an associated parser the first time */
- (void) logEvaluationError:(NuException *)exception;

/*! if yes the result of a recent evaluation gets logged 
    and possibly processed */
@property (nonatomic) BOOL logEvaluationResultEnabled;

/*! the most recent result. gets initialized wit self.root.invalidResultSymbol */
@property (nonatomic) id result;

/*! this method gets called by NuDebuggingCell when logEvaluationResultEnabled == YES */
- (void)logEvaluationResult: (id) result;

/*! returns YES if the result is different from self.root.invalidResultSymbol */
- (BOOL) resultIsValid;

/*! invalidates the result */
- (void) invalidateResult;

/*! if YES the display parser that displays a given result will be 
    inserted before the end of self.
    only possible for lists. */
- (BOOL) displayParserWithinRange;

/*! calculates the position and deletion range for a display parser update */
- (NSRange) possibleDisplayParserRange;

/*! if there is a display parser at belonging to self return the instance */
- (NuResultDisplayParser *) displayParser;

/*! returns the text change, that can be used to update the reuslt */
- (TextChange *) proposedResultUpdate;

/*! a text change for removing self from the source code */
- (TextChange *)removalTextChange;


/* not used
- (void)markError:(NSString *)name reason:(NSString *)reason range: (NSRange) range; */

/*! the start position for parsing, usually self.location + trigger.length */
@property (nonatomic, readonly) NSInteger withOffset;

/*! designated initializer */
- (id)init;

/*! convenince initializer */
- (id)   initWithRoot: (NuRootParser *) root
               parent: (NuListParser *) parent
             previous: (NuObjectParser *) previous
             location: (NSInteger) location
             comments: (NSString *) comments;

/*! subclasses will parse starting at self.withOffset in self.root.job.string
    into self.cell.car
    expects self.index, self.location, self.root, and self.cell to be set 
    some subclasses may also need parent and previous */
- (void) parse;

/*! subclasses update cell cell.car according to changes indicated by
    location, deletionRange and insertionRange 
    returns the affected range of changes in the parsetree.
    if the changes are completely within self, without changing the outside structure
    it returns  location, insertionLength
    otherwise it is self.range  */
- (NSRange) updateAt: (NSInteger) location deleted: (NSInteger) deletionLength inserted: (NSInteger) insertionLength;

/*! tests wether the parser still works after an update of the source string */
- (BOOL) stillValid;

- (BOOL) stillValidWithChangesAt: (NSInteger) location
                         deleted: (NSInteger) deletionLength
                        inserted: (NSInteger) insertionLength;

/*! the position in the current list, that means the list starting with parent.car
    used to calculate path */
- (int) positionInList;

- (int) depth;

/* get's the first Parser in the current List (not the child one) */
- (NuObjectParser *) first;

/*! returns a list to find the way throug the parse tree to this cell
    starting with the list in root.car, you get the position of the cell
    in every child list up to here*/
- (id) path;

/*! returns true if the parsed Item is not a list */
- (BOOL) atom;

/*! returns an array with parsers relevant at the given position
 self is at the top and the top parser is at index 0, if any, the only atom parser */
- (NSMutableArray *) parserStackAt: (NSInteger) pos;

/*! returns the parser at the given location, which hasn't any children anymore 
    parsers with length = 0 don't get found, which is good so.
    => hidden parsers have length zero, eg. NuSpecilaObjectParser. */
- (NuObjectParser *) parserAt: (NSInteger) location;

/*! the parser int the hierarchy containing the given range */
- (NuObjectParser *) parserContaining: (NSRange) range;

/*! collects all Parsers in the subtree */
- (NSMutableArray *)descendants;

/*! is overridden by ListParserSubclasses or others if it makes sense */
- (void) alignChildren;

/*! tests wether self is the first Parser in self.line */
- (BOOL) isFirstParserInLine;

/*! if there is an indent set for this line, the column gets calculated according this indent 
    else, self.column is returned */
- (NSInteger) desiredColumn;

/*! tries to figure out the range of this parser including whitespaces and comments
    all in all, what it takes to delete it.
    maybe there is no whitespace left, so a delete procedure has to figure out
    whether the start of the next atom is an endOfAtomCharacter */
- (NSRange)rangeIncludingSpaces;

/*! aligns self with parser. subclasses like NuSymbolAndNumberParser may override this
    in order eg. to align the colon of labels */
- (void) alignWith: (NuObjectParser *) parser;

/*! tries to emulate opens and parens instance variables in old NuParser
    openSexpr returns a stack with column informations for every open list
    parens returns the number of open parens 
    these functions could be used for indentation etc.
    so in contrary to depth, parensAt doesn't reflect quotes, dots, arrows etc. 
    not used and tested yet 
- (void) stackOpenSexprColumnsAt: (NSInteger)pos with: (NuStack *) stack;
- (NSInteger) parensAt: (NSInteger) pos;
 */
- (NSArray *) tree;

- (NSString *) source;





- (NSString *)description;

/*! returns a string with the type of the parsed object 
    is used eg for syntax highlighting */
- (NSString *) type;

/* not needed, used and tested
- (NSString *) parserInfo;
- (NSString *) parseTreeInfo;
*/

/*! some useful character sets */
+ (NSCharacterSet *) nonWhiteSpaces;
+ (NSCharacterSet *) commentCharacters;
+ (NSCharacterSet *) endOfAtomCharacters;
+ (NSCharacterSet *) stringSpecialCharacters;
+ (NSCharacterSet *) nonWSbutNL;

/*! returns nil, overridden by subclasses to let NuListparser jump over one ore more items 
    a kind of hack which lets implement multi line comments,
    or special items like brekpoints etc. */
- (NuObjectParser *) nextPreviousParser;

/*! to be overridden by the Nu source */
- (NuCell *) proposeNewlineChanges;

/*! to be overridden by subclass to return the triggering string
    like the quote character or " for strings etc. */
+ (NSString *) trigger;


@end

///////////////////////////////////////////////////////////////////////////////////////////

/*! The most important subclass of NuObjectParser to implement the list structure
    Can be subclassed in various ways as demonstrated below.
    This class adds a reference to the last item in the child list called lastChild
    Additionally this object does all the parsing for the children, chooses a fitting parser from the registry, parses comments
    and does all the indentation and aligning stuff
    Also the magic update method is implemented here */
@interface NuListParser : NuObjectParser

/*! the count of cells in list or Parsers without the endOfListParser */
- (int) count;

/*! if not nil, the returned object is set in the car of the list */
- (id) specialCarObject;

/*! Parser registry
    could be individual for every instance or class
    defaults to [root registry]
    could be overridden to establisch a complete different 
    syntax within this part of the parse tree*/
- (NuParserClassRegistry *) registry;

/*! defaultParser
    usuallay = [NuSymbolAndNumberParser class] */
- (Class)  defaultParserClass;

/*! a parserClass to mark the end of a list */
- (Class) endOfListParserClass;

/*! last parser in the list
    importantfor tracking carLength dynamically
    and enumerating through the list parsers 
    if a ')' ends a list its the an NuEndOfListParser
    at the end of a file it's NuEndOfFileParser
    sublasses like NuDotParser or NuFixedLengthParser
    put the last elements parser here,
    so the base isn't necessarily nil */
@property (nonatomic) NuObjectParser *lastChild; // weak reference does not work

/*! parses whitespaces before the next Item starting self.index
    updates self.index to the next parseable item.
 returns the last comments  */
- (NSString *)processWhiteSpacesAndCommentsWith: (NSInteger *) indexp;

/*! the class method trigger in all NuObjectpParsers provides a trigger string
    this methods chooses the matching class accordingly 
    but first looks after the endOfFileParser for this list */
- (Class) matchParserClassWithTrigger: (NSString *) trigger;

/*! returns tha matching parser class for the provided location in the string
    the longest matching triggerstring wins */
- (Class) matchingParserClassAt: (NSInteger) location;

/*! parses */
- (NuObjectParser *) parseInItemAfterPrevious: (NuObjectParser *) previous;

- (NuObjectParser *) parseIn: (NSInteger) count itemsAfter:  (NSInteger) location previous: (NuObjectParser *) previous;

/*! finds the correct child parser to align with, if the parent list extends over several lines
    the result gets memoized, therefor: properties */
@property (nonatomic)  NuObjectParser  *parserToAlign;
@property (nonatomic, weak)  NuObjectParser *labelInFirstLine; // weak?

- (NuObjectParser *) childNr: (NSInteger) nr;

/*! finds the correct parser to align with, if the parent list extends over several lindes */
- (NuObjectParser *) parserToAlign;

/*! if the second item in a list is in a new line it gets either indented or aligned to the car 
    in the list if this method returns 0; */
- (NSInteger) secondParserIndent;

@property (nonatomic) BOOL unfinishedHereString;

@property (nonatomic) BOOL displayParserWithinRange;

@end
///////////////////////////////////////////////////////////////////////////////////

/*! The NuEndoOfListParser parses the end of a list, so usually the '(' */
@interface NuEndOfListParser : NuObjectParser

@end


///////////////////////////////////////////////////////////////////////////////////

/*! parses end of list but behaves like it hasn't seen the last parent and 
    hands it over to the parent list
    that means self.index doesn't get changed and carLength = 0
    it's needed to deal gently with special cases like ' before ),
    or a dot at the end of a list */
@interface NuSilentEndOfListParser : NuEndOfListParser

@end

///////////////////////////////////////////////////////////////////////////////////

/*! a parser which only purpos is to let other parser align with it, in case,
    there is no matchin parser to align with. this parser doesn't get concatenated with
    others, doesn't have any cell and has just a location, length = 0,
    and a connection with parent and root */
@interface NuAlignParser : NuObjectParser

@property (nonatomic) NSInteger desiredColumn;

- (id)initWithRoot:(NuRootParser *)root
            parent:(NuListParser *)parent
          location:(NSInteger) location
          column:(NSInteger)column;

@end

///////////////////////////////////////////////////////////////////////////////////

/*! a parser which parses a list of predefined length
    subclassed eg to parse quotes. */
@interface NuFixedLengthListParser : NuListParser

// defaults to 2
- (int) listLength;

@end

///////////////////////////////////////////////////////////////////////////////////
/*! abstract class for connecting items to a list using a kind of infix operator
    used for implementation of the dot-syntax.
    can also parse more than one item after the operator (NuColonParser)
    or be used as a postfix operator with listLength = 1 (see NuPostfixResultParser) 
    listLength must be defined (when other than 2)
    also the trigger isn't specified yet. */
@interface NuInfixParser : NuFixedLengthListParser

@end

///////////////////////////////////////////////////////////////////////////////////

/*! a proposed extension to the Nu syntax.
    Analog to its function in objective c
    the dot concatenates 2 single items to a list like 
    aa.bb => (aa bb)
    aa.bb.cc => ((aa bb) cc) 
    I think the dot makes things more readable and is imho
    really necessary to keep up with objective c.*/
@interface NuDotParser : NuInfixParser @end

///////////////////////////////////////////////////////////////////////////////////

/*! a possible extension to the Nu syntax.
    Analog to its function in objective c
    the dot concatenates 3 single items to a list like
    aa : bb cc => (aa bb cc)
    aa : bb cc . dd => ((aa bb cc) dd)
    so infix operators like 1 :+: 2 => (1 +: 2) are possible
    this looked first good for me, but since parens can't be used to order precednce 
    it's not a brilliant idea and somewhat looks awkward in nice formatted lisp code 
    But in command line this could be practical */
@interface NuColonParser : NuInfixParser @end

///////////////////////////////////////////////////////////////////////////////////

@interface NuPostfixListParser : NuListParser @end
@interface NuEndOfPostfixListParser : NuEndOfListParser @end

///////////////////////////////////////////////////////////////////////////////////

@interface NuHiddenPrefixParser : NuFixedLengthListParser;
/*! hides the cell.car. through
    self.cell.car = self.lastChild.cell.car; 
    can be overridden to turn on flags like breakpoint or logEvaluationResult */
- (void) hide;
@end

@interface NuHiddenPostfixParser : NuInfixParser;
/*! hides the cell.car. through
 self.cell.car = self.lastChild.cell.car;
 can be overridden to turn on flags like breakpoint or logEvaluationResult */
- (void) hide;
@end


///////////////////////////////////////////////////////////////////////////////////


/*! again a maybe useful extension to the Nu syntax:
    the backward arrow puts everyting from the list start in a new build list in the car, like so:
    (aa bb cc <- dd ee <- ff gg) => (((aa bb cc) dd ee) ff gg) 
    This could be usefulwhen composing message chains like:
 
    (array 1 2 3 7 9 12
        <-    map: (do (number)
                       (+ number 2))
        <- select: (do (number)
                       (> number 6))
        <-   each: puts)
 
    This is I think a good thing makes the code mouch clearer and more readable,
    since the usual lisp formatting stresses the operator in the car but the postfix operators and messages 
    somehow don't look good when nested:
 
    ((((array 1 2 3 7 9 12) map: 
                            (do (number) 
                                (+ number 2))) select:
                                               (do (number)
                                                   (> number 6))) each: puts) */
@interface NuArrowParser : NuPostfixListParser @end
@interface  NuEndOfArrowListParser : NuEndOfPostfixListParser @end

///////////////////////////////////////////////////////////////////////////////////

/*! This is the entry point for all parsing with NuObjectParsers
    The root parser is a list parser with the progn symbol in the car and
    ended by the end of file 
    it stores ireferences to the corresponding job (and so to the source code)
    to a cell provider, the parser class registry and to the symbol table
    Every NuObjectParser in the parse tree has a reference to the root parser */
@interface NuRootParser : NuListParser

// the parseJob object, which provides the source code, and some meta information
@property (nonatomic, weak) NuParseJob * job;

// the cellProvider delegate responds to @selector(cellWithParser:)
// so it is possible to connect cells with the parser and a debugger ...
// or to provide a "barebone" cell for faster performance ...
@property (nonatomic) id <NuCellProvider> cellProvider;

@property (nonatomic) NuSymbolTable *symbolTable;


/* the parser registry for the parse tree defaults to [NuParserRegistry shared] */
@property (nonatomic) NuParserClassRegistry * registry;

@property (nonatomic) NuSymbol *invalidResultSymbol;

- (id) initWithJob:(NuParseJob *)job
      cellProvider:(id<NuCellProvider>)cellProvider
          registry:(NuParserClassRegistry *) registry
       symbolTable:(NuSymbolTable *)symbolTable;

/*! the dictionary gets a indent value for a symbol
 if the symbol is in the car of a list, indent is set fix to this value */
- (NSNumber *)specialIndentWithCar: (id) symbol;

@end


////////////////////////////////////////////////////////////////////////////////

/*! the end of file parser is triggered by "\0".
    since it is an end of list parser and every stringindex of the source > string.length
    returns "\0", not closed lists are ended autmatically (but not without filing an error) */ 
 @interface NuEndOfFileParser : NuEndOfListParser @end

////////////////////////////////////////////////////////////////////////////////

/*! Used to parse in special symbols like 'progn or 'quote */
@interface NuSpecialObjectParser : NuObjectParser

@property (nonatomic) id object;

- (NuObjectParser *)initWithObject: (id) object
                                root:(NuRootParser *)root
                              parent:(NuListParser *)parent
                            previous:(NuObjectParser *)previous
                            location:(NSInteger)location
                            comments:(NSString *)comments;

@end

////////////////////////////////////////////////////////////////////////////////

/*! Toying around with the syntax,
    implementing an array literal with brackets was easy:
    [1 2 3] => (array 1 2 3) 
    I don't know wether this is useful.
    I seldom use array literals.
    one possible variation could be 
    MD[abc: 123 def: 456] for a mutable dictionary or 
    S['s 'd 'r] for a set, and so on.
    I have my doubts about this, (dict abc: 123 def: 456) looks just nicer. */
@interface NuArrayParser : NuListParser @end
@interface NuEndOfArrayParser : NuEndOfListParser @end

////////////////////////////////////////////////////////////////////////////////

/*! also an experiment:
    A try to establish a ruby like block syntax:
    {a b | (+ a b)} => (do (a b) (+ a b))
    {(puts "hello world")} => (do () (puts "hello world"))
    Possible, but not necessary. */
@interface NuBlockParser : NuListParser
@property (nonatomic) BOOL argumentsParsed;
@end
@interface NuBlockArgumentParser : NuListParser @end
@interface NuEndOfBlockArgumentParser : NuEndOfListParser @end
@interface NuEndOfBlockParser : NuEndOfListParser @end


////////////////////////////////////////////////////////////////////////////////

/*! Most frequently used parser.
    Parses symbols and numbers.
    The parser has a special attentian for dots 
    and first tries to parse a fp-number, if not successful, the dot is interpreted as an
    end-of-atom-character, which makes the new dot-syntax possible.
    So following examples get translated as expected:
    3.14.objCType  => (3.14 objCType)
    3.objCType*    => (3 objCType)
    3.14           => 3.14
    3.0e3.objCType => (3.0e3 objCType) 
    labels get recognized as such,
    concatenating multiple labels to one symbol doesn't work yet */
@interface NuSymbolAndNumberParser : NuObjectParser @end

/*! Allows parsing of long symbols including whitespaces and special charcters.
    The symbol is delimeted by < and > but does not include these (for now).
    The main purpose for this is to use this as a reference to objects
    for example: <Nu_add_operator: 0x100595890> 
    So it could be possible, if  <Nu_add_operator: 0x100595890> 
    is returned by the command line, one could refer to this object directly.
    Other usage possibilities:
    -   string symbols (like transient symbols in Pico List)
        which could evaluate to its own string value, if notihing else is defined.
        could be used for localizations
    -   xml/html- tags, but this would be better with the delimters included in the symbol name.
        But I think we are good with Tim's new & - syntax anyway. 
    Characterescaping is allowed.
    For now, the symbol value is not defined and not global, 
    but maybe the other way is better ... */
@interface NuLongSymbolParser : NuSymbolAndNumberParser @end

////////////////////////////////////////////////////////////////////////////////

/*! This is the string parser as implemented by Tim.
    Because I have implemented an alternative version, this one is now triggered by '$"', '+$"' and '-$"' */
@interface  NuStringParser : NuObjectParser @end
@interface NuEscapedStringParser : NuStringParser @end
@interface  NuNonescapedStringParser : NuStringParser @end

////////////////////////////////////////////////////////////////////////////////

/*! the ordinary herestring parser without indentation
    is triggered now by $<<- and $<<+ 
    in the editor you should turn off auto indent, while editing the herestring */
@interface NuHeredocParser : NuStringParser
- (BOOL) escaped;
@end

@interface NuEscapedHeredocParser : NuHeredocParser @end


////////////////////////////////////////////////////////////////////////////////

/*! The same as above just with the legacy triggers */
@interface  NuLegacyStringParser : NuStringParser @end
@interface NuLegacyEscapedStringParser : NuEscapedStringParser @end
@interface  NuLegacyNonescapedStringParser : NuNonescapedStringParser @end
@interface NuLegacyHeredocParser : NuHeredocParser @end
@interface NuLegacyEscapedHeredocParser : NuEscapedHeredocParser @end

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

/*! This string parser parses the string interpolation (so called in ruby for the #{} constructs)
    which enables syntax highlighting, debuggeing and so on.
    the string gets replaced by a list with + operator in the car.
    So far this worked very well,
    but there may be cases, where parsing at evaluation time could be useful.
    So there could be a different trigger used like eg '$"' or so 
    important: the parser is still a subclass of NuListParser, 
    even if there is just a string in the car
    which might be the case when no #{} is used. */
@interface  NuInterpolationStringParser : NuListParser
- (BOOL) escaped;
@end

@interface  NuStringPartialParser : NuStringParser
@property (nonatomic) BOOL terminatedByInterpolation;
@property (nonatomic) BOOL escaped;
@property (nonatomic) NSInteger withOffset;
@end

@interface NuInterpolationParser : NuListParser @end

@interface NuEscapedIpStringParser : NuInterpolationStringParser @end
@interface NuNonescapedIpStringParser : NuInterpolationStringParser @end

////////////////////////////////////////////////////////////////////////////////

/*! This heredoc parser parses the interpolation like above explained 
    Additionally this parser is "indentable"!
    every line gets cut of before the column of the start keyword
    example:
 
 (puts <<-XXX
          eierlegende
          Wollmilchsau
          XXX)
 
 => (puts "eierlegende\nWollmilchsau\n")
 
    this works pretty fine with auto indentation and looks good since the strings doesn't
    obfuscate the source code anymore.
    There is still a problem: with indentation turned on,
    every whitespace at the beginning of a line gets cut off.
    solution: insert an '_' at the beginning of a line
    which gets a special indent and cut off:
 (puts <<-XXX
          eierlegende
         _    Wollmilchsau
          XXX)
 => (puts "eierlegende\n    Wollmilchsau\n")
 
    Again this is awkward if you jus copy and paste in text,
    but the editor may help you out some time. */
@interface NuInterpolatingHeredocParser : NuListParser
- (BOOL) escaped;
@end

@interface  NuHeredocPartialParser : NuStringParser

@property (nonatomic) BOOL escaped;
@property (nonatomic) BOOL terminatedByInterpolation;
@property (nonatomic) NSInteger endOfString;
@property (nonatomic) NSInteger indent;
@property (nonatomic) BOOL startWithNewLine;
@property (nonatomic) NSInteger withOffset;

@end

@interface NuEscapedIpHeredocParser : NuInterpolatingHeredocParser @end

////////////////////////////////////////////////////////////////////////////////

/*! The regex parser */
@interface NuRegexParser : NuStringParser @end

////////////////////////////////////////////////////////////////////////////////

/*! The quote and character parser.
    One problem (also the same with the old nu parser):
    '('(a b)) is ambiguous:
    should be translated as (quote ((quote (a b))))
    the parse parses a paren character literal instead: 40 (a b)
    workaround: insert a ws: '( '(a b)) */
@interface NuQuoteAndCharacterParser : NuFixedLengthListParser

@property (nonatomic) BOOL isCharacter;

@end

////////////////////////////////////////////////////////////////////////////////

@interface NuQuasiquoteParser : NuFixedLengthListParser @end
@interface NuQuasiquoteEvalParser : NuFixedLengthListParser @end
@interface NuQuasiquoteSpliceParser : NuFixedLengthListParser @end

////////////////////////////////////////////////////////////////////////////////

/*! This could be a very useful extension to Nu:
    put a tilde (~) in front of an item or a list,
    then this will be ignored.
    this is very useful for "commenting out" code
    which is often quite tedious with the line comment characters only.
    also multiline comments or something like "compiler directives"
    could be a use case */
@interface NuIgnoreNextItemParser : NuFixedLengthListParser


@end


////////////////////////////////////////////////////////////////////////////////

/*! This Parser parses the following item as child, evaluates it immediately
    and puts the result in his own car. */
@interface NuInlineEvaluationParser : NuFixedLengthListParser
- (void) evaluate;
@end

////////////////////////////////////////////////////////////////////////////////

/*! If live evaluation is turned on, thes parser gets evaluated after every change, made
    in the source code.
    In contrast to NuInlineEvaluationParser evaluation takes place after the parsing.
    The result is not used,
    but can be asked by a result logging parser 
    This can be used for tests and for setting up an live programming environment. */
@interface NuLiveEvaluationParser : NuHiddenPrefixParser
- (void) evaluate;
@end

////////////////////////////////////////////////////////////////////////////////

/*! a parser which is basically ignored and which is
    used to display the results of the evaluation of the previous parser */
@interface NuResultDisplayParser : NuIgnoreNextItemParser @end

////////////////////////////////////////////////////////////////////////////////

/*! This Parser parses the following item as child,
    connects it's own cell to the childs car.
    this cell in a way, that by evaluation, it catches the result of this evaluation
    and stores it in theis parser object.
    the result change gets logged in the parse job object,
    so an editor can ask for it and insert/update so called result parsers,
    which is basically an ignored item following this parser 
    to display the result inline in the editor.
    this parser holds an reference to  the corresponding result parser parser, if 
    there is any.
    but there are also other possibilities to display this evaluation information */
@interface NuPrefixResultLoggingParser : NuHiddenPrefixParser @end

@interface NuPostfixResultLoggingParser : NuHiddenPostfixParser  @end

@interface NuTriggerForResultLoggingListParser  : NuObjectParser
/*! should return NO, if this parser isn't at the end of alist */
- (BOOL) isAtRightPlace;
@end


////////////////////////////////////////////////////////////////////////////////

/*! used by subclasses to give unused parens, brackets etc. a meaning */
@interface NuErrorParser : NuObjectParser @end

////////////////////////////////////////////////////////////////////////////////

/*! parses unused parens usually at the end of file */
@interface NuExtraneousParensParser : NuErrorParser @end
////////////////////////////////////////////////////////////////////////////////

/*! parses unused brackets usually at the end of file */
@interface NuExtraneousBracketsParser : NuErrorParser @end




