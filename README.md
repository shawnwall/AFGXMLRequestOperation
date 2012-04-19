AFGXMLRequestOperation
======================

AFGXMLRequestOperation is an extension for [AFNetworking](http://github.com/AFNetworking/AFNetworking/) that creates fully instantiated [GDataXMLDocument](http://code.google.com/p/gdata-objectivec-client/source/browse/trunk/Source/XMLSupport/) instances instead of NSXMLParsers.

## Example Usage

``` objective-c
[apiClient registerHTTPOperationClass:[AFGXMLRequestOperation class]];
[apiClient getPath:@"path/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSLog(@"response xml doc %@", responseObject");
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"uh oh");
}];
```
