#import <Nimble/DSL.h>
#import <Nimble/Nimble-Swift.h>

NIMBLE_EXPORT NMBExpectation *NMB_expect(id(^actualBlock)(), const char *file, unsigned int line) {
    return [[NMBExpectation alloc] initWithActualBlock:actualBlock
                                              negative:NO
                                                  file:[[NSString alloc] initWithFormat:@"%s", file]
                                                  line:line];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beAnInstanceOf(Class expectedClass) {
    return [NMBObjCMatcher beAnInstanceOfMatcher:expectedClass];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beAKindOf(Class expectedClass) {
    return [NMBObjCMatcher beAKindOfMatcher:expectedClass];
}

NIMBLE_EXPORT NMBObjCBeCloseToMatcher *NMB_beCloseTo(NSNumber *expectedValue) {
    return [NMBObjCMatcher beCloseToMatcher:expectedValue within:0.001];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beginWith(id itemElementOrSubstring) {
    return [NMBObjCMatcher beginWithMatcher:itemElementOrSubstring];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beGreaterThan(NSNumber *expectedValue) {
    return [NMBObjCMatcher beGreaterThanMatcher:expectedValue];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beGreaterThanOrEqualTo(NSNumber *expectedValue) {
    return [NMBObjCMatcher beGreaterThanOrEqualToMatcher:expectedValue];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beIdenticalTo(id expectedInstance) {
    return [NMBObjCMatcher beIdenticalToMatcher:expectedInstance];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beLessThan(NSNumber *expectedValue) {
    return [NMBObjCMatcher beLessThanMatcher:expectedValue];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beLessThanOrEqualTo(NSNumber *expectedValue) {
    return [NMBObjCMatcher beLessThanOrEqualToMatcher:expectedValue];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beTruthy() {
    return [NMBObjCMatcher beTruthyMatcher];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beFalsy() {
    return [NMBObjCMatcher beFalsyMatcher];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beTrue() {
    return [NMBObjCMatcher beTrueMatcher];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beFalse() {
    return [NMBObjCMatcher beFalseMatcher];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_beNil() {
    return [NMBObjCMatcher beNilMatcher];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_contain(id itemOrSubstring) {
    return [NMBObjCMatcher containMatcher:itemOrSubstring];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_endWith(id itemElementOrSubstring) {
    return [NMBObjCMatcher endWithMatcher:itemElementOrSubstring];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_equal(id expectedValue) {
    return [NMBObjCMatcher equalMatcher:expectedValue];
}

NIMBLE_EXPORT id<NMBMatcher> NMB_match(id expectedValue) {
    return [NMBObjCMatcher matchMatcher:expectedValue];
}

NIMBLE_EXPORT NMBObjCRaiseExceptionMatcher *NMB_raiseException() {
    return [NMBObjCMatcher raiseExceptionMatcher];
}

