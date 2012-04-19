//
// AFGXMLRequestOperation.m
//
// Copyright (c) 2012 TwoTap Labs (http://twotaplabs.com/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFGXMLRequestOperation.h"

static dispatch_queue_t af_gxml_request_operation_processing_queue;
static dispatch_queue_t gxml_request_operation_processing_queue() {
    if (af_gxml_request_operation_processing_queue == NULL) {
        af_gxml_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.gxml-request.processing", 0);
    }
    
    return af_gxml_request_operation_processing_queue;
}

@interface AFGXMLRequestOperation ()
@property (readwrite, nonatomic, retain) GDataXMLDocument *responseXML;
@property (readwrite, nonatomic, retain) NSError *error;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFGXMLRequestOperation
@synthesize responseXML = _responseXML;
@synthesize error = _XMLError;

+ (AFGXMLRequestOperation *)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                        success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, GDataXMLDocument *xml))success
                                                        failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, GDataXMLDocument *xml))failure
{
    AFGXMLRequestOperation *requestOperation = [[[self alloc] initWithRequest:urlRequest] autorelease];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AFGXMLRequestOperation *)operation responseXML]);
        }
    }];
    
    return requestOperation;
}


+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/xml", @"text/xml", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"xml", nil];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
    return self;
}

- (GDataXMLDocument *)responseXML {
    if (!_responseXML && [self isFinished]) {
        NSError *error = nil;        
        self.responseXML = [[GDataXMLDocument alloc] initWithData:self.responseData options:0 error:&error];
        self.error = error;
    }
    
    return _responseXML;
}

- (NSError *)error {
    if (_XMLError) {
        return _XMLError;
    } else {
        return [super error];
    }
}

#pragma mark - NSOperation

- (void)cancel {
    [super cancel];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {  
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    self.completionBlock = ^ {
        if ([self isCancelled]) {
            return;
        }
        
        if (self.error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    failure(self, self.error);
                });
            }
        } else {
            dispatch_async(gxml_request_operation_processing_queue(), ^(void) {
                id XML = self.responseXML;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if (self.error) {
                        if (failure) {
                            failure(self, self.error);
                        }
                    } else {
                        if (success) {
                            success(self, XML);
                        }
                    }
                }); 
            });   
        }
    };    
}
@end
