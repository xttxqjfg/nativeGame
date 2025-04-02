//
//  CandyNode.m
//  RedPacketRainGame
//
//  Created by yibo on 2022/7/14.
//

#import "CandyNode.h"
#import "RedPacketRainGameTool.h"

@implementation CandyNode

+ (instancetype)candyNode {
    NSInteger randomIndex = (arc4random() % 2) + 1;
    CandyNode *candy = [CandyNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"redpacket_rain_candy%@",@(randomIndex)]];
    candy.size = [[RedPacketRainGameTool sharedInstance] getBubbleSize];
//    [candy setScale:5];
    candy.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:candy.size.width/2.f];
    
//------------------------init configs---------------------------------
    candy.physicsBody.affectedByGravity = NO;//不受重力影响
//    candy.physicsBody.mass = 10;//质量 10kg
    candy.physicsBody.angularDamping = 0.f;//角动量摩擦力
    candy.physicsBody.linearDamping = 0.f;//线性摩擦力
    candy.physicsBody.restitution = 0.5f;//反弹的动量 1即无限反弹，不丢失动量，相当于一个永动机=。=
    candy.physicsBody.friction = 0.f;//摩擦力
    candy.physicsBody.allowsRotation = YES;//允许受到角动量
    candy.physicsBody.usesPreciseCollisionDetection = YES;//独立计算碰撞
    //设置物理体的标识符
    candy.physicsBody.collisionBitMask = 0x01;
    //设置可与哪一类标识符的物理体发生碰撞
    candy.physicsBody.contactTestBitMask = 0x02;
    
    return candy;
}

@end
