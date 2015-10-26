/***********************************************************************************
 *
 * Copyright (c) 2012 Olivier Halligon
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 ***********************************************************************************/

#import <Foundation/Foundation.h>

#if defined(__IPHONE_7_0) || defined(__MAC_10_9)
#import <objc/runtime.h>

#import "OHHTTPStubs.h"


//////////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  This helper is used to swizzle NSURLSessionConfiguration constructor methods
 *  defaultSessionConfiguration and ephemeralSessionConfiguration to insert the private
 *  OHHTTPStubsProtocol into their protocolClasses array so that OHHTTPStubs is automagically
 *  supported when you create a new NSURLSession based on one of there configurations.
 */

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;
static SessionConfigConstructor orig_ephemeralSessionConfiguration;

static SessionConfigConstructor OHHTTPStubsSwizzle(SEL selector, SessionConfigConstructor newImpl)
{
    Class cls = NSURLSessionConfiguration.class;
    Class metaClass = object_getClass(cls);
    
    Method origMethod = class_getClassMethod(cls, selector);
    SessionConfigConstructor origImpl = (SessionConfigConstructor)method_getImplementation(origMethod);
    if (!class_addMethod(metaClass, selector, (IMP)newImpl, method_getTypeEncoding(origMethod)))
    {
        method_setImplementation(origMethod, (IMP)newImpl);
    }
    return origImpl;
}

static NSURLSessionConfiguration* OHHTTPStubs_defaultSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_defaultSessionConfiguration(self,_cmd); // call original method
    [OHHTTPStubs setEnabled:YES forSessionConfiguration:config]; //OHHTTPStubsAddProtocolClassToNSURLSessionConfiguration(config);
    return config;
}

static NSURLSessionConfiguration* OHHTTPStubs_ephemeralSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_ephemeralSessionConfiguration(self,_cmd); // call original method
    [OHHTTPStubs setEnabled:YES forSessionConfiguration:config]; //OHHTTPStubsAddProtocolClassToNSURLSessionConfiguration(config);
    return config;
}

@interface NSURLSessionConfiguration(OHHTTPStubsSupport) @end
@implementation NSURLSessionConfiguration(OHHTTPStubsSupport)
+(void)load
{
    orig_defaultSessionConfiguration = OHHTTPStubsSwizzle(@selector(defaultSessionConfiguration),
                                                          OHHTTPStubs_defaultSessionConfiguration);
    orig_ephemeralSessionConfiguration = OHHTTPStubsSwizzle(@selector(ephemeralSessionConfiguration),
                                                            OHHTTPStubs_ephemeralSessionConfiguration);
}
@end

#endif


