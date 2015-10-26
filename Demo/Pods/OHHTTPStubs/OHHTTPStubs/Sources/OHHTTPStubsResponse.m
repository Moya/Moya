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

#if ! __has_feature(objc_arc)
#error This file is expected to be compiled with ARC turned ON
#endif

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Imports

#import "OHHTTPStubsResponse.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Defines & Constants
const double OHHTTPStubsDownloadSpeed1KBPS  =-     8 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeedSLOW   =-    12 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeedGPRS   =-    56 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeedEDGE   =-   128 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeed3G     =-  3200 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeed3GPlus =-  7200 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeedWifi   =- 12000 / 8; // kbps -> KB/s

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation OHHTTPStubsResponse

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commodity Constructors


#pragma mark > Building response from NSData

+(instancetype)responseWithData:(NSData*)data
                     statusCode:(int)statusCode
                        headers:(nullable NSDictionary*)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithData:data
                                                    statusCode:statusCode
                                                       headers:httpHeaders];
    return response;
}


#pragma mark > Building response from a file

+(instancetype)responseWithFileAtPath:(NSString *)filePath
                           statusCode:(int)statusCode
                              headers:(nullable NSDictionary *)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithFileAtPath:filePath
                                                          statusCode:statusCode
                                                             headers:httpHeaders];
    return response;
}

+(instancetype)responseWithFileURL:(NSURL *)fileURL
                        statusCode:(int)statusCode
                           headers:(nullable NSDictionary *)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithFileURL:fileURL
                                                       statusCode:statusCode
                                                          headers:httpHeaders];
    return response;
}

#pragma mark > Building an error response

+(instancetype)responseWithError:(NSError*)error
{
    OHHTTPStubsResponse* response = [[self  alloc] initWithError:error];
    return response;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commotidy Setters

-(instancetype)responseTime:(NSTimeInterval)responseTime
{
    _responseTime = responseTime;
    return self;
}

-(instancetype)requestTime:(NSTimeInterval)requestTime responseTime:(NSTimeInterval)responseTime
{
    _requestTime = requestTime;
    _responseTime = responseTime;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initializers

-(instancetype)init
{
    self = [super init];
    return self;
}

-(instancetype)initWithInputStream:(NSInputStream*)inputStream
                          dataSize:(unsigned long long)dataSize
                        statusCode:(int)statusCode
                           headers:(nullable NSDictionary*)httpHeaders
{
    self = [super init];
    if (self)
    {
        _inputStream = inputStream;
        _dataSize = dataSize;
        _statusCode = statusCode;
        NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:httpHeaders];
        static NSString *const ContentLengthHeader = @"Content-Length";
        if (!headers[ContentLengthHeader])
        {
            headers[ContentLengthHeader] = [NSString stringWithFormat:@"%llu",_dataSize];
        }
        _httpHeaders = [NSDictionary dictionaryWithDictionary:headers];
    }
    return self;
}

-(instancetype)initWithFileAtPath:(NSString*)filePath
                       statusCode:(int)statusCode
                          headers:(nullable NSDictionary*)httpHeaders
{
    NSURL *fileURL = filePath ? [NSURL fileURLWithPath:filePath] : nil;
    self = [self initWithFileURL:fileURL
                      statusCode:statusCode
                         headers:httpHeaders];
    return self;
}

-(instancetype)initWithFileURL:(NSURL *)fileURL
                    statusCode:(int)statusCode
                       headers:(nullable NSDictionary *)httpHeaders {
    if (!fileURL) {
        NSLog(@"%s: nil file path. Returning empty data", __PRETTY_FUNCTION__);
        return [self initWithInputStream:[NSInputStream inputStreamWithData:[NSData data]]
                                dataSize:0
                              statusCode:statusCode
                                 headers:httpHeaders];
    }
    
    // [NSURL -isFileURL] is only available on iOS 8+
    NSAssert([fileURL.scheme isEqualToString:NSURLFileScheme], @"%s: Only file URLs may be passed to this method.",__PRETTY_FUNCTION__);
    
    NSNumber *fileSize;
    NSError *error;
    const BOOL success __unused = [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:&error];
    
    NSAssert(success && fileSize, @"%s Couldn't get the file size for URL. \
The URL was: %@. \
The operation to retrieve the file size was %@. \
The error associated with that operation was: %@",
             __PRETTY_FUNCTION__, fileURL, success ? @"successful" : @"unsuccessful", error);
    
    return [self initWithInputStream:[NSInputStream inputStreamWithURL:fileURL]
                            dataSize:[fileSize unsignedLongLongValue]
                          statusCode:statusCode
                             headers:httpHeaders];
}

-(instancetype)initWithData:(NSData*)data
                 statusCode:(int)statusCode
                    headers:(nullable NSDictionary*)httpHeaders
{
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:data?:[NSData data]];
    self = [self initWithInputStream:inputStream
                            dataSize:data.length
                          statusCode:statusCode
                             headers:httpHeaders];
    return self;
}

-(instancetype)initWithError:(NSError*)error
{
    self = [super init];
    if (self) {
        _error = error;
    }
    return self;
}

-(NSString*)debugDescription
{
    return [NSString stringWithFormat:@"<%@ %p requestTime:%f responseTime:%f status:%d dataSize:%llu>",
            self.class, self, self.requestTime, self.responseTime, self.statusCode, self.dataSize];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

-(void)setRequestTime:(NSTimeInterval)requestTime
{
    NSAssert(requestTime >= 0, @"Invalid Request Time (%f) for OHHTTPStubResponse. Request time must be greater than or equal to zero",requestTime);
    _requestTime = requestTime;
}

@end
