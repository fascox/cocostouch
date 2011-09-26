//
//  AppDelegate.h
//  cocostouch
//
//  Created by Fabio Scognamiglio on 26/09/11.
//  Copyright altotouch 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;

@end
