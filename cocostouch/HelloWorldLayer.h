//
//  HelloWorldLayer.h
//  cocostouch
//
//  Created by Fabio Scognamiglio on 26/09/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"


#define MAX_MISSED 3
#define WIN_HIT 5


// HelloWorldLayer
@interface HelloWorldLayer : CCLayerColor
{
    NSMutableArray *_targets;
    NSMutableArray *_projectiles;
    
    CCSprite *_player;
    CCSprite *_nextProjectile;
    
    int _projectilesDestroyed;
    int _targetMissed;
    
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
