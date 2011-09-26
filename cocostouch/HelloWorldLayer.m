//
//  HelloWorldLayer.m
//  cocotest
//
//  Created by Fabio Scognamiglio on 26/09/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"
#import "GameOverScene.h"


// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
    
    CCSprite *bkg = [CCSprite spriteWithFile:@"background.png"];
    bkg.anchorPoint = ccp(0, 0);
    [layer addChild:bkg z:-1];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
        
        _targets = [[NSMutableArray alloc] init];
        _projectiles = [[NSMutableArray alloc] init];
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        
        _player = [CCSprite spriteWithFile:@"Player.png"];
        
        _player.position = ccp(_player.contentSize.width/2, winSize.height/2);
        [self addChild:_player];
        
        [self schedule:@selector(gameLogic:) interval:1.0];
        [self schedule:@selector(update:)];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music-aac.caf"];
        
        self.isTouchEnabled =YES;
	}
	return self;
}

-(void)addTarget {
    
    CCSprite *target = [CCSprite spriteWithFile:@"Target.png"]; 
    
    // Determine where to spawn the target along the Y axis
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    int minY = target.contentSize.height/2;
    int maxY = winSize.height - target.contentSize.height/2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    // Create the target slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    target.position = ccp(winSize.width + (target.contentSize.width/2), actualY);
    [self addChild:target];
    
    // Determine speed of the target
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    // Create the actions
    id actionMove = [CCMoveTo actionWithDuration:actualDuration 
                                        position:ccp(-target.contentSize.width/2, actualY)];
    id actionMoveDone = [CCCallFuncN actionWithTarget:self 
                                             selector:@selector(spriteMoveFinished:)];
    [target runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
    
    target.tag = 1;
    [_targets addObject:target];
    
}

-(void)spriteMoveFinished:(id)sender {
    
    CCSprite *sprite = (CCSprite *)sender;
    [self removeChild:sprite cleanup:YES];
    
    if (sprite.tag == 1) { // target
        
        [_targets removeObject:sprite];
        
        if ( ++_targetMissed == MAX_MISSED) {
            
            _targetMissed = 0;
            GameOverScene *gameOverScene = [GameOverScene node];
            [gameOverScene.layer.label setString:@"Mi dispiace hai perso :["];
            [[CCDirector sharedDirector] replaceScene:gameOverScene];
        }
        
    } else if (sprite.tag == 2) { // projectile
        [_projectiles removeObject:sprite];
    }
}

-(void)gameLogic:(ccTime)dt {
    [self addTarget];
}



// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
    [_targets release];
    _targets = nil;
    
    [_projectiles release];
    _projectiles = nil;
        
	[super dealloc];
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_nextProjectile != nil) return;
    
    // Choose one of the touches to work with
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    // Set up initial location of projectile
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    _nextProjectile = [[CCSprite spriteWithFile:@"Projectile.png"] retain];
    _nextProjectile.position = ccp(20, winSize.height/2);
    
    // Determine offset of location to projectile
    int offX = location.x - _nextProjectile.position.x;
    int offY = location.y - _nextProjectile.position.y;
    
    // Bail out if we are shooting down or backwards
    if (offX <= 0) return;
    
    // Play a sound!
    [[SimpleAudioEngine sharedEngine] playEffect:@"pew-pew-lei.caf"];
    
    // Determine where we wish to shoot the projectile to
    int realX = winSize.width + (_nextProjectile.contentSize.width/2);
    float ratio = (float) offY / (float) offX;
    int realY = (realX * ratio) + _nextProjectile.position.y;
    CGPoint realDest = ccp(realX, realY);
    
    // Determine the length of how far we're shooting
    int offRealX = realX - _nextProjectile.position.x;
    int offRealY = realY - _nextProjectile.position.y;
    float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
    float velocity = 480/1; // 480pixels/1sec
    float realMoveDuration = length/velocity;
    
    // Determine angle to face
    float angleRadians = atanf((float)offRealY / (float)offRealX);
    float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
    float cocosAngle = -1 * angleDegrees;
    float rotateSpeed = 0.5 / M_PI; // Would take 0.5 seconds to rotate 0.5 radians, or half a circle
    float rotateDuration = fabs(angleRadians * rotateSpeed);    
    [_player runAction:[CCSequence actions:
                        [CCRotateTo actionWithDuration:rotateDuration angle:cocosAngle],
                        [CCCallFunc actionWithTarget:self selector:@selector(finishShoot)],
                        nil]];
    
    // Move projectile to actual endpoint
    [_nextProjectile runAction:[CCSequence actions:
                                [CCMoveTo actionWithDuration:realMoveDuration position:realDest],
                                [CCCallFuncN actionWithTarget:self selector:@selector(spriteMoveFinished:)],
                                nil]];
    
    // Add to projectiles array
    _nextProjectile.tag = 2;
    
}

- (void)finishShoot {
    
    // Ok to add now - we've finished rotation!
    [self addChild:_nextProjectile];
    [_projectiles addObject:_nextProjectile];
    
    // Release
    [_nextProjectile release];
    _nextProjectile = nil;
    
}

- (void)update:(ccTime)dt {
    
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    for (CCSprite *projectile in _projectiles) {
        CGRect projectileRect = CGRectMake(
                                           projectile.position.x - (projectile.contentSize.width/2), 
                                           projectile.position.y - (projectile.contentSize.height/2), 
                                           projectile.contentSize.width, 
                                           projectile.contentSize.height);
        
        NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
        for (CCSprite *target in _targets) {
            CGRect targetRect = CGRectMake(
                                           target.position.x - (target.contentSize.width/2), 
                                           target.position.y - (target.contentSize.height/2), 
                                           target.contentSize.width, 
                                           target.contentSize.height);
            
            if (CGRectIntersectsRect(projectileRect, targetRect)) {
                [targetsToDelete addObject:target];				
            }						
        }
        
        for (CCSprite *target in targetsToDelete) {
            [_targets removeObject:target];
            [target stopAllActions];
            
            
            id disappear = [CCFadeTo actionWithDuration:.5 opacity:0];
            id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(targetHit:)];
            id rotate = [CCRotateBy actionWithDuration:0.9 angle:720];
            [target runAction:[CCSequence actions:rotate, disappear, actionMoveDone, nil]];
            
            _projectilesDestroyed++;
            if (_projectilesDestroyed > WIN_HIT) {
                GameOverScene *gameOverScene = [GameOverScene node];
                _projectilesDestroyed = 0;
                [gameOverScene.layer.label setString:@"Bravo hai vinto !!"];
                [[CCDirector sharedDirector] replaceScene:gameOverScene];
            }
            
            //[self removeChild:target cleanup:YES];									
        }
        
        if (targetsToDelete.count > 0) {
            [projectilesToDelete addObject:projectile];
        }
        [targetsToDelete release];
    }
    
    for (CCSprite *projectile in projectilesToDelete) {
        [_projectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
    [projectilesToDelete release];
}

-(void) targetHit:(id) sender {
    
    CCSprite *sprite = (CCSprite *) sender;
    [self removeChild:sprite cleanup:YES];
}

@end
