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


#import <OHHTTPStubs/OHHTTPStubsResponse+JSON.h>

@implementation OHHTTPStubsResponse (JSON)

/*! @name Building a response from JSON objects */

+ (instancetype)responseWithJSONObject:(id)jsonObject
                            statusCode:(int)statusCode
                               headers:(nullable NSDictionary *)httpHeaders
{
    if (!httpHeaders[@"Content-Type"])
    {
        NSMutableDictionary* mutableHeaders = [NSMutableDictionary dictionaryWithDictionary:httpHeaders];
        mutableHeaders[@"Content-Type"] = @"application/json";
        httpHeaders = [NSDictionary dictionaryWithDictionary:mutableHeaders]; // make immutable again
    }
    
    return [self responseWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil]
                       statusCode:statusCode
                          headers:httpHeaders];
}

@end
