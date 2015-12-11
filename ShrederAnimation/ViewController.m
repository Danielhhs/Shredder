//
//  ViewController.m
//  ShrederAnimation
//
//  Created by Huang Hongsen on 15/11/29.
//  Copyright © 2015年 cn.daniel. All rights reserved.
//

#import "ViewController.h"
#import "ShredderRenderer.h"
@interface ViewController ()
@property (nonatomic, strong) ShredderRenderer *renderer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *image = [[UIImageView alloc] initWithFrame:self.view.bounds];
    image.image = [UIImage imageNamed:@"image.jpg"];
    
    self.renderer = [[ShredderRenderer alloc] init];
    [self.renderer startShredderingView:image inContainerView:self.view numberOfPieces:8 animationDuration:3];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
