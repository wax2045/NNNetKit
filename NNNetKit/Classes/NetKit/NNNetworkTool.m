//
//  NNNetworkTool.m
//  NNNetworkTool
//
//  Created by FUWANG on 2017/10/13.
//  Copyright © 2017年 FUWANG. All rights reserved.
//

#import "NNNetworkTool.h"
#import "YYModel.h"
#import "NNHttpTool.h"

/**
 2017.10.13 创建项目
 2018.01.17 修改请求完成回调 增加返回原数据
 2018.07.12 新增GET POST 请求方法 ，修改模型解析框架
 
 */
@implementation NNNetworkTool
+ (void)NNNetworkGetArrData:(BOOL)isGetArrData
                  URLString:(NSString *)URLString
                     params:(id)params
              pickClassName:(NSString *)pickClassName
                   complete:(void(^)(id netData,id response))complete
                    failure:(void(^)(NSString *error))failure
{
    [self NNNetworkGET:YES isGetArrData:isGetArrData URLString:URLString params:params pickClassName:pickClassName complete:complete failure:failure];
}

+ (void)NNNetworkPOSTArrData:(BOOL)isGetArrData
                   URLString:(NSString *)URLString
                      params:(id)params
               pickClassName:(NSString *)pickClassName
                    complete:(void(^)(id netData,id response))complete
                     failure:(void(^)(NSString *error))failure
{
    [self NNNetworkGET:NO isGetArrData:isGetArrData URLString:URLString params:params pickClassName:pickClassName complete:complete failure:failure];
}

+ (void)NNNetworkGET:(BOOL)GET
        isGetArrData:(BOOL)isGetArrData
           URLString:(NSString *)URLString
              params:(id)params
       pickClassName:(NSString *)pickClassName
            complete:(void(^)(id netData,id response))complete
             failure:(void(^)(NSString *error))failure
{
    //包装params
    //更高效
    NSDictionary *paramsDict;
    if (params) {
        if ([params isKindOfClass:[NSDictionary class]]) {
            paramsDict = params;
        }else {
            paramsDict = ((NSString *)params).yy_modelToJSONObject;
        }
    }
    
    if (GET) {
        [NNHttpTool GETWithURLString:URLString params:paramsDict success:^(id response) {
            [self pickData:response isGetArrData:isGetArrData pickClassName:pickClassName complete:complete failure:failure];
        } failure:^(NSError *error) {
            failure(error.description);
        }];
    }else {
        [NNHttpTool POSTWithURLString:URLString params:paramsDict success:^(id response) {
            [self pickData:response isGetArrData:isGetArrData pickClassName:pickClassName complete:complete failure:failure];
        } failure:^(NSError *error) {
            failure([NSString stringWithFormat:@"%@",error.userInfo[@"NSDebugDescription"]]);
        }];
    }
}




+ (void)pickData:(id)response
    isGetArrData:(BOOL)isGetArrData
   pickClassName:(NSString *)pickClassName
        complete:(void(^)(id netData,id response))complete
         failure:(void(^)(NSString *error))failure
{
    NSLog(@"%@",response);
    @try {
        //safe
        if ([response isKindOfClass:[NSNull class]]) {
            failure(@"后台返回null");
            return;
        }
        //json check
        if ([response isKindOfClass:[NSDictionary class]]) {
            
            if (isGetArrData) {
                //获取数组对象
                //解决数据加载完毕后返回数据没有数组后会不会操作问题 这时应该返回json数据
                __block BOOL notFindArrDataFlag = YES;
                [(NSDictionary *)response enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    
                    //判断是否有包装模型
                    if ([obj isKindOfClass:[NSArray class]]) {
                        notFindArrDataFlag = NO;
                        if (pickClassName.length) {
                            
                            NSMutableArray *arrM = [NSMutableArray array];
                            Class modeClass = NSClassFromString(pickClassName);
                            if (modeClass == nil) {
                                failure(@"包装数据模型名称错误");
                                return;
                            }
                            for (NSDictionary *dict in obj) {
                                id data = [modeClass yy_modelWithDictionary:dict];
                                [arrM addObject:data];
                            }
                            complete(arrM,response);
                        }else {
                            complete(obj,response);
                        }
                        *stop = YES;
                    }
                }];
                //一般处理分页加载更多时，数据加载完毕处理
                if (notFindArrDataFlag) {
                    complete(@[],response);
                }
            }else {
                if (pickClassName.length) {
                    complete([NSClassFromString(pickClassName) yy_modelWithDictionary:response],response);
                }else {
                    complete(response,response);
                }
            }
        }else {
            failure(@"非json数据");
            return;
        }
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
        failure(@"解析数据异常");
    } @finally {
    }
    
}
@end
