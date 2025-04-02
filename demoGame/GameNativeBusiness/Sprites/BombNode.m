//
//  BombNode.m
//  RedPacketRainGame
//
//  Created by yibo on 2022/7/14.
//

#import "BombNode.h"
#import "RedPacketRainGameTool.h"

@implementation BombNode

+ (instancetype)bombNode {
    BombNode *bomb = [BombNode spriteNodeWithImageNamed:@"redpacket_rain_bomb"];
//    [bomb setScale:5];
    bomb.size = [[RedPacketRainGameTool sharedInstance] getBubbleSize];
    bomb.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:bomb.size.width/2.f];
    
//------------------------init configs---------------------------------
    bomb.physicsBody.affectedByGravity = NO;//不受重力影响
//    bomb.physicsBody.mass = 10;//质量 10kg
    bomb.physicsBody.angularDamping = 0.f;//角动量摩擦力
    bomb.physicsBody.linearDamping = 0.f;//线性摩擦力
    bomb.physicsBody.restitution = 0.5f;//反弹的动量 1即无限反弹，不丢失动量，相当于一个永动机=。=
    bomb.physicsBody.friction = 0.f;//摩擦力
    bomb.physicsBody.allowsRotation = YES;//允许受到角动量
    bomb.physicsBody.usesPreciseCollisionDetection = YES;//独立计算碰撞
    
    bomb.physicsBody.collisionBitMask = 0x02;
    bomb.physicsBody.contactTestBitMask = 0x01;
    
    return bomb;
}

@end
