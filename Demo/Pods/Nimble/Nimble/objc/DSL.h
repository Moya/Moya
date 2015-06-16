#import <Foundation/Foundation.h>

@class NMBExpectation;
@class NMBObjCBeCloseToMatcher;
@class NMBObjCRaiseExceptionMatcher;
@protocol NMBMatcher;


#define NIMBLE_EXPORT FOUNDATION_EXPORT

#ifdef NIMBLE_DISABLE_SHORT_SYNTAX
#define NIMBLE_SHORT(PROTO, ORIGINAL)
#else
#define NIMBLE_SHORT(PROTO, ORIGINAL) FOUNDATION_STATIC_INLINE PROTO { return (ORIGINAL); }
#endif

NIMBLE_EXPORT NMBExpectation *NMB_expect(id(^actualBlock)(), const char *file, unsigned int line);

NIMBLE_EXPORT id<NMBMatcher> NMB_equal(id expectedValue);
NIMBLE_SHORT(id<NMBMatcher> equal(id expectedValue),
             NMB_equal(expectedValue));

NIMBLE_EXPORT NMBObjCBeCloseToMatcher *NMB_beCloseTo(NSNumber *expectedValue);
NIMBLE_SHORT(NMBObjCBeCloseToMatcher *beCloseTo(id expectedValue),
             NMB_beCloseTo(expectedValue));

NIMBLE_EXPORT id<NMBMatcher> NMB_beAnInstanceOf(Class expectedClass);
NIMBLE_SHORT(id<NMBMatcher> beAnInstanceOf(Class expectedClass),
             NMB_beAnInstanceOf(expectedClass));

NIMBLE_EXPORT id<NMBMatcher> NMB_beAKindOf(Class expectedClass);
NIMBLE_SHORT(id<NMBMatcher> beAKindOf(Class expectedClass),
             NMB_beAKindOf(expectedClass));

NIMBLE_EXPORT id<NMBMatcher> NMB_beginWith(id itemElementOrSubstring);
NIMBLE_SHORT(id<NMBMatcher> beginWith(id itemElementOrSubstring),
             NMB_beginWith(itemElementOrSubstring));

NIMBLE_EXPORT id<NMBMatcher> NMB_beGreaterThan(NSNumber *expectedValue);
NIMBLE_SHORT(id<NMBMatcher> beGreaterThan(NSNumber *expectedValue),
             NMB_beGreaterThan(expectedValue));

NIMBLE_EXPORT id<NMBMatcher> NMB_beGreaterThanOrEqualTo(NSNumber *expectedValue);
NIMBLE_SHORT(id<NMBMatcher> beGreaterThanOrEqualTo(NSNumber *expectedValue),
             NMB_beGreaterThanOrEqualTo(expectedValue));

NIMBLE_EXPORT id<NMBMatcher> NMB_beIdenticalTo(id expectedInstance);
NIMBLE_SHORT(id<NMBMatcher> beIdenticalTo(id expectedInstance),
             NMB_beIdenticalTo(expectedInstance));

NIMBLE_EXPORT id<NMBMatcher> NMB_beLessThan(NSNumber *expectedValue);
NIMBLE_SHORT(id<NMBMatcher> beLessThan(NSNumber *expectedValue),
             NMB_beLessThan(expectedValue));

NIMBLE_EXPORT id<NMBMatcher> NMB_beLessThanOrEqualTo(NSNumber *expectedValue);
NIMBLE_SHORT(id<NMBMatcher> beLessThanOrEqualTo(NSNumber *expectedValue),
             NMB_beLessThanOrEqualTo(expectedValue));

NIMBLE_EXPORT id<NMBMatcher> NMB_beTruthy(void);
NIMBLE_SHORT(id<NMBMatcher> beTruthy(void),
             NMB_beTruthy());

NIMBLE_EXPORT id<NMBMatcher> NMB_beFalsy(void);
NIMBLE_SHORT(id<NMBMatcher> beFalsy(void),
             NMB_beFalsy());

NIMBLE_EXPORT id<NMBMatcher> NMB_beTrue(void);
NIMBLE_SHORT(id<NMBMatcher> beTrue(void),
             NMB_beTrue());

NIMBLE_EXPORT id<NMBMatcher> NMB_beFalse(void);
NIMBLE_SHORT(id<NMBMatcher> beFalse(void),
             NMB_beFalse());

NIMBLE_EXPORT id<NMBMatcher> NMB_beNil(void);
NIMBLE_SHORT(id<NMBMatcher> beNil(void),
             NMB_beNil());

NIMBLE_EXPORT id<NMBMatcher> NMB_beEmpty(void);
NIMBLE_SHORT(id<NMBMatcher> beEmpty(void),
             NMB_beEmpty());

NIMBLE_EXPORT id<NMBMatcher> NMB_contain(id itemOrSubstring);
NIMBLE_SHORT(id<NMBMatcher> contain(id itemOrSubstring),
             NMB_contain(itemOrSubstring));

NIMBLE_EXPORT id<NMBMatcher> NMB_endWith(id itemElementOrSubstring);
NIMBLE_SHORT(id<NMBMatcher> endWith(id itemElementOrSubstring),
             NMB_endWith(itemElementOrSubstring));

NIMBLE_EXPORT NMBObjCRaiseExceptionMatcher *NMB_raiseException(void);
NIMBLE_SHORT(NMBObjCRaiseExceptionMatcher *raiseException(void),
             NMB_raiseException());

NIMBLE_EXPORT id<NMBMatcher> NMB_match(id expectedValue);
NIMBLE_SHORT(id<NMBMatcher> match(id expectedValue),
             NMB_match(expectedValue));

NIMBLE_EXPORT id<NMBMatcher> NMB_allPass(id matcher);
NIMBLE_SHORT(id<NMBMatcher> allPass(id matcher),
             NMB_allPass(matcher));

// In order to preserve breakpoint behavior despite using macros to fill in __FILE__ and __LINE__,
// define a builder that populates __FILE__ and __LINE__, and returns a block that takes timeout
// and action arguments. See https://github.com/Quick/Quick/pull/185 for details.
typedef void (^NMBWaitUntilTimeoutBlock)(NSTimeInterval timeout, void (^action)(void (^)(void)));
typedef void (^NMBWaitUntilBlock)(void (^action)(void (^)(void)));

NIMBLE_EXPORT NMBWaitUntilTimeoutBlock nmb_wait_until_timeout_builder(NSString *file, NSUInteger line);
NIMBLE_EXPORT NMBWaitUntilBlock nmb_wait_until_builder(NSString *file, NSUInteger line);

#define NMB_waitUntilTimeout nmb_wait_until_timeout_builder(@(__FILE__), __LINE__)
#define NMB_waitUntil nmb_wait_until_builder(@(__FILE__), __LINE__)

#ifndef NIMBLE_DISABLE_SHORT_SYNTAX
#define expect(...) NMB_expect(^id{ return (__VA_ARGS__); }, __FILE__, __LINE__)
#define expectAction(...) NMB_expect(^id{ (__VA_ARGS__); return nil; }, __FILE__, __LINE__)
#define waitUntilTimeout NMB_waitUntilTimeout
#define waitUntil NMB_waitUntil
#endif
