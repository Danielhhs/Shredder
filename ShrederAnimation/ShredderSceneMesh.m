//
//  ShredderSceneMesh.m
//  ShrederAnimation
//
//  Created by Huang Hongsen on 15/12/2.
//  Copyright © 2015年 cn.daniel. All rights reserved.
//

#import "ShredderSceneMesh.h"

@interface ShredderSceneMesh() {
    SceneMeshVertex *vertices;
    GLsizei vertexCount;
    GLsizei indexCount;
}
@property (nonatomic) GLuint xResolution;
@property (nonatomic) GLuint yResolution;
@property (nonatomic) size_t screenWidth;
@property (nonatomic) size_t screenHeight;
@property (nonatomic) CGFloat shredderCurlRadius;
@property (nonatomic) CGFloat centerLocation;
@end


@implementation ShredderSceneMesh

- (instancetype) initWithXResolution:(GLuint)xResolution yResolution:(GLuint)yResolution screenWidth:(size_t)screenWidth screenHeight:(size_t)screenHeight
{
    _xResolution = xResolution;
    _yResolution = yResolution;
    _screenWidth = screenWidth;
    _screenHeight = screenHeight;
    _shredderCurlRadius = screenHeight / 0.5;
    _centerLocation = 0;
    vertexCount = (GLsizei)((xResolution * 2) * (yResolution + 1));
    vertices = malloc(sizeof(SceneMeshVertex) * vertexCount);
    
    for (int y = 0; y < yResolution + 1; y++) {
        GLfloat tv = (GLfloat) y / yResolution;
        GLfloat vy = tv * screenHeight;
        for (int x = 0; x < xResolution * 2; x++) {
            GLfloat tx = (x + 1) / 2 / (GLfloat)xResolution;
            SceneMeshVertex *vertex = &vertices[y * (xResolution * 2) + x];
            vertex->position.x = tx * screenWidth;
            vertex->position.y = vy;
            vertex->position.z = 0;
            vertex->texCoords.s = tx;
            vertex->texCoords.t = tv;
        }
    }
    
    
    indexCount = xResolution * yResolution * 2 * 3;
    GLushort *indicies = malloc(indexCount * sizeof(GLushort));
    for (int y = 0; y < yResolution; y++) {
        for (int x = 0; x < xResolution; x++) {
            int idx = (y * xResolution) + x;
            int i = y * xResolution * 2 + x * 2;
            indicies[idx * 6 + 0] = i;
            indicies[idx * 6 + 1] = i + 1;
            indicies[idx * 6 + 2] = i + xResolution * 2;
            indicies[idx * 6 + 3] = i + xResolution * 2;
            indicies[idx * 6 + 4] = i + 1;
            indicies[idx * 6 + 5] = i + xResolution * 2 + 1;
        }
    }
    NSData *vertexData = [NSData dataWithBytes:vertices length:vertexCount * sizeof(SceneMeshVertex)];
    NSData *indexData = [NSData dataWithBytes:indicies length:indexCount * sizeof(GLushort)];
    return [self initWithVerticesData:vertexData indicesData:indexData];
}

- (void) drawEntireMesh
{
    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_SHORT, NULL);
}

- (void) prepareToDraw
{
    if (vertexBuffer == 0 && [self.verticesData length] > 0) {
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, [self.verticesData length], [self.verticesData bytes], GL_STATIC_DRAW);
    }
    if (indexBuffer == 0 && [self.indicesData length] > 0) {
        glGenBuffers(1, &indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, [self.indicesData length], [self.indicesData bytes], GL_STATIC_DRAW);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(SceneMeshVertex), NULL + offsetof(SceneMeshVertex, position));
    
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(SceneMeshVertex), NULL + offsetof(SceneMeshVertex, normal));
    
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(SceneMeshVertex), NULL + offsetof(SceneMeshVertex, texCoords));
        
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
}

- (void) updateWithPercent:(GLfloat)percent
{
    GLfloat shredderLocation = self.screenHeight * percent;
    self.centerLocation = shredderLocation;
    for (int y = 0; y < shredderLocation; y++) {
        GLfloat centerAngle = (CGFloat)(shredderLocation - y) / self.shredderCurlRadius;
        for (int x = 0; x < self.xResolution * 2; x++) {
            SceneMeshVertex *vertex = &vertices[y * (self.xResolution * 2) + x];
            vertex->position.y = shredderLocation - self.shredderCurlRadius * sinf(centerAngle);
            vertex->position.z = self.shredderCurlRadius * (1 - cosf(centerAngle));
            if (x % 4 >= 2) {
                vertex->position.z -= 10;
            }
        }
    }
    [self makeDynamicAndUpdateWithVertices:vertices numberOfVertices:vertexCount];
}

@end
