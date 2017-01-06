//
//  UploadManager.m
//  SoundDemo4
//
//  Created by FlyElephant on 17/1/6.
//  Copyright © 2017年 FlyElephant. All rights reserved.
//

#import "UploadManager.h"
#import "AFHTTPRequestOperationManager.h"

@implementation UploadManager

+ (void)upload:(NSString *)filePath {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"index": @"32"};
     [manager POST:@"http://10.0.1.216:3000/add" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
       [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:@"feature" error:nil];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
      NSLog(@"Success: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      NSLog(@"Error: %@", error);
    }];
}


@end
