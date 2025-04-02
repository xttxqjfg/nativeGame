//
//  RedPacketRainGameTool.m
//  AFNetworking
//
//  Created by yibo on 2022/10/11.
//

#import "RedPacketRainGameTool.h"

@interface RedPacketRainGameTool()

/// 当前游戏视图
@property (nonatomic,assign) CGSize gameViewSize;

/// 游戏视图控件比例
@property (nonatomic,assign) CGFloat gameViewRatio;

/// 泡泡大小
@property (nonatomic,assign) CGSize bubbleSize;

@end

@implementation RedPacketRainGameTool

+ (instancetype)sharedInstance {
    static RedPacketRainGameTool *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RedPacketRainGameTool alloc] init];
    });
    return sharedInstance;
}

/// 用当前游戏视图大小重新计算
/// - Parameter size: 视图大小
/// 泡泡大小
/// iPad mini2， {860, 645}及以上：144px
/// iPad 7，{906, 680}及以上：154px
/// iPad Pro 12.9，{1145, 859}及以上：194px
/// 手机：90px
- (void)updateConfigWithSize:(CGSize)size {
    self.gameViewSize = size;
    
    CGFloat width = size.width;
    if(width > 1000) {
        width = 1000;
    }
    else if (width < 750) {
        width = 750;
    }
    
    //将比例控制在 1~1.5 之间
    self.gameViewRatio = width / 750;
    
    if(size.width >= 1145) {
        self.bubbleSize = CGSizeMake(194, 194);
    }
    else if(size.width >= 906) {
        self.bubbleSize = CGSizeMake(154, 154);
    }
    else if(size.width >= 860) {
        self.bubbleSize = CGSizeMake(144, 144);
    }
    else {
        self.bubbleSize = CGSizeMake(144, 144);
    }
}

/// 获取游戏里控件的缩放比例
- (CGFloat)getGameSizeRatio {
    return self.gameViewRatio;
}

/// 根据机型适配后获取泡泡大小
- (CGSize)getBubbleSize {
    return self.bubbleSize;
}

/// 解析游戏额外的配置参数，比如游戏难度等
/// - Parameter configStr: 配置字符串
+ (NSDictionary *)parseGameExtConfigWithStr:(NSString *)configStr {
    if(0 == [configStr length]) {
        return @{};
    }
    
    //拼接成url格式便于后面解析参数
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"test://?%@",configStr]];
    NSMutableDictionary *paramer = [[NSMutableDictionary alloc]init];

    if (url == nil) {
        return paramer;
    }
    //创建url组件类
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:url.absoluteString];
    
    //遍历所有参数，添加入字典
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [paramer setObject:obj.value forKey:obj.name];
    }];
    
    return [paramer copy];
}

/// 将难度等级转换成难度系数
/// - Parameter level: 难度等级 1~5
+ (CGFloat)getGameDifficultyDegreeWithLevel:(NSInteger)level {
    CGFloat difficultyDegree = 1.2;
    switch (level) {
        case 1:
        {
            difficultyDegree = 0.8;
            break;
        }
        case 2:
        {
            difficultyDegree = 1.0;
            break;
        }
        case 4:
        {
            difficultyDegree = 1.5;
//            difficultyDegree = IS_IPAD ? 2.0 : 1.9;
            break;
        }
        case 5:
        {
            difficultyDegree = 1.8;
//            difficultyDegree = IS_IPAD ? 2.5 : 2.2;
            break;
        }
        default:
        case 3:
        {
            difficultyDegree = 1.2;
            break;
        }
    }
    return difficultyDegree * 1.5;
}

@end
