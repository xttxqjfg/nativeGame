//
//  BombNode.h
//  RedPacketRainGame
//
//  Created by yibo on 2022/7/14.
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BombNode : SKSpriteNode

/// tag值，业务用
@property (nonatomic,assign) NSInteger nodeTag;

+ (instancetype)bombNode;

@end

NS_ASSUME_NONNULL_END
