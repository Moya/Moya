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


/* This category is not available on watchOS because CFNetwork is needed for its implementation but isn't available on Nano */
#if __has_include(<CFNetwork/CFNetwork.h>)

#import "OHHTTPStubsResponse.h"
#import "Compatibility.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Adds support for building stubs from "HTTP Messages" conforming to
 *  the format output by `curl -is`
 *
 *  @note This category is not available on watchOS
 */
@interface OHHTTPStubsResponse (HTTPMessage)

/*! @name Building a response from HTTP Message data */

// TODO: Try to implement it using NSInputStream someday?

/**
 * Builds a response given a message data as returned by `curl -is [url]`, that is containing both the headers and the body.
 *
 * This method will split the headers and the body and build a OHHTTPStubsReponse accordingly
 *
 * @param responseData The NSData containing the whole HTTP response, including the headers and the body
 *
 * @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
+(instancetype)responseWithHTTPMessageData:(NSData*)responseData;

/**
 * Builds a response given the name of a `"*.response"` file containing both the headers and the body.
 *
 * The response file is expected to be in the specified bundle (or the application bundle if nil).
 * This method will split the headers and the body and build a OHHTTPStubsReponse accordingly
 *
 * @param responseName The name of the `"*.response"` file (without extension) containing the whole
 *                     HTTP response (including the headers and the body)
 * @param bundleOrNil  The bundle in which the `"*.response"` file is located. If `nil`, the
 *                     `[NSBundle bundleForClass:self.class]` will be used.
 *
 * @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */

+(instancetype)responseNamed:(NSString*)responseName
                    inBundle:(nullable NSBundle*)bundleOrNil;


@end

NS_ASSUME_NONNULL_END

#endif
