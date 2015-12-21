//
//  ShredderPaperPieceSceneMesh.h
//  ShrederAnimation
//
//  Created by Huang Hongsen on 12/15/15.
//  Copyright © 2015 cn.daniel. All rights reserved.
//

#import "SceneMesh.h"

typedef struct {
    GLKVector3 position;
    GLKVector3 normal;
    GLKVector2 texCoords;
    GLKVector2 pieceWidthRange;
    GLKVector3 cylinderCenter;
}ShredderPaperPieceSceneVertex;

@interface ShredderPaperPieceSceneMesh : SceneMesh
- (void) updateWithPercentage:(CGFloat)percentage;
- (instancetype) initWithScreenWidth:(size_t)screenWidth screenHeight:(size_t)screenHeight totalPieces:(NSInteger)totalPieces index:(NSInteger)index;
- (CGFloat) generateRadiusForScreenHeight:(CGFloat)screenHeight;
- (GLuint) vertexArrayObject;
@end
