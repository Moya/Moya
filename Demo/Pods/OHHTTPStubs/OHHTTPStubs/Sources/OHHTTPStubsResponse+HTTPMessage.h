//
//  OHHTTPStubsResponse+HTTPMessage.h
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 01/09/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import "OHHTTPStubsResponse.h"

#ifdef NS_ASSUME_NONNULL_BEGIN
  NS_ASSUME_NONNULL_BEGIN
  #define _nullable_ __nullable
#else
  #define _nullable_
#endif


/**
 *  Adds support for building stubs from "HTTP Messages" conforming to
 *  the format output by `curl -is`
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
                    inBundle:(NSBundle* _nullable_)bundleOrNil;


@end

#ifdef NS_ASSUME_NONNULL_END
  NS_ASSUME_NONNULL_END
#endif
