//
//  theViewController.m
//  jsonViaTc
//
//  Created by Superman on 24.10.12.
//  Copyright (c) 2012 Superman. All rights reserved.
//

#import "theViewController.h"
#import "RpcMessage.h"

@interface theViewController ()

@end

@implementation theViewController

@synthesize methodName, param1, param2, serverAnswer, jsonResult, iterator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TLC test server communication
    NSString *urlString = [NSString stringWithFormat:@"http://root.mkernel.de"];
    NSInteger port = 5555;
    
    iterator = [NSNumber numberWithUnsignedInt:0];
    [self initNetworkConnectionWithSSL:NO urlString:urlString portNumber:port];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - socket functions

- (void) initNetworkConnectionWithSSL:(BOOL)useSSL urlString:(NSString*)url portNumber:(NSInteger)port
{
    NSURL *website = [NSURL URLWithString:url];
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[website host], port, &readStream, &writeStream);
    
    NSLog(@"Write Stream Host Name %@", CFWriteStreamCopyProperty(writeStream, kCFStreamPropertySocketRemoteHostName));
    NSLog(@"Write Stream Post Number %@", CFWriteStreamCopyProperty(writeStream, kCFStreamPropertySocketRemotePortNumber));
    
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if ([inputStream streamStatus] == NSStreamStatusNotOpen)
        [inputStream open];
    if ([outputStream streamStatus] == NSStreamStatusNotOpen)
        [outputStream open];
    
    if (useSSL) {
        // SSL settings
        NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredCertificates,
                                  [NSNumber numberWithBool:YES], kCFStreamSSLAllowsAnyRoot,
                                  [NSNumber numberWithBool:NO], kCFStreamSSLValidatesCertificateChain,
                                  kCFNull,kCFStreamSSLPeerName,
                                  nil];
        
        [inputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL
                          forKey:NSStreamSocketSecurityLevelKey];
        [outputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL
                           forKey:NSStreamSocketSecurityLevelKey];
        
        CFReadStreamSetProperty((CFReadStreamRef)inputStream, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
        CFWriteStreamSetProperty((CFWriteStreamRef)outputStream, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
    }
}

- (void) stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    
	switch (streamEvent) {
            
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
            
		case NSStreamEventHasBytesAvailable:
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        // Create a string from buffer
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                            [serverAnswer setText:output];
                            serverAnswer.numberOfLines = 0;
                            [serverAnswer sizeToFit];
                        }
                        
                        // Convert an array from the intermediate string
                        NSData *jsonData = [output dataUsingEncoding:NSUTF8StringEncoding];
                        NSError* error;
                        NSArray* outArray = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
                        
                        // Display the result
                        if ([[outArray valueForKey:@"result"] isKindOfClass:[NSString class]]) {
                            NSString *result = [outArray valueForKey:@"result"];
                            [jsonResult setText:result];
                        } else {
                            NSString *result = [[outArray valueForKey:@"result"] stringValue];
                            [jsonResult setText:result];
                        }
                        
                    
                    }
                }
            }
			break;
            
		case NSStreamEventErrorOccurred: {
			NSLog(@"Can not connect to the host!");
            NSError* error = [theStream streamError];
            NSString* errorMessage = [NSString stringWithFormat:@"%@ (Code = %d)",
                                      [error localizedDescription],
                                      [error code]];
            NSLog(@"%@",errorMessage);
            
        } break;
            
		case NSStreamEventEndEncountered:
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			break;
            
		default:
			NSLog(@"Unknown event");
	}
    
}

#pragma mark - data to string

- (NSString *)getString:(NSData*)theData
{
    Byte *dataPointer = (Byte *)[theData bytes];
    NSMutableString *result = [NSMutableString stringWithCapacity:0];
    NSUInteger index;
    for (index = 0; index < [theData length]; index++)
    {
        [result appendFormat:@"0x%02x,", dataPointer[index]];
    }
    return result;
}

#pragma mark - Actions

- (IBAction)sendJSON
{
    // Hide the keyboard
    [self.view endEditing:NO];
    // increment the RPC ID
    iterator = [NSNumber numberWithUnsignedInt:[iterator intValue]+1];
    
    // RPC init
    RpcMessage *message = [[RpcMessage alloc] init];
    message.jsonrpc = @"2.0";
    message.method = methodName.text;
    message.rpcid = iterator;
    message.params = [NSArray arrayWithObjects:param1.text,param2.text, nil];
    
    // JSON prepare
    NSArray *keys = [NSArray arrayWithObjects:@"jsonrpc",@"method",@"id",@"params", nil];
    NSArray *objects = [NSArray arrayWithObjects:message.jsonrpc,message.method,message.rpcid,message.params, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    // JSON Encode
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@", jsonString);
    
    
    if (outputStream) {
        [outputStream write:[jsonData bytes] maxLength:[jsonData length]];
    } else {
        NSLog(@"No output Stream!");
    }
}

@end
