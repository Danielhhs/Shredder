//
//  ShredderRenderer.h
//  ShrederAnimation
//
//  Created by Huang Hongsen on 15/12/3.
//  Copyright © 2015年 cn.daniel. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface ShredderRenderer : NSObject<GLKViewDelegate>

- (void) startShredderingView:(UIView *)view inContainerView:(UIView *)containerView numberOfPieces:(NSInteger)numberOfPieces animationDuration:(NSTimeInterval)duration;

@end
