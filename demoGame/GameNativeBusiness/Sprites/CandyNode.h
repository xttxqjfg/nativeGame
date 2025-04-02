//
//  CandyNode.h
//  RedPacketRainGame
//
//  Created by yibo on 2022/7/14.
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CandyNode : SKSpriteNode

/// tag值，业务用
@property (nonatomic,assign) NSInteger nodeTag;

+ (instancetype)candyNode;

@end

NS_ASSUME_NONNULL_END
