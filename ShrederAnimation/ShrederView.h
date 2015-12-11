//
//  ShrederView.h
//  ShrederAnimation
//
//  Created by Huang Hongsen on 15/11/29.
//  Copyright © 2015年 cn.daniel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShrederView : UIView
- (void) startShreddering;
- (instancetype) initWithFrame:(CGRect)frame horizontalResolution:(NSUInteger)horizontalResolution verticalResolution:(NSUInteger)verticalResolution;
@end
