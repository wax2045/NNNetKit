//
//  NNCacheData.h
//  sqltTest
//
//  Created by FUWANG on 2017/8/25.
//  Copyright © 2017年 FUWANG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNCacheData : NSObject
/**
 删除数据库 用于用户更新了账号  ？ 版本号更新了
 */
-(void)deleteFMDBFile;

+ (instancetype)shareManager;

/**
 更新数据库（没有就创建） 字定义key

 @param data 要更新的数据 模型 或者 字典
 @param tableName 数据库表名称
 @param IDPropertysNameArr 普通比较 判断是否存在 这个参数是固定的
 @param compareChangeRefrshPropertysNameArr 深度比较 判断是否有变化 用于动态更新数据库
 @param complete 数据库更新状态
 */
+ (void)NNUpdata:(id)data
       tableName:(NSString *)tableName
IDPropertysNameArr:(NSArray *)IDPropertysNameArr
compareChangeRefrshPropertysNameArr:(NSArray *)compareChangeRefrshPropertysNameArr
        complete:(void(^)(BOOL isNew))complete;

/**
 删除单个数据

 @param tableName 表名
 @param IDPropertysNameArr 确定删除对象的字段
 @param delectData 删除数据 可以是模型 可以是自动
 @param complete 删除回调 是否成功
 */
+ (void)NNDelectTableName:(NSString *)tableName
       IDPropertysNameArr:(NSArray *)IDPropertysNameArr
               delectData:(id)delectData
                 complete:(void(^)(BOOL isDelect))complete;


/**
 删除数据库

 @param tableName 数据库名称
 @param complete 完成回调
 */
+ (void)NNDelectTableWithTableName:(NSString *)tableName complete:(void(^)())complete;
/**
 获取数据库数据
 
 @param tableName 数据库表名
 @param isGetFirstData 是否从新加载第一页，为yes加载第一页，为no加载更多页数据 例如：where d_repay_date_origin > 1502281069 order by sh_status >0 desc ,d_repay_date_origin asc 代表筛选d_repay_date_origin大于某个时间搓的数据排序 以sh_status > 0 降序 和  d_repay_date_origin 正序
 @param sortSqlString 数据排序筛选语句 注：只包含筛选和排序的语句，其它选择表和页码语句自动填写
 @param pickDataClassName 用来包装数据的模型类名
 @param complete 数据查询完成回调
 */
+ (void)NNGetDataTableName:(NSString *)tableName
            isGetFirstData:(BOOL)isGetFirstData
             sortSqlString:(NSString *)sortSqlString
         pickDataClassName:(NSString *)pickDataClassName
                  complete:(void(^)(NSArray *dataArr))complete;
@end
