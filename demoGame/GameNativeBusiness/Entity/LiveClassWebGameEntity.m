//
//  LiveClassWebGameEntity.m
//  LivePlayer
//
//  Created by yibo on 2022/5/30.
//

#import "LiveClassWebGameEntity.h"

@implementation LiveClassWebGameDataEntity

@end

@implementation LiveClassWebGameEntity

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"data" : [LiveClassWebGameDataEntity class]
    };
}

@end
