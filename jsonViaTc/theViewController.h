//
//  theViewController.h
//  jsonViaTc
//
//  Created by Superman on 24.10.12.
//  Copyright (c) 2012 Superman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface theViewController : UIViewController <NSStreamDelegate>

@property (strong, nonatomic) IBOutlet UITextField *methodName;
@property (strong, nonatomic) IBOutlet UITextField *param1;
@property (strong, nonatomic) IBOutlet UITextField *param2;


@property (strong, nonatomic) IBOutlet UILabel *serverAnswer;
@property (strong, nonatomic) IBOutlet UILabel *jsonResult;

@property (strong, nonatomic) NSNumber *iterator;

- (void) initNetworkConnectionWithSSL:(BOOL)useSSL urlString:(NSString*)url portNumber:(NSInteger)port;
- (NSString *)getString:(NSData*)theData;

- (IBAction)sendJSON;

@end

NSInputStream *inputStream;
NSOutputStream *outputStream;
