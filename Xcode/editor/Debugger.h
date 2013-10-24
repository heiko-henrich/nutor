//
//  Debugging.h
//  Nu
//
//  Created by Heiko Henrich on 17.08.13.
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*! 
    This is not really a Debugger (yet)
    This file is mainly for  hacking  into the evaluation process of Nu Objects.
    It is done by replacing the evalWithContext: Method of the most important
    Nu Classes with a new one, which wraps around a call to the old one.
    now its just to pick intermediate results,
    later this will be used to handle breakpoints
    and step debugging, which is just a chapter of his own.
    I tried this with proxies first,
    this would have been more elegant and would have had other advantages,
    but unfortunately, nu_objectIsKindOfClass function in contrary to the isKindOfClass: method,
    works too strict.
    so some standard Nu methods like stringValue, didn't work correctly anymore.
    Since my goal was, not to touch Nu.m
    I decided for this "dirty" solution.
    Subclassing was also an option, but had similar problems like the proxy approach.

    In order to get the right parser which holds the evaluated object in question
    this "Debugger" uses a hack:
    Since almost every call to evaluateWithContext: is preceded by call to car of the cell (and parser) 
    in question, every call to car remembers it's last caller with a global variable.
    Attention: this is not thread safe (yet).
 
    furthermore there is  a kind of standard method introduced
    called asNuExpression, which results in a string,
    which, evaluated as a Nu expression, will result 
    in an object equalTo: self 
    more of these are introduced in expressions.nu */

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "Nu.h"
#import "Parser.h"



/*! a hack to change the superclass at runtime.
    Tim did something like this in NuClass.
    Probably not usable from within objc ? 
    anyway, this should do the trick */
@interface NSObject (Debugging)
/*! used to change the class of an object after instantiaton
    actually not used anymore, but useful */
- (void)setClass:(Class)aClass;

/*! returns a unique symbol to identify this object
    (((NSTextView alloc) init) symbolValue)
    e.g. results in a symbol like <NSTextView:610000720140>.
    Now things like:
    (<NSTextView:610000720140> description)
    => "<NSTextView: 0x610000720140>\n    Frame = {{0.00, 0.00}, {0.00, 0.00}}, Bounds = {{0.00, 0.00}, {0.00, 0.00}}\n    Horizontally resizable: NO, Vertically resizable: YES\n    MinSize = {0.00, 0.00}, MaxSize = {0.00, 10000000.00}\n"
    are possible.
    these symbols are only usable with the new introduced long symbol syntax,
    which encloses a symbolname in < >.  */
- (NuSymbol *)symbolValue;

/*! this fallback superclass method returns a string with a
    (new introduced long) symbol bound to the value of the object.
    (see symbolValue method)
    subclasses override this in more Nu-like expressions like
    ('(a b) asNuExpression) => "(list 'a 'b)"
    which could be evaluates to a value equalTo: '(a b) */
- (NSString *) asNuExpression;
@end

@interface NSString (Debugging)
- (NSString *) asNuExpression;
@end

@interface NuDebugging : NSObject

/*! if yes all nu objects are in debugging mode */
+ (BOOL)state;

/*! sets debugging mode */
+ (void) setState: (BOOL) on;

@end

@interface NuDebuggingException : NuException

/*! a kind of call stack,
    that means all parent cells that got evaluated before 
    the exception happened */
@property NSMutableArray * evaluationStack;

@end

@interface NuSymbol(Debugging)
- (NSString *) asNuExpression;
@end

@interface NSNumber (Debugging)
- (NSString *) asNuExpression;
@end



@interface NuCell (Debugging)

/*! should be called before a new evaluation with result tracking is started. 
    this is due to a hack:
    because it is not easily possible to determine, which object is evaluated by which operator,
    cell or so, I  have "overridden" car Method to statically remember the last parent, means caller.
    because usually the car of a cell is evaluated, in 90% of all cases, this works fine.
    If ou don't want to mess up with previous evaluations,
    you have to reset this static vairiable by this method */
+ (void)resetLastParent;

- (NSString *) asNuExpression;

@end

@interface NuMath (PI)

+ (double) pi;

@end