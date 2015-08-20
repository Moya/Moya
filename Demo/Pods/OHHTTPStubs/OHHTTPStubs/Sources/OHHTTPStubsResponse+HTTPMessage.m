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


#if __has_include(<CFNetwork/CFNetwork.h>)
#import <CFNetwork/CFNetwork.h>

#import "OHHTTPStubsResponse+HTTPMessage.h"

@implementation OHHTTPStubsResponse (HTTPMessage)

#pragma mark Building response from HTTP Message Data (dump from "curl -is")

+(instancetype)responseWithHTTPMessageData:(NSData*)responseData;
{
    NSData *data = [NSData data];
    NSInteger statusCode = 200;
    NSDictionary *headers = @{};
    
    CFHTTPMessageRef httpMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    if (httpMessage)
    {
        CFHTTPMessageAppendBytes(httpMessage, responseData.bytes, responseData.length);
        
        data = responseData; // By default
        
        if (CFHTTPMessageIsHeaderComplete(httpMessage))
        {
            statusCode = (NSInteger)CFHTTPMessageGetResponseStatusCode(httpMessage);
            headers = (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(httpMessage);
            data = (__bridge_transfer NSData *)CFHTTPMessageCopyBody(httpMessage);
        }
        CFRelease(httpMessage);
    }
    
    return [self responseWithData:data
                       statusCode:(int)statusCode
                          headers:headers];
}

+(instancetype)responseNamed:(NSString*)responseName
                    inBundle:(nullable NSBundle*)responsesBundle
{
    NSURL *responseURL = [responsesBundle?:[NSBundle bundleForClass:self.class] URLForResource:responseName
                                                                                   withExtension:@"response"];
    
    NSData *responseData = [NSData dataWithContentsOfURL:responseURL];
    NSAssert(responseData, @"Could not find HTTP response named '%@' in bundle '%@'", responseName, responsesBundle);
    
    return [self responseWithHTTPMessageData:responseData];
}

@end

#endif
