//
//  NNHttpTool.m
//  H1Hub
//
//  Created by 吴狄 on 16/6/23.
//  Copyright © 2016年 NDL. All rights reserved.
//

#import "NNHttpTool.h"
#import "AFNetworking.h"

@implementation NNHttpTool
+ (instancetype)shareManager
{
    static NNHttpTool *instance = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        instance = [[NNHttpTool alloc]init];
        instance.manager = [AFHTTPSessionManager manager];
    });
    return instance;
}
- (void)GETWithURLString:(NSString *)URLString params:(id)params success:(void(^)(id response))success failure:(void(^)(NSError *error))failure
{
    //显示加载网络状态
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [[NNHttpTool shareManager].manager GET:URLString parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
         success(responseObject);
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
        NSLog(@"%@",error);
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    }];
}
- (void)POSTWithURLString:(NSString *)URLString params:(id)params success:(void(^)(id response))success failure:(void(^)(NSError *error))failure
{
    //显示加载网络状态
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[NNHttpTool shareManager].manager POST:URLString parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
        NSLog(@"%@",error);
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

+ (void)GETWithURLString:(NSString *)URLString params:(id)params success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    [[self shareManager] GETWithURLString:URLString params:params success:success failure:failure];
}
+ (void)POSTWithURLString:(NSString *)URLString params:(id)params success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    ((NNHttpTool *)[self shareManager]).manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[self shareManager] POSTWithURLString:URLString params:params success:success failure:failure];
}

+ (void)POSTNoBackJsonWithURLString:(NSString *)URLString params:(id)params success:(void (^)(id response))success failure:(void (^)(NSError *error))failure;
{
    ((NNHttpTool *)[self shareManager]).manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [[self shareManager] POSTWithURLString:URLString params:params success:success failure:failure];

}


@end





