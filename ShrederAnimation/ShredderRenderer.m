//
//  ShredderRenderer.m
//  ShrederAnimation
//
//  Created by Huang Hongsen on 15/12/3.
//  Copyright © 2015年 cn.daniel. All rights reserved.
//

#import "ShredderRenderer.h"
#import "ShredderFrontSceneMesh.h"
#import "OpenGLHelper.h"
#import "ShredderBackSceneMesh.h"
@interface ShredderRenderer() {
    GLuint program;
    GLuint mvpLoc;
    GLuint samplerLoc;
    GLuint texture;
    GLuint shredderPositionLoc;
    GLfloat shredderPosition;
    GLuint backProgram;
    GLuint backMvpLoc;
    GLuint backSamplerLoc;
    GLuint backShredderPotisionLoc;
}
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKView *animationView;
@property (nonatomic, strong) ShredderFrontSceneMesh *mesh;
@property (nonatomic, strong) ShredderBackSceneMesh *backMesh;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSTimeInterval elapsedTime;
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

void OrthoM4x4(GLfloat *out, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far);

@implementation ShredderRenderer

- (instancetype) init
{
    self = [super init];
    if (self) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    }
    return self;
}

-  (void) setupGL
{
    [EAGLContext setCurrentContext:self.context];
    program = [OpenGLHelper loadProgramWithVertexShaderSrc:@"ShredderVertex.glsl" fragmentShaderSrc:@"ShredderFragment.glsl"];
    glUseProgram(program);
    mvpLoc = glGetUniformLocation(program, "u_mvpMatrix");
    samplerLoc = glGetUniformLocation(program, "s_tex");
    shredderPositionLoc = glGetUniformLocation(program, "u_shredderPosition");
    
    backProgram = [OpenGLHelper loadProgramWithVertexShaderSrc:@"ShredderVertexShadow.glsl" fragmentShaderSrc:@"ShredderFragmentShadow.glsl"];
    glUseProgram(backProgram);
    backMvpLoc = glGetUniformLocation(backProgram, "u_mvpMatrix");
    backSamplerLoc = glGetUniformLocation(backProgram, "s_tex");
    backShredderPotisionLoc = glGetUniformLocation(backProgram, "u_shredderPosition");
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);
    glEnableVertexAttribArray(3);
    glClearColor(0, 0, 0, 1);
}

- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [EAGLContext setCurrentContext:self.context];
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glViewport(0, 0, (GLuint)view.drawableWidth, (GLuint)view.drawableHeight);
    
    GLKMatrix4 modelView = GLKMatrix4MakeTranslation(-view.frame.size.width / 2, -view.frame.size.height / 2, -view.frame.size.height / 2 - 200);
    GLfloat aspect = (GLfloat)view.frame.size.width / view.frame.size.height;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), aspect, 0.1, 1000);
    GLKMatrix4 mvp = GLKMatrix4Multiply(perspective, modelView);
    
//    GLfloat mvp[16];
//    OrthoM4x4(mvp, 0, view.bounds.size.width, 0, view.bounds.size.height, -1000, 1000);
    
    
    glUseProgram(backProgram);
    glUniformMatrix4fv(backMvpLoc, 1, GL_FALSE, mvp.m);
    glUniform1f(backShredderPotisionLoc, shredderPosition);
    [self.backMesh prepareToDraw];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(backSamplerLoc, 0);
    [self.backMesh drawEntireMesh];
    
    glUseProgram(program);
    glUniformMatrix4fv(mvpLoc, 1, GL_FALSE, mvp.m);
    glUniform1f(shredderPositionLoc, shredderPosition);
    
    [self.mesh prepareToDraw];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(samplerLoc, 0);
    [self.mesh drawEntireMesh];
    
}

- (void) setupTextureWithView:(UIView *)view
{
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = view.bounds.size.width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, view.bounds.size.width, view.bounds.size.height, bitsPerComponent, bytesPerRow, colorSpace, 1);
    CGColorSpaceRelease(colorSpace);
    
    [view.layer renderInContext:context];
    
    GLubyte *textureData = CGBitmapContextGetData(context);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, view.bounds.size.width, view.bounds.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    CGContextRelease(context);
    
}

- (void) startShredderingView:(UIView *)view inContainerView:(UIView *)containerView numberOfPieces:(NSInteger)numberOfPieces animationDuration:(NSTimeInterval)duration
{
    self.duration = duration;
    self.elapsedTime = 0.f;
    [self setupGL];
    self.animationView = [[GLKView alloc] initWithFrame:view.frame context:self.context];
    self.animationView.delegate = self;
    self.mesh = [[ShredderFrontSceneMesh alloc] initWithXResolution:(GLuint)numberOfPieces yResolution:view.bounds.size.height screenWidth:view.bounds.size.width screenHeight:view.bounds.size.height];
    self.backMesh = [[ShredderBackSceneMesh alloc] initWithXResolution:(GLuint)numberOfPieces yResolution:view.bounds.size.height screenWidth:view.bounds.size.width screenHeight:view.bounds.size.height];
    [self setupTextureWithView:view];
    [containerView addSubview:self.animationView];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) update:(CADisplayLink *)displayLink
{
    self.elapsedTime += displayLink.duration;
    if (self.elapsedTime < self.duration) {
        shredderPosition = self.animationView.bounds.size.height * (self.elapsedTime / self.duration);
        [self.mesh updateWithPercent:(self.elapsedTime / self.duration)];
        [self.backMesh updateWithPercent:(self.elapsedTime / self.duration)];
        [self.animationView display];
    } else {
        shredderPosition = self.animationView.bounds.size.height;
        [self.mesh updateWithPercent:1];
        [self.backMesh updateWithPercent:1];
        [self.animationView display];
        [self.displayLink invalidate];
    }
}

@end

void OrthoM4x4(GLfloat *out, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far)
{
    out[0] = 2.f/(right-left); out[4] = 0.f; out[8] = 0.f; out[12] = -(right+left)/(right-left);
    out[1] = 0.f; out[5] = 2.f/(top-bottom); out[9] = 0.f; out[13] = -(top+bottom)/(top-bottom);
    out[2] = 0.f; out[6] = 0.f; out[10] = -2.f/(far-near); out[14] = -(far+near)/(far-near);
    out[3] = 0.f; out[7] = 0.f; out[11] = 0.f; out[15] = 1.f;
}