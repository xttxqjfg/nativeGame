//
//  RedPacketRainPlayScene.m
//  RedPacketRainGame
//
//  Created by yibo on 2022/7/13.
//

#import "RedPacketRainPlayScene.h"
#import "CandyNode.h"
#import "BombNode.h"
#import "TrailShapeNode.h"
#import "RedPacketRainGameTool.h"

@interface RedPacketRainPlayScene()<SKPhysicsContactDelegate>

/// 背景
@property (nonatomic,strong) SKSpriteNode *gameBgNode;

/// 金币背景
@property (nonatomic,strong) SKSpriteNode *coinsBgNode;

/// 金币值标签
@property (nonatomic,strong) SKLabelNode *coinsTitleNode;

/// 倒计时背景
@property (nonatomic,strong) SKSpriteNode *timeBgNode;

/// 倒计时值标签
@property (nonatomic,strong) SKLabelNode *timeTitleNode;

/// 倒计时值
@property (nonatomic,assign) NSInteger countdownValue;

/// 开始游戏倒计时
@property (nonatomic,strong) SKSpriteNode *readyGoNode;

///// 划痕刀刃粒子效果
@property (nonatomic,strong) SKEmitterNode *cuttingEmitter;

/// 糖果炸弹数据源
@property (nonatomic,strong) NSMutableArray *dataSourcesArr;

/// 当前正在添加的结点索引
@property (nonatomic,assign) NSInteger currentNodeIndex;

@property (nonatomic,strong) NSArray *candyTextures;

@property (nonatomic,strong) NSArray *bombTextures;

/// 糖果或者炸弹出现时的向量数组
@property (nonatomic,strong) NSArray *vectors;

/// 金币总数
@property (nonatomic,assign) NSInteger coinsSum;

/// 划痕数据点
@property (nonatomic,strong) NSMutableArray *shapePointArr;

/// 划到的糖果积分列表
@property (nonatomic,strong) NSMutableArray *candyPointArr;

/// 划到的炸弹积分列表
@property (nonatomic,strong) NSMutableArray *bombPointArr;

/// 最终难度系数，根据传值的level计算
@property (nonatomic,assign) CGFloat gameDifficultyDegree;

/// 主要用来计算进入后台到返回前台中间的时间间隔
@property (nonatomic,assign) NSTimeInterval enterBackTime;

@end

///
@implementation RedPacketRainPlayScene

- (id)initWithSize:(CGSize)size{
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor clearColor];
        self.coinsSum = 0;
        self.countdownValue = 10;
        [self candyTextures];
        [self bombTextures];
        
        [self setupGamePrepareContent];
        
        [self addChild:self.gameBgNode];
    }
    return self;
}

/// 开始游戏
/// - Parameter dataConfig: 游戏配置
- (void)startPlayGameWithConfig:(LiveClassWebGameDataEntity *)dataConfig {
    if(dataConfig.redbagDuration > 0) {
        self.countdownValue = dataConfig.redbagDuration;
    }
    
    //保存当前游戏难度等级
    NSDictionary *extConfig = [RedPacketRainGameTool parseGameExtConfigWithStr:dataConfig.parameter];
    self.gameDifficultyDegree = [RedPacketRainGameTool getGameDifficultyDegreeWithLevel:[extConfig objectForKey:@"level"]];//默认难度等级为3
    NSLog(@"【原生红包雨】当前游戏难度系数：%@",@(self.gameDifficultyDegree));
    
    [self createNodeDataSourcesWithConfig:dataConfig];
    
    [self addChild:self.coinsBgNode];
    [self addChild:self.timeBgNode];
    [self addChild:self.coinsTitleNode];
    [self addChild:self.timeTitleNode];
    [self playReadyGoAnimation];
}

/// 处理app进前后台的状态变化
/// - Parameter isEnterBack: yes进后台  no回前台
- (void)handleAppStatusChanged:(BOOL)isEnterBack {
    if(isEnterBack) {
        //进后台，记录当前时间戳
        self.enterBackTime = [[NSDate date] timeIntervalSince1970] * 1000;
    }
    else {
        NSInteger timeGap = floor(([[NSDate date] timeIntervalSince1970] * 1000 - self.enterBackTime) / 1000.0);
        NSLog(@"【原生红包雨】当前游戏进入后台的时间间隔：%@",@(timeGap));
        self.enterBackTime = [[NSDate date] timeIntervalSince1970] * 1000;
        if(self.countdownValue > timeGap) {
            self.countdownValue = self.countdownValue - timeGap;
            NSLog(@"【原生红包雨】回到前台后重新调整倒计时");
        }
        else {
            //游戏时间到，主动结束游戏
            NSLog(@"【原生红包雨】回到前台后倒计时已到，主动结束游戏");
            [self endGameWithFore:YES];
        }
    }
}

/// 结束当前游戏
/// - Parameter isForce: 是否强制结束
- (void)endGameWithFore:(BOOL)isForce {
    NSLog(@"【原生红包雨】游戏结束，是否是强制结束：%@",@(isForce));
    
    self.paused = YES;
    
    if(isForce) {
        //移除所有发泡泡逻辑
        [self removeActionForKey:@"sprite-create"];
    }
    
    //移除所有还在的精灵
    for (SKNode *node in self.children) {
        if ([node isKindOfClass:[CandyNode class]] || [node isKindOfClass:[BombNode class]] || [node isKindOfClass:[TrailShapeNode class]]) {
            [node removeFromParent];
        }
    }
    
    if([self.eventDelegate respondsToSelector:@selector(eventOnRedPacketRainPlaySceneWithType:userinfo:)]) {
        NSMutableDictionary *resultParams = [[NSMutableDictionary alloc]init];
        [resultParams setObject:@(self.coinsSum) forKey:@"coin"];
        [resultParams setObject:[self.candyPointArr copy] forKey:@"grabRedbagQueue"];
        [resultParams setObject:[self.bombPointArr copy] forKey:@"grabBombQueue"];
        
        [self.eventDelegate eventOnRedPacketRainPlaySceneWithType:(RedPacketRainPlaySceneEventTypeEnd) userinfo:[resultParams copy]];
        
        //清空记录
        [self.candyPointArr removeAllObjects];
        [self.bombPointArr removeAllObjects];
    }
}

- (void)setupGamePrepareContent {
    
//    //设置世界的碰撞代理
//    self.physicsWorld.contactDelegate = self;
    //设置这个世界的边界，任何刚体都无法通过力的作用逃离这个世界的边界
    
    //边界设置上下留白一个泡泡的高度，便于自然入和自然出效果
    CGFloat bubbleHeight = [[RedPacketRainGameTool sharedInstance] getBubbleSize].height;
    CGRect edgeRect = CGRectMake(0, -bubbleHeight, self.size.width, self.size.height + 2 * bubbleHeight);
    NSLog(@"【原生红包雨】当前游戏物理世界边界大小：%@",@(edgeRect));
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:edgeRect];
}

#pragma mark - PhysicsContact
- (void)didBeginContact:(SKPhysicsContact *)contact {
    
}

- (void)didEndContact:(SKPhysicsContact *)contact {
    
}

//检测精灵是否达到顶部或者底部边缘，达到则直接移除
- (void)update:(NSTimeInterval)currentTime {
    for (SKSpriteNode *itemNode in self.dataSourcesArr) {
        if (CGRectIntersectsRect(itemNode.frame, CGRectMake(50, self.size.height - 20, self.size.width - 100, 30))) {
            [itemNode runAction:[SKAction sequence:@[[SKAction fadeOutWithDuration:0.2],
                                                     [SKAction removeFromParent]]]];
        }
    }
}

#pragma mark touch delegate
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //开始划糖果
    //划痕移动
    for (UITouch *touch in touches) {
        CGPoint startLocation = [touch locationInNode:self];
        [self touchMovedWithPoint:startLocation];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    //划痕移动
    for (UITouch *touch in touches) {
        CGPoint startLocation = [touch locationInNode:self];
        CGPoint endLocation = [touch previousLocationInNode:self];
        
        //记录当前滑动位置
        NSLog(@"记录当前划痕位置：%@",@(startLocation));
        [self touchMovedWithPoint:startLocation];
        
        [self.physicsWorld enumerateBodiesAlongRayStart:startLocation end:endLocation usingBlock:^(SKPhysicsBody * _Nonnull body, CGPoint point, CGVector normal, BOOL * _Nonnull stop) {
            [self checkCuttingObject:body];
        }];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //划动结束
    [self.shapePointArr removeAllObjects];
//    [self.cuttingEmitter removeFromParent];
//    self.cuttingEmitter = nil;
}

- (void)touchMovedWithPoint:(CGPoint)point {
    if (self.shapePointArr.count > 6) {
        [self createLineShapeWithPointArr:[self.shapePointArr copy]];
        [self.shapePointArr removeObjectsInRange:NSMakeRange(0, 4)];
    }
    else {
        [self.shapePointArr addObject:@{@"x":@(point.x),@"y":@(point.y)}];
    }
}

- (void)createLineShapeWithPointArr:(NSArray *)pointArr {
    CGMutablePathRef linePath = CGPathCreateMutable();
    NSDictionary *first = [pointArr firstObject];
    CGPathMoveToPoint(linePath, NULL, [[first objectForKey:@"x"] integerValue], [[first objectForKey:@"y"] integerValue]);
    for (NSDictionary *point in pointArr) {
        CGPathAddLineToPoint(linePath, NULL, [[point objectForKey:@"x"] integerValue], [[point objectForKey:@"y"] integerValue]);
    }
    
    TrailShapeNode *lineNode = [TrailShapeNode shapeNodeWithPath:linePath];
    lineNode.strokeColor = [UIColor whiteColor];
    lineNode.glowWidth = 10;
    lineNode.lineCap = kCGLineCapRound;
    [self addChild:lineNode];
    
    [lineNode runAction:[SKAction sequence:@[[SKAction fadeOutWithDuration:0.5],
                                             [SKAction removeFromParent]]]];
    CGPathRelease(linePath);
    linePath = nil;
}

- (void)checkCuttingObject:(SKPhysicsBody *)body {
    if (body.node) {
        if ([body.node isKindOfClass:[CandyNode class]]) {
            CandyNode *candy = (CandyNode *)body.node;
            [self getCandyWithPoint:candy.nodeTag positon:candy.position];
        }
        if ([body.node isKindOfClass:[BombNode class]]) {
            BombNode *bomb = (BombNode *)body.node;
            [self getBombWithPoint:bomb.nodeTag positon:bomb.position];
        }
        [body.node removeFromParent];
    }
}

/// 划到了糖果
/// @param point 糖果对应的积分
/// @param position 位置信息
- (void)getCandyWithPoint:(NSInteger)point positon:(CGPoint)position {
    NSLog(@"【原生红包雨】当前划到的是糖果,对应积分是：%@",@(point));
    SKSpriteNode *candyResultNode = [SKSpriteNode spriteNodeWithImageNamed:@"candy-effect-12"];
    candyResultNode.position = position;
    candyResultNode.size = [[RedPacketRainGameTool sharedInstance] getBubbleSize];
    SKAction *candyAtlasAnimation = [SKAction animateWithTextures:self.candyTextures timePerFrame:0.05];
    SKAction *candyMusic = [SKAction playSoundFileNamed:@"coin.mp3" waitForCompletion:NO];
    [candyResultNode runAction:[SKAction sequence:@[candyMusic,candyAtlasAnimation,[SKAction removeFromParent]]]];
    [self addChild:candyResultNode];
    
    [self showPointWithPosition:position point:point withType:1000];
    [self.candyPointArr addObject:@(point)];
    
    self.coinsSum = self.coinsSum + point;
    self.coinsTitleNode.text = [NSString stringWithFormat:@"%@",@(self.coinsSum)];
}

/// 划到了炸弹
/// @param position 位置信息
- (void)getBombWithPoint:(NSInteger)point positon:(CGPoint)position {
    NSLog(@"【原生红包雨】当前划到的是炸弹,对应积分是：%@",@(point));
    SKSpriteNode *bombResultNode = [SKSpriteNode spriteNodeWithImageNamed:@"bomb-effect-14"];
    bombResultNode.position = position;
    bombResultNode.size = [[RedPacketRainGameTool sharedInstance] getBubbleSize];
    SKAction *bombAtlasAnimation = [SKAction animateWithTextures:self.bombTextures timePerFrame:0.05];
    SKAction *bombMusic = [SKAction playSoundFileNamed:@"bomb.mp3" waitForCompletion:NO];
    [bombResultNode runAction:[SKAction sequence:@[bombMusic,bombAtlasAnimation,[SKAction removeFromParent]]]];
    [self addChild:bombResultNode];
    
    [self showPointWithPosition:position point:point withType:2000];
    [self.bombPointArr addObject:@(point)];
    
    self.coinsSum = self.coinsSum - point;
    self.coinsTitleNode.text = [NSString stringWithFormat:@"%@",@(self.coinsSum)];
}

/// 展示所得金币动画
/// @param position 金币提示位置
/// @param point 得分
/// @param type 类型，1000为红包，2000为炸弹
- (void)showPointWithPosition:(CGPoint)position point:(NSInteger)point withType:(NSInteger)type {
    SKSpriteNode *symbolNode; // 符号精灵节点
    SKSpriteNode *pointNode;  // 得分精灵节点
    CGFloat viewRatio = [[RedPacketRainGameTool sharedInstance] getBubbleSize].width / 90.0; //泡泡视图比例
    switch (type) {
        case 1000:
        {
            symbolNode = [SKSpriteNode spriteNodeWithImageNamed:@"plus-point"];
            symbolNode.size = CGSizeMake(22.5 * viewRatio, 23.5 * viewRatio);
            symbolNode.position = CGPointMake(position.x - 10 * viewRatio, position.y);
            
            pointNode = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"plus-point-%@",@(point)]];
            pointNode.size = CGSizeMake(22.5 * viewRatio, 29.5 * viewRatio);
            pointNode.position = CGPointMake(position.x + 10 * viewRatio, position.y);
            break;
        }
        case 2000:
        {
            symbolNode = [SKSpriteNode spriteNodeWithImageNamed:@"subtract-point"];
            symbolNode.size = CGSizeMake(15 * viewRatio, 9.5 * viewRatio);
            symbolNode.position = CGPointMake(position.x - 10 * viewRatio, position.y);;
            
            pointNode = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"subtract-point-%@",@(point)]];
            pointNode.size = CGSizeMake(22.5 * viewRatio, 29.5 * viewRatio);
            pointNode.position = CGPointMake(position.x + 10 * viewRatio, position.y);;
            break;
        }
        default:
            break;
    }
    
    //先缩放到0.01，最后放大到1.0，模拟延时0.3秒出现
    [symbolNode setScale:0.01];
    [pointNode setScale:0.01];
    
    [symbolNode runAction:[SKAction sequence:@[[SKAction waitForDuration:0.25],[SKAction scaleTo:1.0 duration:0.05],[SKAction fadeOutWithDuration:0.2],
                                             [SKAction removeFromParent]]]];
    [pointNode runAction:[SKAction sequence:@[[SKAction waitForDuration:0.25],[SKAction scaleTo:1.0 duration:0.05],[SKAction fadeOutWithDuration:0.2],
                                             [SKAction removeFromParent]]]];
    
    [self addChild:symbolNode];
    [self addChild:pointNode];
}

/// 创建糖果和炸弹
- (void)setupCandyAndBomb {
    [self.readyGoNode runAction:[SKAction sequence:@[
                                                [SKAction fadeOutWithDuration:0.5],
                                                [SKAction removeFromParent],
                                                ]]];
    self.readyGoNode = nil;
    
    self.currentNodeIndex = 0;
    SKAction *actionAdd = [SKAction runBlock:^{
        [self addNodeToScene];
    }];
    SKAction *actionWait = [SKAction waitForDuration:0.25];
    [self runAction:[SKAction repeatAction:[SKAction sequence:@[actionAdd,actionWait]] count:self.dataSourcesArr.count] withKey:@"sprite-create"];
    
    //开始10秒倒计时
    SKAction *actionCountdown = [SKAction runBlock:^{
        [self updateCountdownTime];
    }];
    SKAction *actionWaitTime = [SKAction waitForDuration:1.0];
    [self runAction:[SKAction repeatAction:[SKAction sequence:@[actionCountdown,actionWaitTime]] count:11] withKey:@"game-countdown"];
}

- (void)updateCountdownTime {
    NSLog(@"【原生红包雨】当前游戏剩余时间：%@",@(self.countdownValue));
    self.timeTitleNode.text = [NSString stringWithFormat:@"%@s",@(self.countdownValue)];
    if (0 == self.countdownValue) {
        NSLog(@"【原生红包雨】游戏时间结束");
        [self endGameWithFore:NO];
        return;
    }
    
    if (self.countdownValue <= 3) {
        [self playCountdownTimeAnimation];
    }
    
    self.countdownValue--;
}

- (void)playCountdownTimeAnimation {
    //开始播放倒计时音效
    SKAction *time_scale_1 = [SKAction scaleTo:1.2 duration:0.12];
    SKAction *time_scale_2 = [SKAction scaleTo:1.0 duration:0.08];
    SKAction *time_scale = [SKAction sequence:@[time_scale_1,time_scale_2]];
    
    SKAction *sound = [SKAction playSoundFileNamed:@"countdown.mp3" waitForCompletion:NO];
    SKAction *group = [SKAction group:@[time_scale,sound]];
    [self.timeTitleNode runAction:group];
}

- (void)addNodeToScene {
    SKSpriteNode *node = [self.dataSourcesArr objectAtIndex:self.currentNodeIndex];
    self.currentNodeIndex++;
    
    //如果待出的精灵是炸弹，需要检查当前积分是不是大于炸弹分，小于的话就不出炸弹
    if([node isKindOfClass:[BombNode class]]) {
        BombNode *bombNode = (BombNode *)node;
        if(self.coinsSum < bombNode.nodeTag) {
            NSLog(@"【原生红包雨】当前所得积分总数小于将要出的炸弹积分，抛弃此炸弹");
            return;
        }
    }

    CGSize winSize = self.size;
    int minX = node.size.width / 2;
    int maxX = winSize.width - node.size.width / 2.0;
    int rangeX = maxX - minX;
    int actualX = (arc4random() % rangeX) + minX;
    
    //让泡泡从底部自然出，y位置向下偏移到边界底部
    node.position = CGPointMake(actualX, -[[RedPacketRainGameTool sharedInstance] getBubbleSize].height);
    
    CGVector velocity = [self.vectors[self.currentNodeIndex % self.vectors.count] CGVectorValue];
    velocity.dx = velocity.dx * self.gameDifficultyDegree;
    velocity.dy = velocity.dy * self.gameDifficultyDegree;
    
    node.physicsBody.velocity = velocity;
    NSLog(@"【原生红包雨】当前泡泡加速度值为：x:%@,y:%@",@(velocity.dx),@(velocity.dy));
    [self addChild:node];
}

- (void)playReadyGoAnimation {
    //倒计时背景蒙层
    SKSpriteNode *bgNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7] size:self.size];
    bgNode.position = CGPointMake(self.size.width/2.f, self.size.height/2.f);
    [self addChild:bgNode];
    
    self.readyGoNode = [SKSpriteNode spriteNodeWithImageNamed:@"redpacket_time_3"];
    self.readyGoNode.position = CGPointMake(self.size.width/2.f, self.size.height/2.f);
    CGFloat factor = 1.0;//视图大小系数
    [self.readyGoNode setScale:2.0 * factor];
    [self addChild:self.readyGoNode];
    
    //图片缩放
    SKAction *time_3_1 = [SKAction scaleTo:0.8 * factor duration:0.24];
    SKAction *time_3_2 = [SKAction scaleTo:1.1 * factor duration:0.12];
    SKAction *time_3_3 = [SKAction scaleTo:1.0 * factor duration:0.08];//0.45秒
    SKAction *time_3_4 = [SKAction scaleTo:1.0 * factor duration:0.55];
    SKAction *time_3 = [SKAction sequence:@[time_3_1,time_3_2,time_3_3,time_3_4]];
    
    SKAction *time_2_replace = [SKAction setTexture:[SKTexture textureWithImageNamed:@"redpacket_time_2"] resize:YES];
    SKAction *time_2_0 = [SKAction scaleTo:2.0 * factor duration:0.01];
    SKAction *time_2_1 = [SKAction scaleTo:0.8 * factor duration:0.24];
    SKAction *time_2_2 = [SKAction scaleTo:1.1 * factor duration:0.12];
    SKAction *time_2_3 = [SKAction scaleTo:1.0 * factor duration:0.08];//0.45秒
    SKAction *time_2_4 = [SKAction scaleTo:1.0 * factor duration:0.55];
    SKAction *time_2 = [SKAction sequence:@[time_2_replace,time_2_0,time_2_1,time_2_2,time_2_3,time_2_4]];
    
    SKAction *time_1_replace = [SKAction setTexture:[SKTexture textureWithImageNamed:@"redpacket_time_1"] resize:YES];
    SKAction *time_1_0 = [SKAction scaleTo:2.0 * factor duration:0.01];
    SKAction *time_1_1 = [SKAction scaleTo:0.8 * factor duration:0.24];
    SKAction *time_1_2 = [SKAction scaleTo:1.1 * factor duration:0.12];
    SKAction *time_1_3 = [SKAction scaleTo:1.0 * factor duration:0.08];//0.45秒
    SKAction *time_1_4 = [SKAction scaleTo:1.0 * factor duration:0.55];
    SKAction *time_1 = [SKAction sequence:@[time_1_replace,time_1_0,time_1_1,time_1_2,time_1_3,time_1_4]];
    
    SKAction *time_go_replace = [SKAction setTexture:[SKTexture textureWithImageNamed:@"redpacket_time_go"] resize:YES];
    SKAction *time_go_0 = [SKAction scaleTo:2.0 * factor duration:0.01];
    SKAction *time_go_1 = [SKAction scaleTo:0.8 * factor duration:0.24];
    SKAction *time_go_2 = [SKAction scaleTo:1.1 * factor duration:0.12];
    SKAction *time_go_3 = [SKAction scaleTo:1.0 * factor duration:0.08];//0.45秒
    SKAction *time_go_4 = [SKAction scaleTo:1.0 * factor duration:0.55];
    SKAction *time_go = [SKAction sequence:@[time_go_replace,time_go_0,time_go_1,time_go_2,time_go_3,time_go_4]];
    
    SKAction *sound = [SKAction playSoundFileNamed:@"321go.mp3" waitForCompletion:NO];
    SKAction *group = [SKAction group:@[[SKAction sequence:@[time_3,time_2,time_1,time_go]],sound]];
    
    [self.readyGoNode runAction:group completion:^{
        [bgNode removeFromParent];
        //播放完成动画，开始出泡泡
        [self setupCandyAndBomb];
    }];
}

- (void)createNodeDataSourcesWithConfig:(LiveClassWebGameDataEntity *)config {
    [self.dataSourcesArr removeAllObjects];
    
    for (NSString *point in config.redbagQueue) {
        CandyNode *candy = [CandyNode candyNode];
        candy.nodeTag = [point integerValue];
        [self.dataSourcesArr addObject:candy];
    }
    
    for (NSString *point in config.bombQueue) {
        BombNode *bomb = [BombNode bombNode];
        bomb.nodeTag = [point integerValue];
        [self.dataSourcesArr addObject:bomb];
    }
    
    //乱序
    for (int i = 0; i < self.dataSourcesArr.count; i++) {
        int n = (arc4random() % (self.dataSourcesArr.count - i)) + i;
        [self.dataSourcesArr exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}

/// 销毁所有节点
- (void)destorySubNodes {
    [self.gameBgNode removeFromParent];
    
    [self.coinsBgNode removeFromParent];
    
    [self.timeBgNode removeAllActions];
    [self.timeBgNode removeFromParent];
    
    [self.coinsTitleNode removeFromParent];
    [self.timeTitleNode removeFromParent];
    
    [self.dataSourcesArr removeAllObjects];
    self.candyTextures = nil;
    self.bombTextures = nil;
}

- (void)dealloc {
    NSLog(@"【原生红包雨】RedPacketRainPlayScene dealloc");
}

#pragma mark -- get --
- (SKSpriteNode *)gameBgNode {
    if (!_gameBgNode) {
        _gameBgNode = [SKSpriteNode spriteNodeWithImageNamed:@"redpacket_rain_play_bg"];
        _gameBgNode.name = @"gameBgNode";
        _gameBgNode.size = CGSizeMake(self.size.width, self.size.height);
        _gameBgNode.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
    }
    return _gameBgNode;
}

- (SKSpriteNode *)coinsBgNode {
    if (!_coinsBgNode) {
        _coinsBgNode = [SKSpriteNode spriteNodeWithImageNamed:@"redpacket_rain_coins_bg"];
        _coinsBgNode.name = @"coinsBgNode";
        _coinsBgNode.size = CGSizeMake(122, 62);
        _coinsBgNode.position = CGPointMake(CGRectGetMinX(self.frame) + 61,CGRectGetMaxY(self.frame) - 31);//设置精灵的position
    }
    return _coinsBgNode;
}

- (SKSpriteNode *)timeBgNode {
    if (!_timeBgNode) {
        _timeBgNode = [SKSpriteNode spriteNodeWithImageNamed:@"redpacket_rain_time_bg"];
        _timeBgNode.name = @"timeBgNode";
        _timeBgNode.size = CGSizeMake(78, 36);
        _timeBgNode.position = CGPointMake(CGRectGetMaxX(self.frame) - 39 - 12,CGRectGetMaxY(self.frame) - 15 - 18);//设置精灵的position
    }
    return _timeBgNode;
}

- (SKLabelNode *)coinsTitleNode {
    if (!_coinsTitleNode) {
        _coinsTitleNode = [[SKLabelNode alloc] init];
        _coinsTitleNode.name = @"coinsTitleNode";
        CGPoint position = self.coinsBgNode.position;
        position.x = position.x + 17;
        _coinsTitleNode.position = position;
        _coinsTitleNode.fontColor = [UIColor whiteColor];
        _coinsTitleNode.fontSize = 20;
        _coinsTitleNode.text = @"0";
        _coinsTitleNode.fontName = @"SFProRounded-Bold";
        _coinsTitleNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    }
    return _coinsTitleNode;
}

- (SKLabelNode *)timeTitleNode {
    if (!_timeTitleNode) {
        _timeTitleNode = [[SKLabelNode alloc] init];
        _timeTitleNode.name = @"timeTitleNode";
        _timeTitleNode.position = self.timeBgNode.position;
        _timeTitleNode.fontColor = [UIColor whiteColor];
        _timeTitleNode.fontSize = 20;
        _timeTitleNode.text = @"10s";
        _timeTitleNode.fontName = @"SFProRounded-Bold";
        _timeTitleNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    }
    return _timeTitleNode;
}

- (NSMutableArray *)dataSourcesArr {
    if (!_dataSourcesArr) {
        _dataSourcesArr = [[NSMutableArray alloc]init];
    }
    return _dataSourcesArr;
}

- (NSArray *)candyTextures {
    if (!_candyTextures) {
        SKTextureAtlas *candyAtlas = [SKTextureAtlas atlasNamed:@"candy-effect"];
        SKTexture *f1 = [candyAtlas textureNamed:@"candy-effect-1.png"];
        SKTexture *f2 = [candyAtlas textureNamed:@"candy-effect-2.png"];
        SKTexture *f3 = [candyAtlas textureNamed:@"candy-effect-3.png"];
        SKTexture *f4 = [candyAtlas textureNamed:@"candy-effect-4.png"];
        SKTexture *f5 = [candyAtlas textureNamed:@"candy-effect-5.png"];
        SKTexture *f6 = [candyAtlas textureNamed:@"candy-effect-6.png"];
        SKTexture *f7 = [candyAtlas textureNamed:@"candy-effect-7.png"];
        SKTexture *f8 = [candyAtlas textureNamed:@"candy-effect-8.png"];
        SKTexture *f9 = [candyAtlas textureNamed:@"candy-effect-9.png"];
        SKTexture *f10 = [candyAtlas textureNamed:@"candy-effect-10.png"];
        SKTexture *f11 = [candyAtlas textureNamed:@"candy-effect-11.png"];
        SKTexture *f12 = [candyAtlas textureNamed:@"candy-effect-12.png"];
        _candyTextures = @[f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12];
    }
    return _candyTextures;
}

- (NSArray *)bombTextures {
    if (!_bombTextures) {
        SKTextureAtlas *bombAtlas = [SKTextureAtlas atlasNamed:@"bomb-effect"];
        SKTexture *f1 = [bombAtlas textureNamed:@"bomb-effect-1.png"];
        SKTexture *f2 = [bombAtlas textureNamed:@"bomb-effect-2.png"];
        SKTexture *f3 = [bombAtlas textureNamed:@"bomb-effect-3.png"];
        SKTexture *f4 = [bombAtlas textureNamed:@"bomb-effect-4.png"];
        SKTexture *f5 = [bombAtlas textureNamed:@"bomb-effect-5.png"];
        SKTexture *f6 = [bombAtlas textureNamed:@"bomb-effect-6.png"];
        SKTexture *f7 = [bombAtlas textureNamed:@"bomb-effect-7.png"];
        SKTexture *f8 = [bombAtlas textureNamed:@"bomb-effect-8.png"];
        SKTexture *f9 = [bombAtlas textureNamed:@"bomb-effect-9.png"];
        SKTexture *f10 = [bombAtlas textureNamed:@"bomb-effect-10.png"];
        SKTexture *f11 = [bombAtlas textureNamed:@"bomb-effect-11.png"];
        SKTexture *f12 = [bombAtlas textureNamed:@"bomb-effect-12.png"];
        SKTexture *f13 = [bombAtlas textureNamed:@"bomb-effect-13.png"];
        SKTexture *f14 = [bombAtlas textureNamed:@"bomb-effect-14.png"];
        _bombTextures = @[f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14];
    }
    return _bombTextures;
}

- (NSArray *)vectors {
    if (!_vectors) {
        CGFloat speed = 250.0;
        _vectors = @[[NSValue valueWithCGVector:CGVectorMake(speed, speed)],
                     [NSValue valueWithCGVector:CGVectorMake(-speed, speed)],
                     [NSValue valueWithCGVector:CGVectorMake(0, speed)]];
    }
    return _vectors;
}

- (NSMutableArray *)shapePointArr {
    if (!_shapePointArr) {
        _shapePointArr = [[NSMutableArray alloc]init];
    }
    return _shapePointArr;
}

- (NSMutableArray *)candyPointArr {
    if(!_candyPointArr) {
        _candyPointArr = [[NSMutableArray alloc]init];
    }
    return _candyPointArr;
}

- (NSMutableArray *)bombPointArr {
    if(!_bombPointArr) {
        _bombPointArr = [[NSMutableArray alloc]init];
    }
    return _bombPointArr;
}

@end
