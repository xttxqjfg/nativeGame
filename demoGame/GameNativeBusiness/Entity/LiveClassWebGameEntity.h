//
//  LiveClassWebGameEntity.h
//  LivePlayer
//
//  Created by yibo on 2022/5/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveClassWebGameDataEntity : NSObject

/// 互动id
@property (nonatomic,copy) NSString *interactId;

/// 游戏名称
@property (nonatomic,copy) NSString *name;

/// 互动阶段{start\play\end}
@property (nonatomic,copy) NSString *action;

/// 互动开关状态
@property (nonatomic,assign) BOOL pub;

/// 游戏时长，秒
@property (nonatomic,assign) NSInteger redbagDuration;

/// 红包数组
@property (nonatomic,strong) NSArray *redbagQueue;

/// 炸弹数组
@property (nonatomic,strong) NSArray *bombQueue;

/// 透传参数,客户端不用关注内容 parameter = "level=5&xx=a";
@property (nonatomic,copy) NSString *parameter;

@end

@interface LiveClassWebGameEntity : NSObject

/// 指令类型
@property (nonatomic,copy) NSString *ircType;

/// 指令内容
@property (nonatomic,strong) LiveClassWebGameDataEntity *data;

/// 发送时间戳
@property (nonatomic,assign) NSTimeInterval sendTime;


@end

NS_ASSUME_NONNULL_END
