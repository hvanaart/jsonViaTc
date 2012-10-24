//
//  theViewController.h
//  jsonViaTc
//
//  Created by Superman on 24.10.12.
//  Copyright (c) 2012 Superman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface theViewController : UIViewController <NSStreamDelegate>

- (void) initNetworkConnectionWithSSL:(BOOL)useSSL urlString:(NSString*)url portNumber:(NSInteger)port;
- (void) sendJSON;
- (NSString *)getString:(NSData*)theData;


@end

NSInputStream *inputStream;
NSOutputStream *outputStream;
