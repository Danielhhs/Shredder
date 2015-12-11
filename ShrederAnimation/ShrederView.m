//
//  ShrederView.m
//  ShrederAnimation
//
//  Created by Huang Hongsen on 15/11/29.
//  Copyright © 2015年 cn.daniel. All rights reserved.
//

#import "ShrederView.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/glext.h>
#import "OpenGLHelper.h"
typedef struct {
    GLfloat x, y, z;
    GLfloat u, v;
} Vertex;
@interface ShrederView () {
    GLuint framebuffer;
    GLuint colorRenderbuffer;
    GLint viewportWidth;
    GLint viewportHeight;
    
    GLuint mvpLoc;
    GLuint samplerLoc;
    
    GLuint textureWidth;
    GLuint textureHeight;
    
    GLuint texture;
    GLfloat mvp[16];
    GLuint program;
    GLuint pageVAO;
    GLuint vertexBuffer;
    GLuint indexBuffer;
    GLsizei elementCount;
}
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic) CGFloat screenScale;
@property (nonatomic) NSUInteger horizontalResolution;
@property (nonatomic) NSUInteger verticalResolution;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSTimeInterval elapsedTime;
@end


void OrthoM4x4(GLfloat *out, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far);

@implementation ShrederView

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (BOOL) setupGLView
{
    self.screenScale = [UIScreen mainScreen].scale;
    [self setContentScaleFactor:self.screenScale];
    CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
    layer.backgroundColor = [UIColor clearColor].CGColor;
    [layer setDrawableProperties:@{kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8, kEAGLDrawablePropertyRetainedBacking : @(NO)}];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (![self createFrameBuffer]) {
        return NO;
    }
    
    [self createVertexBufferWithXres:self.horizontalResolution yRes:self.verticalResolution];
    if (![self createShaders]) {
        return NO;
    }
    
    textureWidth = (GLuint)self.frame.size.width * self.screenScale;
    textureHeight = (GLuint) self.frame.size.height * self.screenScale;
    
    texture = [self generateTexture];
    [self setupMVP];
    [self createVAO];
    return YES;
}

#pragma mark - Initialization
- (instancetype) initWithFrame:(CGRect)frame horizontalResolution:(NSUInteger)horizontalResolution verticalResolution:(NSUInteger)verticalResolution
{
    self = [self initWithFrame:frame];
    if (self) {
        _horizontalResolution = horizontalResolution;
        _verticalResolution = verticalResolution;
        if (![self setupGLView]) {
            return nil;
        }
        [self initializeGLState];
    }
    return self;
}

- (void) initializeGLState
{
    [EAGLContext setCurrentContext:self.context];
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glViewport(0, 0, viewportWidth, viewportHeight);
    self.backgroundColor = [UIColor clearColor];
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glUseProgram(program);
    glUniform4fv(mvpLoc, 1, mvp);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
}

#pragma mark - FrameBuffer
- (BOOL) createFrameBuffer
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyFrameBuffer];
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &viewportWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &viewportHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        return NO;
    }
    return YES;
}

- (void) destroyFrameBuffer
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteFramebuffers(1, &framebuffer);
    framebuffer = 0;
    glDeleteRenderbuffers(1, &colorRenderbuffer);
    colorRenderbuffer = 0;
}

- (GLuint) generateTexture
{
    GLuint aTexture;
    glGenTextures(1, &aTexture);
    glBindTexture(GL_TEXTURE_2D, aTexture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return aTexture;
}

- (void) setupMVP
{
    [EAGLContext setCurrentContext:self.context];
    OrthoM4x4(mvp, 0, viewportWidth, 0, viewportHeight, -1000.f, 1000.f);
    glUseProgram(program);
    glUniform4fv(mvpLoc, 1, mvp);
}

- (void) createVAO
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyVAO];
    
    glGenVertexArrays(1, &pageVAO);
    glBindVertexArray(pageVAO);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), offsetof(Vertex, x));
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, v));
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBindVertexArray(0);
}

- (void) destroyVAO
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteVertexArrays(1, &pageVAO);
    pageVAO = 0;
}

- (void) createVertexBufferWithXres:(NSUInteger)xRes yRes:(NSUInteger)yRes
{
    [EAGLContext setCurrentContext:self.context];
    NSUInteger vertexCount = xRes * 2 * (yRes + 1) * 2 * 3;
    GLsizeiptr verticesSize = (vertexCount * sizeof(Vertex));
    Vertex *vertices = malloc(verticesSize);
    
    for (int y = 0; y < yRes + 1; y++) {
        CGFloat tv = (GLfloat)y / yRes;
        CGFloat vy = tv * viewportHeight;
        for (int x = 0; x < xRes; x++) {
            Vertex *v = &vertices[y * (xRes * 2) + x];
            v -> u = (GLfloat)((x + 1) / 2) / xRes;
            v -> v = tv;
            v -> x = v -> u * viewportWidth;
            v -> y = vy;
            v -> z = -1;
            NSLog(@"Vertex {%g, %g, %g}, texCoords{%g, %g}", v->x, v->y, v->x, v->u, v->v);
        }
    }
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, verticesSize, vertices, GL_STATIC_DRAW);
    free(vertices);
    
    elementCount = (GLsizei)(xRes * yRes * 2 * 3);
    GLsizeiptr indiciesSize = elementCount * sizeof(GLushort);
    GLushort *indices = malloc(indiciesSize);
    for (int y = 0; y < yRes; y++) {
        for (int x = 0; x < xRes; x++) {
            int i = y * (int)xRes * 2 + x * 2;
            int idx = y * (int)xRes + x;
            indices[idx + 0] = i;
            indices[idx + 1] = i + 1;
            indices[idx + 2] = i + xRes * 2;
            indices[idx + 3] = i + 1;
            indices[idx + 4] = i + xRes * 2 + 1;
            indices[idx + 5] = i + xRes * 2;
        }
    }
    
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indiciesSize, indices, GL_STATIC_DRAW);
    free(indices);
}

- (BOOL) createShaders
{
    if ((program = [OpenGLHelper loadProgramWithVertexShaderSrc:@"ShredderVertex.glsl" fragmentShaderSrc:@"ShredderFragment.glsl"]) != 0) {
        glUseProgram(program);
        glBindAttribLocation(program, 0, "a_position");
        glBindAttribLocation(program, 1, "a_texCoord");
        glGetUniformLocation(program, "u_mvpMatrix");
        glGetUniformLocation(program, "s_tex");
        return YES;
    }
    return NO;
}

- (void) draw:(CADisplayLink *)displayLink
{
    [EAGLContext setCurrentContext:self.context];
    glClear(GL_COLOR_BUFFER_BIT);
    glCullFace(GL_BACK);
    glUseProgram(program);
    
    glBindVertexArray(pageVAO);
    glDrawElements(GL_TRIANGLES, elementCount, GL_UNSIGNED_SHORT, NULL);
}

- (void) drawImage:(UIImage *)image onTexture:(GLuint) aTexture
{
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, aTexture);
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, 1);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    GLubyte *textureData = CGBitmapContextGetData(context);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLuint)width, (GLuint)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    CGContextRelease(context);
}

- (void) startShreddering
{
    [self drawImage:[UIImage imageNamed:@"image.jpg"] onTexture:texture];
    [self startAnimating];
}

- (void) startAnimating
{
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(draw:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

void OrthoM4x4(GLfloat *out, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far)
{
    out[0] = 2.f/(right-left); out[4] = 0.f; out[8] = 0.f; out[12] = -(right+left)/(right-left);
    out[1] = 0.f; out[5] = 2.f/(top-bottom); out[9] = 0.f; out[13] = -(top+bottom)/(top-bottom);
    out[2] = 0.f; out[6] = 0.f; out[10] = -2.f/(far-near); out[14] = -(far+near)/(far-near);
    out[3] = 0.f; out[7] = 0.f; out[11] = 0.f; out[15] = 1.f;
}
@end
