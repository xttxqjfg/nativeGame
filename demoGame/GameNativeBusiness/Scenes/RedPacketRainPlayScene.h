//
//  RedPacketRainPlayScene.h
//  RedPacketRainGame
//
//  Created by yibo on 2022/7/13.
//

#import <SpriteKit/SpriteKit.h>
#import "LiveClassWebGameEntity.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RedPacketRainPlaySceneEventType) {
    RedPacketRainPlaySceneEventTypeStart            = 1000,
    RedPacketRainPlaySceneEventTypeEnd              = 2000,
    RedPacketRainPlaySceneEventTypeUnknow           = 3000
};

@protocol RedPacketRainPlaySceneDelegate <NSObject>

/// 代理回调事件
/// @param eventType 事件类型
/// @param userinfo 用户信息
- (void)eventOnRedPacketRainPlaySceneWithType:(RedPacketRainPlaySceneEventType)eventType userinfo:(NSDictionary *)userinfo;

@end


///
@interface RedPacketRainPlayScene : SKScene

/// 代理
@property (nonatomic,weak) id<RedPacketRainPlaySceneDelegate> eventDelegate;


/// 开始游戏
/// - Parameter dataConfig: 游戏配置
- (void)startPlayGameWithConfig:(LiveClassWebGameDataEntity *)dataConfig;

/// 处理app进前后台的状态变化
/// - Parameter isEnterBack: yes进后台  no回前台
- (void)handleAppStatusChanged:(BOOL)isEnterBack;

/// 结束当前游戏
/// - Parameter isForce: 是否强制结束
- (void)endGameWithFore:(BOOL)isForce;

/// 销毁所有节点
- (void)destorySubNodes;

@end

NS_ASSUME_NONNULL_END
