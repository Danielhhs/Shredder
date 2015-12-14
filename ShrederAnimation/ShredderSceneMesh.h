//
//  ShredderSceneMesh.h
//  ShrederAnimation
//
//  Created by Huang Hongsen on 12/14/15.
//  Copyright © 2015 cn.daniel. All rights reserved.
//

#import "SceneMesh.h"


typedef struct {
    GLKVector3 position;
    GLKVector3 normal;
    GLKVector2 texCoords;
    GLKVector3 cylinderCenter;
}ShredderVertex;

@interface ShredderSceneMesh : SceneMesh

- (instancetype) initWithXResolution:(GLuint)xResolution yResolution:(GLuint)yResolution screenWidth:(size_t)screenWidth screenHeight:(size_t)screenHeight;
- (void) updateWithPercent:(GLfloat)percent;
@end
