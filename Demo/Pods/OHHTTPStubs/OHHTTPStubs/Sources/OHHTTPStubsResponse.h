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

// For SDK 7.1 Compatibility (as this macro was only included starting SDK 8.0)
#ifndef NS_DESIGNATED_INITIALIZER
  #if __has_attribute(objc_designated_initializer)
    #define NS_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
  #else
    #define NS_DESIGNATED_INITIALIZER
  #endif
#endif

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Imports

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Defines & Constants

// Standard download speeds.
extern const double
OHHTTPStubsDownloadSpeedGPRS,
OHHTTPStubsDownloadSpeedEDGE,
OHHTTPStubsDownloadSpeed3G,
OHHTTPStubsDownloadSpeed3GPlus,
OHHTTPStubsDownloadSpeedWifi;

#ifdef NS_ASSUME_NONNULL_BEGIN
  NS_ASSUME_NONNULL_BEGIN
  #define _nullable_ __nullable
#else
  #define _nullable_
#endif


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

/**
 *  Stubs Response. This describes a stubbed response to be returned by the URL Loading System,
 *  including its HTTP headers, body, statusCode and response time.
 */
@interface OHHTTPStubsResponse : NSObject

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Properties

/**
 *  The headers to use for the fake response
 */
@property(nonatomic, strong) NSDictionary* _nullable_ httpHeaders;
/**
 *  The HTTP status code to use for the fake response
 */
@property(nonatomic, assign) int statusCode;
/**
 *  The inputStream used when sending the response.
 *  @note You generally don't manipulate this directly.
 */
@property(nonatomic, strong) NSInputStream* _nullable_ inputStream;
/**
 *  The size of the fake response body, in bytes.
 */
@property(nonatomic, assign) unsigned long long dataSize;
/**
 *  The duration to wait before faking receiving the response headers.
 *
 *  Defaults to 0.0.
 */
@property(nonatomic, assign) NSTimeInterval requestTime;
/**
 *  The duration to use to send the fake response body.
 *
 * @note if responseTime<0, it is interpreted as a download speed in KBps ( -200 => 200KB/s )
 */
@property(nonatomic, assign) NSTimeInterval responseTime;
/**
 *  The fake error to generate to simulate a network error.
 *
 *  If `error` is non-`nil`, the request will result in a failure and no response will be sent.
 */
@property(nonatomic, strong) NSError* _nullable_ error;




////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commodity Constructors
/*! @name Commodity */

/* -------------------------------------------------------------------------- */
#pragma mark > Building response from NSData

/**
 *  Builds a response given raw data.
 *
 *  @note Internally calls `-initWithInputStream:dataSize:statusCode:headers:` with and inputStream built from the NSData.
 *
 *  @param data The raw data to return in the response
 *  @param statusCode The HTTP Status Code to use in the response
 *  @param httpHeaders The HTTP Headers to return in the response
 *  @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
+(instancetype)responseWithData:(NSData*)data
                     statusCode:(int)statusCode
                        headers:(NSDictionary* _nullable_)httpHeaders;


/* -------------------------------------------------------------------------- */
#pragma mark > Building response from a file

/**
 *  Builds a response given a file path, the status code and headers.
 *
 *  @param filePath The file path that contains the response body to return.
 *  @param statusCode The HTTP Status Code to use in the response
 *  @param httpHeaders The HTTP Headers to return in the response
 *
 *  @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 *
 *  @note It is encouraged to use the OHPathHelpers functions & macros to build
 *        the filePath parameter easily
 */
+(instancetype)responseWithFileAtPath:(NSString *)filePath
                           statusCode:(int)statusCode
                              headers:(NSDictionary* _nullable_)httpHeaders;

/* -------------------------------------------------------------------------- */
#pragma mark > Building an error response

/**
 *  Builds a response that corresponds to the given error
 *
 *  @param error The error to use in the stubbed response.
 *
 *  @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 *
 *  @note For example you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]`
 */
+(instancetype)responseWithError:(NSError*)error;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commotidy Setters

/**
 *  Set the `responseTime` of the `OHHTTPStubsResponse` and return `self`. Useful for chaining method calls.
 *
 *  _Usage example:_
 *  <pre>return [[OHHTTPStubsReponse responseWithData:data statusCode:200 headers:nil] responseTime:5.0];</pre>
 *
 *  @param responseTime If positive, the amount of time used to send the entire response.
 *                     If negative, the rate in KB/s at which to send the response data.
 *                     Useful to simulate slow networks for example. You may use the
 *                     _OHHTTPStubsDownloadSpeed…_ constants here.
 *
 *  @return `self` (= the same `OHHTTPStubsResponse` that was the target of this method).
 *          Returning `self` is useful for chaining method calls.
 */
-(instancetype)responseTime:(NSTimeInterval)responseTime;

/**
 *  Set both the `requestTime` and the `responseTime` of the `OHHTTPStubsResponse` at once.
 *  Useful for chaining method calls.
 *
 *  _Usage example:_
 *  <pre>return [[OHHTTPStubsReponse responseWithData:data statusCode:200 headers:nil]
 *            requestTime:1.0 responseTime:5.0];</pre>
 *
 *  @param requestTime The time to wait before the response begins to send. This value must be greater than or equal to zero.
 *  @param responseTime If positive, the amount of time used to send the entire response.
 *                      If negative, the rate in KB/s at which to send the response data.
 *                      Useful to simulate slow networks for example. You may use the
 *                      _OHHTTPStubsDownloadSpeed…_ constants here.
 *
 *  @return `self` (= the same `OHHTTPStubsResponse` that was the target of this method). Useful for chaining method calls.
 */
-(instancetype)requestTime:(NSTimeInterval)requestTime responseTime:(NSTimeInterval)responseTime;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initializers
/*! @name Initializers */

/**
 *  Designed initializer. Initialize a response with the given input stream, dataSize, 
 *  statusCode and headers.
 *
 *  @param inputStream The input stream that will provide the data to return in the response
 *  @param dataSize The size of the data in the stream.
 *  @param statusCode The HTTP Status Code to use in the response
 *  @param httpHeaders The HTTP Headers to return in the response
 *
 *  @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 *
 *  @note You will probably never need to call this method yourself. Prefer the other initializers (that will call this method eventually)
 */
-(instancetype)initWithInputStream:(NSInputStream*)inputStream
                          dataSize:(unsigned long long)dataSize
                        statusCode:(int)statusCode
                           headers:(NSDictionary* _nullable_)httpHeaders NS_DESIGNATED_INITIALIZER;


/**
 *  Initialize a response with a given file path, statusCode and headers.
 *
 *  @param filePath The file path of the data to return in the response
 *  @param statusCode The HTTP Status Code to use in the response
 *  @param httpHeaders The HTTP Headers to return in the response
 *
 *  @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 *
 *  @note This method simply builds the NSInputStream, compute the file size, and then call `-initWithInputStream:dataSize:statusCode:headers:`
 */
-(instancetype)initWithFileAtPath:(NSString*)filePath
                       statusCode:(int)statusCode
                          headers:(NSDictionary* _nullable_)httpHeaders;


/**
 *  Initialize a response with the given data, statusCode and headers.
 *
 *  @param data The raw data to return in the response
 *  @param statusCode The HTTP Status Code to use in the response
 *  @param httpHeaders The HTTP Headers to return in the response
 *
 *  @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
-(instancetype)initWithData:(NSData*)data
                 statusCode:(int)statusCode
                    headers:(NSDictionary* _nullable_)httpHeaders;


/**
 *  Designed initializer. Initialize a response with the given error.
 *
 *  @param error The error to use in the stubbed response.
 *
 *  @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 *
 *  @note For example you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]`
 */
-(instancetype)initWithError:(NSError*)error NS_DESIGNATED_INITIALIZER;

@end

#ifdef NS_ASSUME_NONNULL_END
  NS_ASSUME_NONNULL_END
#endif
