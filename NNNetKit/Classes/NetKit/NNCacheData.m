//
//  NNCacheData.m
//  sqltTest
//
//  Created by FUWANG on 2017/8/25.
//  Copyright © 2017年 FUWANG. All rights reserved.
//
// 日志
/*
 2017/8/25 创建项目
 2018/01/08 添加数据库删除功能
 2018/02/09 更新数据库的对数据存储结构，解决已数字参数排序出现乱序的问题
 2018/02/17 解决丢失父类字段问题
 
 
 
 
 
 
 */
#import "NNCacheData.h"
#import "FMDB.h"
#import "MJExtension.h"
#import <objc/runtime.h>


// 数据库中常见的几种类型
#define SQL_TEXT     @"TEXT" //文本
#define SQL_INTEGER  @"INTEGER" //int long integer ...
#define SQL_REAL     @"REAL" //浮点
#define SQL_BLOB     @"BLOB" //data
#define SQL_BOOL     @"BOOL" //data
#define NNDB ((NNCacheData *)[self shareManager]).db

@interface NNCacheData()<NSCopying,NSMutableCopying>
@property (nonatomic , strong) FMDatabase *db;
/**
 说有页面的页面字典 代替静态变量
 */
@property (nonatomic , strong) NSMutableDictionary *allPageDict;
@end

@implementation NNCacheData
static NNCacheData *instance;

- (FMDatabase *)db
{
    if (!_db) {
        [self crateFMDBFile];
    }
    return _db;
}
- (void)crateFMDBFile
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dbPath   = [docsPath stringByAppendingPathComponent:@"NNCacheData.db"];
    _db     = [FMDatabase databaseWithPath:dbPath];
    NSLog(@"%@",dbPath);
}
-(void)deleteFMDBFile
{
    //自己禁止删除数据库
    
//    return;
    
    NSFileManager* fileManager=[NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    //文件名
    NSString *uniquePath=[[paths objectAtIndex:0] stringByAppendingPathComponent:@"NNCacheData.db"];
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:uniquePath];
    if (!blHave) {
        NSLog(@"no  have");
        return ;
    }else {
        NSLog(@" have");
        BOOL blDele= [fileManager removeItemAtPath:uniquePath error:nil];
        if (blDele) {
            NSLog(@"dele success");
            
            [self crateFMDBFile];
        }else {
            NSLog(@"dele fail");
        }
    }
}
/**
 检测软件版本
 */
- (void)isNewDataBaseVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSLog(@"%@",app_Version);
    
    //UserDefalutVersion
    NSString *fmdbVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"NNCacheDataVersionUserDefault"];
    
    //版本不一致删除 和 用户切换了账号
    if (![fmdbVersion isEqualToString:app_Version]) {
        [self deleteFMDBFile];
        [[NSUserDefaults standardUserDefaults] setObject:app_Version forKey:@"NNCacheDataVersionUserDefault"];
    }
}
- (id)copyWithZone:(NSZone *)zone
{
    return instance;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
    return instance;
}
+ (instancetype)shareManager
{
    return [self new];
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [super allocWithZone:zone];
            instance.allPageDict = [NSMutableDictionary dictionary];
            [instance isNewDataBaseVersion];
        }
    });
    return instance;
}
/**
 把对象用字符串的格式保存  
 统一用空字符串来表示缺省值
 */
+ (NSString *)checkContentNotNull:(NSString *)content
{
    //为空，主要是为了占一个位置在内容数组里
    
    //假如为null 防止奔溃
    if ([content isKindOfClass:[NSNull class]]) {
        content = @"";
    }
    
    //在检测的时候 会对数字当做空的处理吗？
    //int 100 都可以进入
    if (content) {
        return content;
    }
    
    if (content == nil) {
        return @"";
    }
    return content;
}
//借用<JQFMDB>大神的 获取数据类型
+ (NSString *)propertTypeConvert:(NSString *)typeStr
{
    NSString *resultStr = nil;
    if ([typeStr hasPrefix:@"T@\"NSString\""]) {
        resultStr = SQL_TEXT;
    } else if ([typeStr hasPrefix:@"T@\"NSData\""]) {
        resultStr = SQL_BLOB;
    } else if ([typeStr hasPrefix:@"Ti"]||[typeStr hasPrefix:@"TI"]||[typeStr hasPrefix:@"Ts"]||[typeStr hasPrefix:@"TS"]||[typeStr hasPrefix:@"T@\"NSNumber\""]||[typeStr hasPrefix:@"TB"]||[typeStr hasPrefix:@"Tq"]||[typeStr hasPrefix:@"TQ"]) {
        resultStr = SQL_INTEGER;
    } else if ([typeStr hasPrefix:@"Tf"] || [typeStr hasPrefix:@"Td"]){
        resultStr= SQL_REAL;
    }else {
        //修改 缺省值 NSData
        resultStr = SQL_BLOB;
    }
    
    return resultStr;
}
+ (NSString *)propertyTypeWithObject:(id )obj {
    NSString *classString = NSStringFromClass([obj class]);
    
    NSString *result = @"";
    if ([classString rangeOfString:@"String"].location != NSNotFound) {
        result = SQL_TEXT;
    }else if ([classString rangeOfString:@"Data"].location != NSNotFound) {
        result = SQL_BLOB;
    }else if ([classString rangeOfString:@"Boolean"].location != NSNotFound) {
        result = SQL_BOOL;
    }else if ([classString rangeOfString:@"Number"].location != NSNotFound) {
        //整数，默认为浮点了
        result = SQL_REAL;
    }else {
        //默认为data数据存储了
        //如果你想更精确的，建议查询数据库类型，你可以创建你想要的类型，他会在操作数据库上非常便利 http://www.w3school.com.cn/sql/sql_datatypes.asp
        NSLog(@"数据不精确,使用NSData代替了");
        result = SQL_BLOB;
    }
    return result;
}
/**
 获取类参数名 和数据类型
 */
+ (void)getClassPropertyArr:(Class)class complete:(void(^)(NSArray *propertyNameArr,NSArray *propertyTypeArr))complete
{
    unsigned int count;
    unsigned int superCount;
    NSMutableArray *propertyNameArrM = [NSMutableArray array];
    NSMutableArray *propertyTypeArrM = [NSMutableArray array];
    
    Class superClass = class_getSuperclass(class);
    objc_property_t *superProperties = class_copyPropertyList(superClass, &superCount);
    
    
    
    //父
    //父类不为NSObject 不要往下深入了
    //深度递归获取
    
    if (![NSStringFromClass(superClass) isEqualToString:@"NSObject"]) {
        for (int i = 0; i < superCount; i++) {
            objc_property_t property = superProperties[i];
            const char * cName = property_getName(property);
            const char * cType = property_getAttributes(property);
            NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
            [propertyNameArrM addObject:name];
            
            NSString *type = [NSString stringWithCString:cType encoding:NSUTF8StringEncoding];
            [propertyTypeArrM addObject:[self propertTypeConvert:type]];
        }
    }
    
    
    //子
    objc_property_t *properties = class_copyPropertyList(class, &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        const char * cName = property_getName(property);
        const char * cType = property_getAttributes(property);
        NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        [propertyNameArrM addObject:name];
        
        NSString *type = [NSString stringWithCString:cType encoding:NSUTF8StringEncoding];
        [propertyTypeArrM addObject:[self propertTypeConvert:type]];
    }
    complete(propertyNameArrM,propertyTypeArrM);
}
+ (void)NNUpdata:(id)data
       tableName:(NSString *)tableName
IDPropertysNameArr:(NSArray *)IDPropertysNameArr
compareChangeRefrshPropertysNameArr:(NSArray *)compareChangeRefrshPropertysNameArr
        complete:(void(^)(BOOL isNew))complete
{
    //等下我要加固我的框架 （：
    @try {
        if ([data isKindOfClass:[NSNull class]]) return;
            
        if (data==nil) return;
        
        if (!tableName.length) return;
        
        if (![NNDB open]) {
            NSLog(@"open sqlt error");
            return;
        }
        //判断取出key 和转成json文件
        __block NSArray *allKeys;
        __block NSArray *types;
        //判断用户是否已经构建了
        //你可以传入dict数据过来，但是你要保证第一次是正常的，
        //对模型进行转化成字典，取出key对应的value
        NSDictionary *dictData;
        if ([data isKindOfClass:[NSDictionary class]]) {
            dictData = data;
            NSLog(@"NNCacheData__你可以传入dict数据过来，但是你要保证第一次你需要的所用字段都是有数据的，不然数据库是不会创建的,很难保证，你可以传入模型，他是安全的，可以使用指定参数名方法创建的方法");
            allKeys = ((NSDictionary *)data).allKeys;
            //那了下呢
            NSDictionary *dict = data;
            NSMutableArray *typesM = [NSMutableArray array];
            NSLog(@"%@",dict);
            [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [typesM addObject:[self propertyTypeWithObject:obj]];
            }];
            types = typesM;
        }else {
            dictData = ((NNCacheData *)data).mj_keyValues;
            //runtime 获取参数名 和 类型
            [self getClassPropertyArr:[data class] complete:^(NSArray *propertyNameArr, NSArray *propertyTypeArr) {
                allKeys = propertyNameArr;
                types   = propertyTypeArr;
            }];
        }
        
        //create
        if (!allKeys.count) return;
        
        //按照字符串的格式保存
        NSMutableString *createPropertyM = [@"" mutableCopy];
        NSMutableString *insertPropertyM = [@"" mutableCopy];
        NSMutableString *insertQuestionM = [@"" mutableCopy];
        
        //sql语句通过数组方式添加
        NSMutableArray *insertContentM  = [@[] mutableCopy];
        
        //看看类型数组是否有数据 没有只能默认为text创建数据库
        for (int i = 0; i < types.count; i++) {
            NSString *key = allKeys[i];
            NSString *type = types[i];
            //帮你过滤
            if (!key.length) {
                continue;
            }
            //你已经把这里写成了text了，写死了 应该是要活的
            //这样如果 获取我以为什么都可以用
            //直接去掉字典，模型来 ，也可以 字典喜欢 ，但是不知道类型
            //必须使用真实值 假的不要
            [createPropertyM appendFormat:@"%@ %@,",key,type];
            [insertPropertyM appendFormat:@"'%@',",key];
            [insertQuestionM appendString:@"?,"];
            
            //mj 会自动过来掉值为空的情况，留下有值的
            id content = dictData[key];
            //这里正是我使用明确的key所要解决的问题，如果我过滤他们，他们将不会创建
            //一般我使用最多的是NSString 和 CGFloat 只有 处理一下就好 默认 @"" 和 0
            //如何获取到他的类型呢
            //到这来 防控处理就有用了
            content = [self checkContentNotNull:content];
            [insertContentM addObject:content];
        }
        
        //删除最后一个字符
        [createPropertyM deleteCharactersInRange:NSMakeRange(createPropertyM.length-1, 1)];
        [insertPropertyM deleteCharactersInRange:NSMakeRange(insertPropertyM.length-1, 1)];
        [insertQuestionM deleteCharactersInRange:NSMakeRange(insertQuestionM.length-1, 1)];
        
        if (![NNDB executeUpdate:[NSString stringWithFormat:@"create table if not exists %@ (%@)",tableName,createPropertyM]]) {
            NSLog(@"crete table error ");
            return ;
        }
        
        //noraml compare
        //检测是否有重复
        NSMutableString *normalCompareNameStringM = [@"" mutableCopy];
        NSMutableArray *normalCompareContentM = [@[] mutableCopy];
        for (NSString *obj in IDPropertysNameArr) {
            [normalCompareNameStringM appendFormat:@"%@ = ? and ",obj];
            
            NSString *content = dictData[obj];
            [normalCompareContentM addObject:content];
        }
        //有时是不会开启检测功能的
        if (normalCompareNameStringM.length > 4) {
            [normalCompareNameStringM deleteCharactersInRange:NSMakeRange(normalCompareNameStringM.length-4, 4)];
        }
        
        
        NSString *checkEqualSql = [NSString stringWithFormat:@"select * from %@ where (%@)",tableName,normalCompareNameStringM];
        FMResultSet *compareRs = [NNDB executeQuery:checkEqualSql withArgumentsInArray:normalCompareContentM];
        
        
        //
        //hige compare
        //主要是用于更新数据库
        //这几个数据都是动态的
        if ([compareRs next]) {
            
            if (compareChangeRefrshPropertysNameArr.count) {
                
                NSMutableString *higeCompareStrM = [@"" mutableCopy];
                NSMutableArray *higeCompleteContentArrM = [@[] mutableCopy];
                
                NSMutableArray *compareChangeRefrshPropertysNameArrTemp = [IDPropertysNameArr mutableCopy];
                [compareChangeRefrshPropertysNameArrTemp addObjectsFromArray:compareChangeRefrshPropertysNameArr];
                for (NSString *obj in compareChangeRefrshPropertysNameArrTemp) {
                    [higeCompareStrM appendFormat:@"%@ = ? and ",obj];
                    
                    NSString *content = dictData[obj];
                    content = [self checkContentNotNull:content];
                    [higeCompleteContentArrM addObject:content];
                }
                if (higeCompareStrM.length > 4) {
                    [higeCompareStrM deleteCharactersInRange:NSMakeRange(higeCompareStrM.length-4, 4)];
                }
                NSString *higeCheckEqualSql = [NSString stringWithFormat:@"select *from %@ where (%@)",tableName,higeCompareStrM];
                
                FMResultSet *higeRs = [NNDB executeQuery:higeCheckEqualSql withArgumentsInArray:higeCompleteContentArrM];
                
                if ([higeRs next]) {
                    if (complete) {
                        complete(NO);
                    }
                    return;
                }else {
                    //数据已更新 需要刷新数据库 会刷新到深度比较的字段
                    NSMutableString *updateStrM = [@"" mutableCopy];
                    NSMutableArray *updateContentArrM = [@[] mutableCopy];
                    //更新库里的说有数据
                    //给出什么 就更新什么，
                    for (NSString *obj in compareChangeRefrshPropertysNameArr) {
                        [updateStrM appendFormat:@"%@ = ?,",obj];
                        
                        NSString *content = dictData[obj];
                        content = [self checkContentNotNull:content];
                        [updateContentArrM addObject:content];
                    }
                    [updateStrM deleteCharactersInRange:NSMakeRange(updateStrM.length-1, 1)];
                    
                    //使用检测的内容来定位到数据
                    NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ where %@",tableName,updateStrM,normalCompareNameStringM];
                    [updateContentArrM addObjectsFromArray:normalCompareContentM];
                    
                    if ([NNDB executeUpdate:updateSql withArgumentsInArray:updateContentArrM]) {
                        //刷新成功
                        if (complete) {
                            complete(YES);
                        }
                        
                    }else {
                        NSAssert(1, @"新数据更新不成功!");
                        if (complete) {
                            complete(-1);
                        }
                        
                    }
                    return;
                }
            }else {
                //不用深度比较
                if (complete) {
                    complete(NO);
                }
                
                return;
            }
        }
        
        //update
        NSString *insertString = [NSString stringWithFormat:@"insert into %@ (%@) values (%@)",tableName,insertPropertyM,insertQuestionM];
        //insert
        //系统会对后面的数据作为 语句 系统匹配多个
        //存储字符串dict
        //改库
        
        if (![NNDB executeUpdate:insertString withArgumentsInArray:insertContentM]) {
            NSLog(@"insert error");
            return;
        }
        if (complete) {
            complete(YES);
        }
        
    } @catch (NSException *exception) {
        NSLog(@"数据库未知异常");
        if (complete) {
            complete(NO);
        }
    } @finally {
    }
}
/**
 设置某表的查询页面
 */
+ (void)setPage:(NSInteger)page withTableName:(NSString *)tableName
{
    [instance.allPageDict setObject:@(page) forKey:tableName];
}
/**
 获取某表的查询页面 多线程的时候会用到 为同时多个表查询做准备
 */
+ (NSInteger)getPageWithTableName:(NSString *)tableName
{
    NSNumber *number = [instance.allPageDict objectForKey:tableName];
    return [number integerValue];
}
+ (void)NNDelectTableName:(NSString *)tableName
       IDPropertysNameArr:(NSArray *)IDPropertysNameArr
               delectData:(id)delectData
                 complete:(void(^)(BOOL isDelect))complete
{
    @try {
        if (0==tableName.length) return;
        //如果缺失 无法指定
        if (0 == IDPropertysNameArr.count) {
            if(complete) {
                complete(NO);
            }
            return;
        }
        if (delectData == nil) {
            if(complete) {
                complete(NO);
            }
            return;
        }
        if (![NNDB open]) {
            NSLog(@"open error");
            if(complete) {
               complete(NO);
            }
            return;
        }
        NSDictionary *dictData;
        if (![delectData isKindOfClass:[NSDictionary class]]) {
            dictData = [((NSString *)delectData) mj_keyValues];
        }else {
            dictData = delectData;
        }
        //需要一个
        //遇到一个坑 ，如果是executeUpdateWithFormat带format的记得在拼接的时候加%@ = ?,这种格式哟
        //你可以选择只是语句
        //还有如果是？创建的数据库 必须用？来增删改 %@ = ? and  直接拼接 value是不对的
        NSMutableString *detemineStingM = [@"" mutableCopy];
        NSMutableArray *delectObjArrM = [NSMutableArray array];
        for (NSString *obj in IDPropertysNameArr) {
            if (obj.length) {
                id value = dictData[obj];
                if (value) {
                    [detemineStingM appendFormat:@"%@ = ? and ",obj];
                    [delectObjArrM addObject:value];
                }
            }
        }
        //删除多余的，
        if (detemineStingM.length) {
            [detemineStingM deleteCharactersInRange:NSMakeRange(detemineStingM.length-4, 4)];
        }
        
        //DELETE FROM Person WHERE LastName = 'Wilson'
        NSString *SQLStr = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@",tableName,detemineStingM];
        if([NNDB executeUpdate:SQLStr withArgumentsInArray:delectObjArrM]){
            complete(YES);
        }else {
            NSLog(@"删除失败");
            complete(NO);
        }
    } @catch (NSException *exception) {
        NSLog(@"数据库解析异常");
    } @finally {
    }
    
    
}
+ (void)NNDelectTableWithTableName:(NSString *)tableName complete:(void(^)())complete
{
    if (0 == tableName.length) return;
    
    if (![NNDB open])
    {
        if (complete) {
            complete();
        }
        NSLog(@"打开数据库错误");
        return;
    }
    
    if ([NNDB executeUpdate:[NSString stringWithFormat:@"Delete from %@",tableName]]) {
        if (complete) {
            complete();
        }
    }else {
        if (complete) {
            complete();
        }
        NSLog(@"删除失败");
    }
    
}
+ (void)NNGetDataTableName:(NSString *)tableName isGetFirstData:(BOOL)isGetFirstData sortSqlString:(NSString *)sortSqlString pickDataClassName:(NSString *)pickDataClassName complete:(void(^)(NSArray *dataArr))complete
{
    @try {
        
        if (![NNDB open]) {
            NSLog(@"open error");
            complete(@[]);
            return;
        }
        
        //default load 20页
        //如果同时对一个数据库进行操作 会导致数据库定位异常
        //需要优化
        NSInteger pageBegain = [self getPageWithTableName:tableName];
        if (isGetFirstData) {
            pageBegain = 0;
        }else {
            pageBegain += 20;
        }
        //如果上一次没走完 你是不是要回退一下呢 用来下拉查询数据加载更多
        //where d_repay_date_origin > '%0.0f' order by sh_status >0 desc ,d_repay_date_origin asc
        //在sql语句注入分页查询接口
        FMResultSet *rss = [NNDB executeQuery:[NSString stringWithFormat:@"select * from %@ %@ limit %ld,%d",tableName,sortSqlString?sortSqlString:@"",(long)pageBegain,20]];
        //先把时间排好
        //自动切换到加载已读数据
        //如果
        
        NSMutableArray *arrM = [NSMutableArray array];
        while ([rss next]) {
            //系统会提供字段名称
            //处理字典
            
            NSDictionary *dict= rss.resultDictionary;
            id obj = (pickDataClassName.length)?[NSClassFromString(pickDataClassName) mj_objectWithKeyValues:dict]:dict;
            if (obj) {
                [arrM addObject:obj];
            }
        }
        //判断是否加载顺利 用于下一次的更新
        NSLog(@"起始页------  %ld",(long)pageBegain);
        if (arrM.count != 20) {
            pageBegain -= (20 - arrM.count);
        }
        [self setPage:pageBegain withTableName:tableName];
        NSLog(@"下个起始页------  %ld",((long)pageBegain+20));
        NSLog(@"读了--------%ld页",(long)arrM.count);
        
        
        NSLog(@"%@",arrM);
        if (complete) {
            complete(arrM);
        }

    } @catch (NSException *exception) {
        NSLog(@"数据库解析异常");
        complete(@[]);
    } @finally {
    }
}
@end
