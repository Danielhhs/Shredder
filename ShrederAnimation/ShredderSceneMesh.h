//
//  ShredderSceneMesh.h
//  ShrederAnimation
//
//  Created by Huang Hongsen on 15/12/2.
//  Copyright © 2015年 cn.daniel. All rights reserved.
//

#import "SceneMesh.h"

@interface ShredderSceneMesh : SceneMesh

- (instancetype) initWithXResolution:(GLuint)xResolution yResolution:(GLuint)yResolution screenWidth:(size_t)screenWidth screenHeight:(size_t)screenHeight;
- (void) updateWithPercent:(GLfloat)percent;
@end
