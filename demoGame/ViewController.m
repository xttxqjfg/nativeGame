//
//  ViewController.m
//  demoGame
//
//  Created by 易博 on 2025/3/27.
//

#import "ViewController.h"
#import <SpriteKit/SpriteKit.h>
#import "RedPacketRainPlayScene.h"
#import "LiveClassWebGameEntity.h"
#import "RedPacketRainGameTool.h"
#import <AVFAudio/AVAudioPlayer.h>

typedef NS_ENUM(NSUInteger, GameInteractionStage) {
    GameInteractionStageUnknow         = 1000,//未知，默认为初始阶段
    GameInteractionStageStart          = 2000,//互动已开启，展示提示
    GameInteractionStagePlay           = 3000,//互动中
    GameInteractionStageSubmit         = 4000,//已做答
    GameInteractionStageEnd            = 5000//结束阶段
};

@interface ViewController ()<RedPacketRainPlaySceneDelegate>

/// 承载视图
@property (nonatomic,strong) SKView *gameContentView;

/// 玩游戏场景
@property (nonatomic,strong) RedPacketRainPlayScene *redPacketRainPlayScene;

/// 音效播放器
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

/// 互动过期时间，主要用于异常恢复，默认10秒
@property (assign, nonatomic) NSInteger expiredTime;

/// 当前互动数据
@property (strong, nonatomic) LiveClassWebGameEntity *currentInteractionEntity;

/// 游戏获得的金币数
@property (assign, nonatomic) NSInteger gameSubmitNumber;

/// 互动阶段
@property (assign, nonatomic) GameInteractionStage currentStage;

@property (weak, nonatomic) IBOutlet UIView *gameView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)startBtnClicked:(UIButton *)sender {
    LiveClassWebGameEntity *gameEntity = [[LiveClassWebGameEntity alloc] init];
    LiveClassWebGameDataEntity *data = [[LiveClassWebGameDataEntity alloc] init];
    data.action = @"play";
    data.redbagDuration = 60;
    data.bombQueue = @[@"5",@"15",@"25",@"3",@"13",@"23",@"2",@"1",@"11",@"31",@"22",@"12",@"50",@"33",@"88",@"100"];
    data.redbagQueue = @[@"4",@"2",@"7",@"5",@"10"];
    data.parameter = @"level=5";
    data.pub = YES;
    
    gameEntity.data = data;
    [self handleRedPackageRainWithEntity:gameEntity];
}

- (IBAction)stopBtnClicked:(UIButton *)sender {
    //互动结束
    if([_gameContentView isDescendantOfView:self.gameView]) {
        //判断当前互动阶段是否已做答，否则主动调一次作答结果
        if (self.currentStage >= GameInteractionStageSubmit) {
            NSLog(@"【原生红包雨】收到结束指令时已完成了作答");
        }
        else {
            NSLog(@"【原生红包雨】收到结束指令时还没有完成作答，此时游戏所属阶段：%@",@(self.currentStage));
                        
            if (GameInteractionStagePlay == self.currentStage ) {
                // 主动结束游戏并提交答案
                [self.redPacketRainPlayScene endGameWithFore:YES];
            }
            else {
//                [self destoryGameView];
            }
        }
    }
    else {
        //销毁可能存在的缓存数据信息
        self.currentInteractionEntity = nil;
        self.currentStage = GameInteractionStageEnd;
        self.gameSubmitNumber = 0;
    }
}

#pragma mark -- RedPacketRainPlaySceneDelegate --
- (void)eventOnRedPacketRainPlaySceneWithType:(RedPacketRainPlaySceneEventType)eventType userinfo:(NSDictionary *)userinfo {
    switch (eventType) {
        case RedPacketRainPlaySceneEventTypeEnd:
        {
//            [self destoryGameContentView];
            
//            self.gameSubmitNumber = [userinfo wx_integerForKey:@"coin" defaultValue:0];
            self.currentStage = GameInteractionStageSubmit;
            //异步提交金币数
//            [self stuCoinsSubmitDataPostWithData:userinfo];
            //金币动效
//            [self.redPackageRainResultView showResultLottieWithCoinNumber:[userinfo wx_integerForKey:@"coin" defaultValue:0]];
            [self playWebGameAudio:2];
            
            break;
        }
        default:
            break;
    }
}

- (void)handleRedPackageRainWithEntity:(LiveClassWebGameEntity *)entity {
    if (entity.data.pub) {
        //开始播放背景音乐
        [self playWebGameAudio:4];
        
        //start指令不再查询作答状态，直接处理
        if ([entity.data.action isEqualToString:@"start"]) {
            self.currentStage = GameInteractionStageStart;
            self.gameSubmitNumber = 0;
            //开始展示游戏场景
            [self.gameContentView presentScene:self.redPacketRainPlayScene];
        }
        else if ([entity.data.action isEqualToString:@"play"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //互动开启
                if(GameInteractionStageStart != self.currentStage) {
                    //开始展示游戏场景
                    [self.gameContentView presentScene:self.redPacketRainPlayScene];
                }
                                
                [self.redPacketRainPlayScene startPlayGameWithConfig:entity.data];
                self.currentStage = GameInteractionStagePlay;
                self.gameSubmitNumber = 0;
            });
        }
        else {
            NSLog(@"【原生红包雨】非正常的开启类型指令");
        }
    }
}

#pragma mark - 音效播放 -
- (void)playWebGameAudio:(NSInteger)audioType {
    [self destoryAudio];
    NSString *audioName;
    switch (audioType) {
        case 1:
            //飞金币
            audioName = @"redpacketrain_coins_move";
            break;
        case 2:
            //结算背景
            audioName = @"redpacketrain_result";
            break;
        case 3:
            //获取点击
            audioName = @"redpacketrain_colloct_clicked";
            break;
        case 4:
            //背景音乐
            audioName = @"bg";
            break;
        default:
            return;
            break;
    }
    
    NSString *audioPath = [[NSBundle mainBundle] pathForResource:audioName ofType:@"mp3"];
    if (audioPath == nil) {
        return;
    }
    NSURL *url = [NSURL fileURLWithPath:audioPath];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.volume = 1.0;
    self.audioPlayer.numberOfLoops = 0;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer setCurrentTime:0.0];
    [self.audioPlayer play];
}

- (void)destoryAudio {
    if (self.audioPlayer) {
        if (self.audioPlayer.isPlaying) {
            _audioPlayer.volume = 0.0;
            [self.audioPlayer stop];
        }
        self.audioPlayer = nil;
    }
}

#pragma mark -- get --
- (RedPacketRainPlayScene *)redPacketRainPlayScene {
    if (!_redPacketRainPlayScene) {
        _redPacketRainPlayScene = [RedPacketRainPlayScene sceneWithSize:self.gameView.frame.size];
        _redPacketRainPlayScene.scaleMode = SKSceneScaleModeAspectFill;
        _redPacketRainPlayScene.eventDelegate = self;
    }
    return _redPacketRainPlayScene;
}


- (SKView *)gameContentView {
    if(!_gameContentView) {
        [[RedPacketRainGameTool sharedInstance] updateConfigWithSize:self.gameView.frame.size];
        NSLog(@"【原生红包雨】游戏视图size：%@",@(self.gameView.frame));
        _gameContentView = [[SKView alloc]initWithFrame: self.gameView.bounds];
        _gameContentView.showsFPS = YES;
        _gameContentView.showsNodeCount = YES;
        _gameContentView.allowsTransparency = YES;
        [self.gameView addSubview:_gameContentView];
    }
    return _gameContentView;
}

@end
