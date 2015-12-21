//
//  ShredderPaperPieceSceneMesh.m
//  ShrederAnimation
//
//  Created by Huang Hongsen on 12/15/15.
//  Copyright © 2015 cn.daniel. All rights reserved.
//

#import "ShredderPaperPieceSceneMesh.h"

@interface ShredderPaperPieceSceneMesh () {
    ShredderPaperPieceSceneVertex *vertices;
    NSInteger vertexCount;
    NSInteger indexCount;
}
@property (nonatomic) CGFloat cylinderRadius;
@property (nonatomic) CGFloat screenHeight;
@property (nonatomic) NSInteger pixelsPerPiece;
@end

@implementation ShredderPaperPieceSceneMesh

- (instancetype) initWithScreenWidth:(size_t)screenWidth screenHeight:(size_t)screenHeight totalPieces:(NSInteger)totalPieces index:(NSInteger)index
{
    NSInteger pixelsPerPiece = screenWidth / totalPieces;
    _pixelsPerPiece = pixelsPerPiece;
    NSInteger startPixelCount = index * pixelsPerPiece;
    _screenHeight = screenHeight;
    vertexCount = (pixelsPerPiece + 1) * (screenHeight + 1);
    self.cylinderRadius = [self generateRadiusForScreenHeight:screenHeight];
    vertices = malloc(vertexCount * sizeof(ShredderPaperPieceSceneVertex));
    
    for (int y = 0; y < screenHeight + 1; y++) {
        GLfloat ty = (GLfloat)y / screenHeight;
        for (int x = 0; x < pixelsPerPiece + 1; x++) {
            ShredderPaperPieceSceneVertex *vertex = &vertices[y * (pixelsPerPiece + 1) + x];
            vertex->position.x = x + startPixelCount;
            vertex->position.y = y;
            vertex->position.z = 0;
            vertex->texCoords.x = (GLfloat)(x + startPixelCount) / screenWidth;
            vertex->texCoords.y = ty;
            vertex->pieceWidthRange = GLKVector2Make(startPixelCount, startPixelCount + pixelsPerPiece);
            vertex->cylinderCenter = GLKVector3Make(vertex->position.x, 0, _cylinderRadius);
        }
    }
    NSLog(@"index = %lu, radius = %g", index, self.cylinderRadius);
    indexCount = (pixelsPerPiece * screenHeight * 2 * 3);
    GLuint *indices = malloc(indexCount * sizeof(GLuint));
    int counter = 0;
    for (int y = 0; y < screenHeight; y++) {
        for (int x = 0; x < pixelsPerPiece; x++) {
            NSInteger idx = y * pixelsPerPiece + x;
            NSInteger i = y * (pixelsPerPiece + 1) + x;
            indices[idx * 6 + 0] = (GLuint)i;
            indices[idx * 6 + 1] = (GLuint)(i + 1);
            indices[idx * 6 + 2] = (GLuint)(i + pixelsPerPiece + 1);
            indices[idx * 6 + 3] = (GLuint)i + 1;
            indices[idx * 6 + 4] = (GLuint)(i + pixelsPerPiece + 2);
            indices[idx * 6 + 5] = (GLuint)(i + pixelsPerPiece + 1);
            counter++;
        }
    }
    
    NSData *vertexData = [NSData dataWithBytes:vertices length:vertexCount * sizeof(ShredderPaperPieceSceneVertex)];
    NSData *indexData = [NSData dataWithBytes:indices length:indexCount * sizeof(GLuint)];
    return [self initWithVerticesData:vertexData indicesData:indexData];
}

- (void) prepareToDraw
{
    if (vertexBuffer == 0 && [self.verticesData length] != 0) {
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, [self.verticesData length], [self.verticesData bytes], GL_STATIC_DRAW);
    }
    if (indexBuffer == 0 && [self.indicesData length] != 0) {
        glGenBuffers(1, &indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, [self.indicesData length], [self.indicesData bytes], GL_STATIC_DRAW);
    }
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(ShredderPaperPieceSceneVertex), NULL + offsetof(ShredderPaperPieceSceneVertex, position));
    
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(ShredderPaperPieceSceneVertex), NULL + offsetof(ShredderPaperPieceSceneVertex, normal));
    
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(ShredderPaperPieceSceneVertex), NULL + offsetof(ShredderPaperPieceSceneVertex, texCoords));
    
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 2, GL_FLOAT, GL_FALSE, sizeof(ShredderPaperPieceSceneVertex), NULL + offsetof(ShredderPaperPieceSceneVertex, pieceWidthRange));
    
    glEnableVertexAttribArray(4);
    glVertexAttribPointer(4, 3, GL_FLOAT, GL_FALSE, sizeof(ShredderPaperPieceSceneVertex), NULL + offsetof(ShredderPaperPieceSceneVertex, cylinderCenter));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
}

- (void) drawEntireMesh
{
    glDrawElements(GL_TRIANGLES, (GLsizei)indexCount, GL_UNSIGNED_INT, NULL);
}

- (void) updateWithPercentage:(CGFloat)percentage
{
    GLfloat shredderLocation = self.screenHeight * percentage;
    for (int y = 0; y <= shredderLocation; y++) {
        for (int x = 0; x < self.pixelsPerPiece + 1; x++) {
            ShredderPaperPieceSceneVertex *vertex = &vertices[y * (self.pixelsPerPiece + 1) + x];
            vertex->cylinderCenter.y = shredderLocation;
        }
    }
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ShredderPaperPieceSceneVertex) * vertexCount, vertices, GL_DYNAMIC_DRAW);
}

- (CGFloat) generateRadiusForScreenHeight:(CGFloat)screenHeight
{
    CGFloat amplitude = screenHeight / 0.4;
    CGFloat shredderCurlRadius = screenHeight / 0.2;
    int min = -50;
    int max = 50;
    int randomNumber = min + rand() % (max-min);
    double factor = (double) randomNumber / (max - min);
    return shredderCurlRadius + factor * amplitude;
}

@end
