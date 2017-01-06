//
//  ViewController.m
//  SoundDemo4
//
//  Created by FlyElephant on 17/1/4.
//  Copyright © 2017年 FlyElephant. All rights reserved.
//

#import "ViewController.h"
#import "AFHTTPRequestOperationManager.h"
#include "make_features.h"
#import "TKAudioRecorderManager.h"

#define bound  @"----WebKitFormBoundaryjh7urS5p3OcvqXAT"

@interface ViewController ()

@property (strong, nonatomic) NSURLSession *session;

@property (copy, nonatomic) NSString *recordPath;

@property (copy, nonatomic) NSString *featurePath;

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)recordAction:(UIButton *)sender {
    [[TKAudioRecorderManager sharedInstance] record];
}

- (IBAction)stopRecordAction:(UIButton *)sender {
    [[TKAudioRecorderManager sharedInstance] stopRecord];
    [self makefeature];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uploadFeature];
    });
}

- (IBAction)playAction:(UIButton *)sender {
    [[TKAudioRecorderManager sharedInstance] play];
}

- (IBAction)stopPlayAction:(UIButton *)sender {
    [[TKAudioRecorderManager sharedInstance] stopPlay];
}


- (IBAction)makeFeatureAction:(UIButton *)sender {
    [self makefeature];
}

- (IBAction)uploadAction:(UIButton *)sender {
    [self uploadFeature];
}

- (void)makefeature {
    NSInteger time = [[NSDate date] timeIntervalSince1970];
    NSString *fileName = [NSString stringWithFormat:@"record-%ld",time];
    NSString *outPutPath = [self filePathWithDirectoryName:@"" fileName:fileName];
    self.featurePath = outPutPath;
    NSLog(@"record--输出路径---%@",outPutPath);
    //   NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"record" ofType:@"wav"];
    NSString *soundPath = [TKAudioRecorderManager sharedInstance].recordPath;
    NSLog(@"录音文件地址--%@",soundPath);
    NSString *result = [self makeScore:soundPath featurePath:outPutPath];
    
    NSLog(@"record----打分---%@",result);
}

- (void)uploadFeature {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"index": @"32"};
    [manager POST:@"http://10.0.1.216:3000/add" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:self.featurePath] name:@"feature" error:nil];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success: %@", responseObject);
        NSString *result = [NSString stringWithFormat:@"Success: %@", responseObject];
        NSLog(@"%@",result);
        self.resultLabel.text = result;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - MakeScore

- (NSString *)makeScore:(NSString *)audioPath featurePath:(NSString *)featurePath {
    std::string cpp_audioPath([audioPath UTF8String], [audioPath lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    MakeFeatures makeFeatures(cpp_audioPath);
    
    //ark:文件完整路径
    NSString *makePath = [NSString stringWithFormat:@"%@",featurePath];
    std::string cpp_outPath([makePath UTF8String], [makePath lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    
    
    NSString *strResult = @"";
    std::string cpp_strResult([strResult UTF8String], [strResult lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    
    makeFeatures.make_features(cpp_outPath);
    
    return @"Success";
    
}

- (NSString *)filePathWithDirectoryName:(NSString *)dirName fileName:(NSString *)fileName {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",cacheDirectory,fileName];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSLog(@"删除file文件路径");
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
    return filePath;
}


#pragma mark - UploadData



- (void)originalUploadFile {
    
    NSDictionary *params = @{
                             @"userName"    : @"FlyElephant"};
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jpg"];
    NSString *boundary = [self generateBoundaryString];
    
    // 请求的Url
    NSURL *url = [NSURL URLWithString:@"http://10.0.1.216:3000/add"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    // 设置ContentType
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSString *fieldName = @"CustomFile";
    NSData *httpBody = [self createBodyWithBoundary:boundary parameters:params paths:@[path] fieldName:fieldName];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:httpBody completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"error = %@", error);
            return;
        }
        
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"FlyElephant-返回结果---result = %@", result);
    }];
    [task resume];
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             paths:(NSArray *)paths
                         fieldName:(NSString *)fieldName {
    NSMutableData *httpBody = [NSMutableData data];
    
    // 文本参数
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // 本地文件的NSData
    
    for (NSString *path in paths) {
        NSString *filename  = [path lastPathComponent];
        NSData   *data      = [NSData dataWithContentsOfFile:path];
        NSString *mimetype  = [self mimeTypeForPath:path];
        
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
        [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return httpBody;
}

- (NSString *)mimeTypeForPath:(NSString *)path {
    
    //CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
   // CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);

    //NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    
  //  CFRelease(UTI);
    
    //return mimetype;
    return @"";
}

- (NSString *)generateBoundaryString {
    return [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
}

@end
