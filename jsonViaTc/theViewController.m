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
    
    [self initNetworkConnectionWithSSL:NO urlString:urlString portNumber:port];
    [self sendJSON];
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

- (void) sendJSON
{
    // RPC init
    RpcMessage *message = [[RpcMessage alloc] init];
    message.jsonrpc = @"2.0";
    message.method = @"test";
    message.rpcid = [NSNumber numberWithUnsignedInt:1];
    message.params = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:1],@"", nil];
    
    // JSON prepare
    NSArray *keys = [NSArray arrayWithObjects:@"jsonrpc",@"method",@"id",@"params", nil];
    NSArray *objects = [NSArray arrayWithObjects:message.jsonrpc,message.method,message.rpcid,message.params, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    // JSON Encode
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    
    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
    if (outputStream) {
        [outputStream write:[jsonData bytes] maxLength:[jsonData length]];
    } else {
        NSLog(@"No output Stream!");
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
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
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


@end
