//
//  RedPacketRainGameTool.h
//  AFNetworking
//
//  Created by yibo on 2022/10/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RedPacketRainGameTool : NSObject

/// 单例
+ (instancetype)sharedInstance;

/// 用当前游戏视图大小重新计算
/// - Parameter size: 视图大小
- (void)updateConfigWithSize:(CGSize)size;

/// 获取游戏里控件的缩放比例
- (CGFloat)getGameSizeRatio;

/// 根据机型适配后获取泡泡大小
- (CGSize)getBubbleSize;

/// 解析游戏额外的配置参数，比如游戏难度等
/// - Parameter configStr: 配置字符串
+ (NSDictionary *)parseGameExtConfigWithStr:(NSString *)configStr;

/// 将难度等级转换成难度系数
/// - Parameter level: 难度等级 1~5
+ (CGFloat)getGameDifficultyDegreeWithLevel:(NSInteger)level;

@end

NS_ASSUME_NONNULL_END
