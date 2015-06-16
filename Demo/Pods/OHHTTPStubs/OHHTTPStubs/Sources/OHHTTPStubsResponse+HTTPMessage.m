//
//  OHHTTPStubsResponse+HTTPMessage.m
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 01/09/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

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
                    inBundle:(NSBundle*)responsesBundle
{
    NSURL *responseURL = [responsesBundle?:[NSBundle bundleForClass:self.class] URLForResource:responseName
                                                                                   withExtension:@"response"];
    
    NSData *responseData = [NSData dataWithContentsOfURL:responseURL];
    NSAssert(responseData, @"Could not find HTTP response named '%@' in bundle '%@'", responseName, responsesBundle);
    
    return [self responseWithHTTPMessageData:responseData];
}

@end
