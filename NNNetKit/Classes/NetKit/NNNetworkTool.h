//
//  NNNetworkTool.h
//  NNNetworkTool
//
//  Created by FUWANG on 2017/10/13.
//  Copyright © 2017年 FUWANG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNNetworkTool : NSObject
/**
 进一步包装网络请求，自带异常处理 是安全的

 @param isGetArrData 获取数据是否是数组类型，或者是NSDict类型 
 注：如果选择了数组 如果没有找到 默认返回一个空数组
 @param URLString 网址
 @param params 请求参数 字典或者模型
 @param pickClassName 包装数据的类名
 @param complete 完成回调
 @param failure 请求异常，有异常提示 你可以自定义异常情况 配合后台
 */
+ (void)NNNetworkGetArrData:(BOOL)isGetArrData URLString:(NSString *)URLString
                     params:(id)params
              pickClassName:(NSString *)pickClassName
                   complete:(void(^)(id netData,id response))complete
                    failure:(void(^)(NSString *error))failure;
@end
