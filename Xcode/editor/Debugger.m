//
//  Debugging.m
//  Nu
//
//  Created by Heiko Henrich on 17.08.13.
//
//

#import "Debugger.h"
#import <objc/runtime.h>


#define IS_NOT_NULL(xyz) ((xyz) && (((id) (xyz)) != [NSNull null]))


@interface NuDebuggingMixin : NSObject
- (id)debuggingEvalWithContext:(NSMutableDictionary *)context;
@end



/*!
 @class NuBreakException
 @abstract Internal class used to implement the Nu break operator.
 */
@interface NuBreakException : NSException
@end

/*!
 @class NuContinueException
 @abstract Internal class used to implement the Nu continue operator.
 */
@interface NuContinueException : NSException
@end

/*!
 @class NuReturnException
 @abstract Internal class used to implement the Nu return operator.
 */
@interface NuReturnException : NSException
{
    id value;
	id blockForReturn;
}

- (id) value;
- (id) blockForReturn;
@end


// maybe subclassing or even changing nu.m would have been the better choice.
@implementation NuDebuggingException

- (id)init
{
    self = [super init];
    if (self)
    {
        _evaluationStack = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) registerAndNotify: (NuCell *) cell context: (NSMutableDictionary *) context
{
    [[self evaluationStack] addObject:@{   @"cell": cell,
                                        @"context": context}];
    
    NuObjectParser *parser;
    if ( [cell respondsToSelector:@selector(parser)]
       && (parser = [cell parser]) )
    {
        [parser.parent logEvaluationError:self];
    }
}

@end

@implementation NuCell (Debugging)

+ (void) toggleDebugging
{
    [NuCell exchangeInstanceMethod:@selector(debuggingEvalWithContext:) withMethod:@selector(evalWithContext:)];
    [NuCell exchangeInstanceMethod:@selector(debuggingCar) withMethod:@selector(car)];
}

static NuCell *_lastParent;

+ (NuCell *) lastParent
{
    NuCell * lp = _lastParent;
    _lastParent = nil;
    return lp;
}

+ (void)resetLastParent
{
    _lastParent = nil;
}


- (id)debuggingCar
{
    _lastParent = self;
    return self.debuggingCar;
}

static BOOL nu_objectIsKindOfClass(id object, Class class)
{
    if (object == NULL) {
        return NO;
    }
    Class classCursor = object_getClass(object);
    while (classCursor) {
        if (classCursor == class) {
            return YES;
        }
        classCursor = class_getSuperclass(classCursor);
    }
    return NO;
}


- (id) debuggingEvalWithContext:(NSMutableDictionary *)context
{
    id value = nil;
    id result = nil;
    
    NuCell *lastParent = [NuCell lastParent];
    @try
    {
        value = [self.car evalWithContext:context];
        
        // to improve error reporting, add the currently-evaluating expression to the context
        [context setObject:self forKey:[[NuSymbolTable sharedSymbolTable] symbolWithString:@"_expression"]];
        
        result = [value evalWithArguments:self.cdr context:context];
        
    }
    @catch (NuDebuggingException* nuException) {
        //[self addToException:nuException value:[self.car stringValue]];
        [nuException registerAndNotify: self context: context];
        @throw nuException;
    }
    @catch (NSException* e) {
        if (   nu_objectIsKindOfClass(e, [NuBreakException class])
            || nu_objectIsKindOfClass(e, [NuContinueException class])
            || nu_objectIsKindOfClass(e, [NuReturnException class])) {
            @throw e;
        }
        else {
            
            NuDebuggingException* nuException = [[NuDebuggingException alloc] initWithName:[e name]
                                                                                    reason:[e reason]
                                                                                  userInfo:[e userInfo]];
            //[self addToException:nuException value:[car stringValue]];
            [nuException registerAndNotify:self context:context];
            @throw nuException;
        }
    }
    
    if ([lastParent respondsToSelector:@selector(parser)])
    {
        id parser = [lastParent parser];
        if ([parser logEvaluationResultEnabled])
        {
            [parser logEvaluationResult:result ];
        }
    }
    return result;
    
}



- (NSString *) asNuExpression
{
    NuCell *cursor = self;
    NSMutableString *result = [NSMutableString stringWithString:@"(list "];
    int count = 0;
    while (IS_NOT_NULL(cursor)) {
        if (count > 0)
            [result appendString:@" "];
        count++;
        id item = [cursor car];
        if (IS_NOT_NULL(item)) {
            [result appendString:[item asNuExpression]];
        }
        else {
            [result appendString:@"()"];
        }
        cursor = [cursor cdr];
        // check for dotted pairs
        /*       if (IS_NOT_NULL(cursor) && ![item isKindOfClass:[NuCell class]]) {
         [result appendString:@" . "];
         if ([cursor respondsToSelector:@selector(escapedStringRepresentation)]) {
         [result appendString:[((id) cursor) escapedStringRepresentation]];
         }
         else {
         [result appendString:[cursor description]];
         }
         break;
         }*/
    }
    [result appendString:@")"];
    return result;
}

@end



@implementation NuDebuggingMixin


- (id)debuggingEvalWithContext:(NSMutableDictionary *)context
{
    NuCell *lastParent = [NuCell lastParent];
    id result  = [self debuggingEvalWithContext:context];
    if ([lastParent respondsToSelector:@selector(parser)])
    {
        id parser = [lastParent parser];
        if ([parser logEvaluationResultEnabled])
        {
            [parser logEvaluationResult:result ];
        }
    }
    return result;
}
@end



@implementation NSObject (Debugging)

+ (void)toggleDebugging
{
    [self.class exchangeInstanceMethod:@selector(debuggingEvalWithContext:) withMethod:@selector(evalWithContext:)];
}

- (void)setClass:(Class)aClass {
    NSAssert(
             class_getInstanceSize([self class]) ==
             class_getInstanceSize(aClass),
             @"Classes must be the same size to swizzle.");
    object_setClass(self, aClass);
}

- (NuSymbol *)symbolValue
{
    NSString *objectName = [NSString stringWithFormat:@"<%s:%lx>", class_getName(object_getClass(self)), (long) self];
    NuSymbol *symbol = [[NuSymbolTable sharedSymbolTable] symbolWithString:objectName];
    [symbol setValue:self];
    return symbol;
}

- (NSString *) asNuExpression
{
    return [[self symbolValue] stringValue];
}

@end

@implementation NSString(Debugging)

+ (void)toggleDebugging
{
    [self.class exchangeInstanceMethod:@selector(debuggingEvalWithContext:) withMethod:@selector(evalWithContext:)];
}

- (BOOL) translatesToLabel
{
    return [self rangeOfCharacterFromSet:[NuObjectParser endOfAtomCharacters]].location == NSNotFound;
   
}

- (NSString *)asNuExpression
{
    return [self escapedStringRepresentation];
}
@end



@implementation NSArray(Debugging)

- (NSString *)asNuExpression
{
    NSMutableString *result = [NSMutableString stringWithString:@"(array "];
    for (id element in self)
    {
        [result appendFormat:@"%@ ", [element asNuExpression]];
    }
    [result appendString:@")"];
    return result;
}

@end

@implementation NSDictionary(Debugging)

- (NSString *)asNuExpression
{
    
    NSMutableString *result = [NSMutableString stringWithString:@"(dict "];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && [key translatesToLabel])
        {
            [result appendFormat:@"%@: ", key];
        }
        else
        {
            [result appendFormat:@"%@ ", [key asNuExpression]];
        }
        [result appendFormat:@"%@ ", [obj asNuExpression] ];
    }];
    [result appendString:@")"  ];
    return result;
}

@end

@implementation NSNumber (Debugging)

- (NSString *)asNuExpression
{
    return [self description];
}

- (NSDecimalNumber *) decimalNumber
{
    return [NSDecimalNumber decimalNumberWithDecimal:[self decimalValue]];
}

@end


@implementation NuSymbol(Debugging)

+ (void)toggleDebugging
{
    [self.class exchangeInstanceMethod:@selector(debuggingEvalWithContext:) withMethod:@selector(evalWithContext:)];
}

- (NSString *)asNuExpression
{
    if (self.isLabel)
    {
        return self.stringValue;
    }
    else
    {
        if ([self.stringValue isEqualToString:@"/"])
            return [NSString stringWithFormat:@"'%@ ", self.stringValue];
        else
            return [NSString stringWithFormat:@"'%@", self.stringValue];
    }
}

@end


@implementation NuDebugging

static BOOL _debugging = NO;

static NSArray * _classesToChange;

+ (void)initialize
{
    _classesToChange =  @[[NuCell class],  [NuSymbol class], [NSObject class], [NSString class]];
    NSMutableArray * mixinClasses =[_classesToChange mutableCopy];
    [mixinClasses removeObjectAtIndex:0];
    for (Class class in mixinClasses)
    {
        [class include:[NuClass classWithClass:[NuDebuggingMixin class]]];
    }
    
}

+ (BOOL)state

{
    return _debugging;
}

+ (void) setState: (BOOL) on
{
    if(_debugging != on)
    {
        for (Class class in _classesToChange)
        {
            [class toggleDebugging];
        }
        _debugging = on;
    }
}


@end

@implementation NuMath (PI)

+ (double) pi
{
    return M_PI;
}

@end
