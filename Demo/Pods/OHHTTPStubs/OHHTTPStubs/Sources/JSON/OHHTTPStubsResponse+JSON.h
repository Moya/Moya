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


#import <OHHTTPStubs/OHHTTPStubsResponse.h>
#import <OHHTTPStubs/Compatibility.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Adds convenience methods to manipulate JSON objects directly.
 *  Pass in an `NSDictionary` or `NSArray` to generate a corresponding JSON output.
 */
@interface OHHTTPStubsResponse (JSON)

/**
 *  Builds a response given a JSON object for the response body, status code, and headers.
 *
 *  @param jsonObject  Object representing the response body.
 *                     Typically a `NSDictionary`; may be any object accepted by `+[NSJSONSerialization dataWithJSONObject:options:error:]`
 *  @param statusCode  The HTTP Status Code to use in the response
 *  @param httpHeaders The HTTP Headers to return in the response
 *                     If a "Content-Type" header is not included, "Content-Type: application/json" will be added.
 *
 *  @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 *
 *  @note This method typically calls `responseWithData:statusCode:headers:`, passing the serialized JSON
 *        object as the data parameter and adding the Content-Type header if necessary.
 */
+ (instancetype)responseWithJSONObject:(id)jsonObject
                            statusCode:(int)statusCode
                               headers:(nullable NSDictionary *)httpHeaders;

@end

NS_ASSUME_NONNULL_END
