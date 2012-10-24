//
//  RpcMessage.h
//  chronox
//
//  Created by Superman on 11.10.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RpcMessage : NSObject

@property (strong, nonatomic) NSString *jsonrpc;
@property (strong, nonatomic) NSString *method;
@property (strong, nonatomic) NSNumber *rpcid;
@property (strong, nonatomic) NSArray *params;

@end
