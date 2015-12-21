//
//  ShredderRenderer.m
//  ShrederAnimation
//
//  Created by Huang Hongsen on 15/12/3.
//  Copyright © 2015年 cn.daniel. All rights reserved.
//

#import "ShredderRenderer.h"
//#import "ShredderFrontSceneMesh.h"
#import "OpenGLHelper.h"
//#import "ShredderBackSceneMesh.h"
#import "ShredderPaperPieceSceneMesh.h"
#import "ShredderPaperBackPieceSceneMesh.h"
#import "ConfettiSceneMesh.h"
#import <OpenGLES/ES3/glext.h>
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
    GLuint columnWidthLoc;
    GLfloat columnWidth;
    
    GLuint confettiProgram;
    GLuint confettiMvpLoc;
    GLuint confettiSamplerLoc;
    GLuint confettiShredderPositionLoc;
    GLuint confettiFallingDistanceLoc;
}
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKView *animationView;
@property (nonatomic, strong) NSMutableArray *frontMeshes;
@property (nonatomic, strong) NSMutableArray *backMeshes;
@property (nonatomic, strong) NSMutableArray *confettiMeshes;
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
    columnWidthLoc = glGetUniformLocation(backProgram, "u_columnWidth");
    
    confettiProgram = [OpenGLHelper loadProgramWithVertexShaderSrc:@"ShredderConfettiVertex.glsl" fragmentShaderSrc:@"ShredderConfettiFragment.glsl"];
    glUseProgram(confettiProgram);
    confettiMvpLoc = glGetUniformLocation(confettiProgram, "u_mvpMatrix");
    confettiSamplerLoc = glGetUniformLocation(confettiProgram, "s_tex");
    confettiShredderPositionLoc = glGetUniformLocation(confettiProgram, "u_shredderPosition");
    confettiFallingDistanceLoc = glGetUniformLocation(confettiProgram, "u_fallingDistance");
    
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
    
    glUseProgram(backProgram);
    glUniformMatrix4fv(backMvpLoc, 1, GL_FALSE, mvp.m);
    glUniform1f(backShredderPotisionLoc, shredderPosition);
    glUniform1f(columnWidthLoc, columnWidth);
    for (ShredderPaperPieceSceneMesh *mesh in self.backMeshes) {
        glBindVertexArray([mesh vertexArrayObject]);
        glActiveTexture(GL_TEXTURE0);
        glUniform1i(samplerLoc, 0);
        [mesh drawEntireMesh];
        glBindVertexArray(0);
    }

    glUseProgram(program);
    glUniformMatrix4fv(mvpLoc, 1, GL_FALSE, mvp.m);
    glUniform1f(shredderPositionLoc, shredderPosition);
    
    for (ShredderPaperPieceSceneMesh *mesh in self.frontMeshes) {
        glBindVertexArray([mesh vertexArrayObject]);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture);
        glUniform1i(samplerLoc, 0);
        [mesh drawEntireMesh];
        glBindVertexArray(0);
    }

    glUseProgram(confettiProgram);
    glUniformMatrix4fv(confettiMvpLoc, 1, GL_FALSE, mvp.m);
    glUniform1f(confettiShredderPositionLoc, shredderPosition);
    for (ConfettiSceneMesh *mesh in self.confettiMeshes) {
        glBindVertexArray([mesh vertexArrayObject]);
        glUniform1f(confettiFallingDistanceLoc, [mesh fallingDistance]);
        glActiveTexture(GL_TEXTURE0);
        glUniform1i(confettiSamplerLoc, 0);
        [mesh drawEntireMesh];
        glBindVertexArray(0);
    }
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
    columnWidth = (GLfloat)view.bounds.size.width / numberOfPieces;
    self.animationView = [[GLKView alloc] initWithFrame:view.frame context:self.context];
    self.animationView.drawableMultisample = GLKViewDrawableMultisample4X;
    self.animationView.delegate = self;
    self.frontMeshes = [NSMutableArray array];
    self.backMeshes = [NSMutableArray array];
    self.confettiMeshes = [NSMutableArray array];
    for (int i = 0; i < numberOfPieces; i+=2) {
        ShredderPaperPieceSceneMesh *mesh = [[ShredderPaperPieceSceneMesh alloc] initWithScreenWidth:view.bounds.size.width screenHeight:view.bounds.size.height totalPieces:numberOfPieces index:i];
        [self.frontMeshes addObject:mesh];
        if (i != 0) {
            [self generateConfettiForPieceAtIndex:i screenWidth:view.bounds.size.width screenHeight:view.bounds.size.height numberOfPieces:numberOfPieces];
        }
    }
    for (int i = 1; i < numberOfPieces; i+=2) {
        ShredderPaperPieceSceneMesh *mesh = [[ShredderPaperBackPieceSceneMesh alloc] initWithScreenWidth:view.bounds.size.width screenHeight:view.bounds.size.height totalPieces:numberOfPieces index:i];
        [self.backMeshes addObject:mesh];
    }
    [self setupTextureWithView:view];
    [containerView addSubview:self.animationView];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) generateConfettiForPieceAtIndex:(NSInteger)index screenWidth:(size_t)screenWidth screenHeight:(size_t)screenHeight numberOfPieces:(NSInteger)numberOfPieces
{
    int numberOfConfetties = arc4random() % 5 + 2;
    for (int i = 0; i < numberOfConfetties; i++) {
        ConfettiSceneMesh *confettiMesh = [[ConfettiSceneMesh alloc] initWithScreenWidth:screenWidth screenHeight:screenHeight numberOfPieces:numberOfPieces index:index];
        [self.confettiMeshes addObject:confettiMesh];
    }
}

- (void) update:(CADisplayLink *)displayLink
{
    self.elapsedTime += displayLink.duration;
    if (self.elapsedTime < self.duration) {
        CGFloat percent = (self.elapsedTime / self.duration);
        shredderPosition = self.animationView.bounds.size.height * percent;
        [self updateMeshesWithPercent:percent timeInterval:displayLink.duration];
        [self.animationView display];
    } else {
        shredderPosition = self.animationView.bounds.size.height;
        [self updateMeshesWithPercent:1.f timeInterval:displayLink.duration];
        [self.animationView display];
        [self.displayLink invalidate];
    }
}

- (void) updateMeshesWithPercent:(CGFloat)percent timeInterval:(NSTimeInterval)timeInterval
{
    for (ShredderPaperPieceSceneMesh *mesh in self.frontMeshes) {
        [mesh updateWithPercentage:percent];
    }
    for (ShredderPaperPieceSceneMesh *mesh in self.backMeshes) {
        [mesh updateWithPercentage:percent];
    }
    for (ConfettiSceneMesh *mesh in self.confettiMeshes) {
        [mesh updateWithPercentage:percent timeInterval:timeInterval];
    }
}

@end