//
//  ImageBrowse.h
//  Hospital
//
//  Created by FZX on 2018/9/27.
//  Copyright © 2018年 wangbao. All rights reserved.
//

#import "ZXModallyViewController.h"

@interface ImageBrowse : ZXModallyViewController
///images数组  UIImage  NSString  NSData
+ (instancetype)imageBrowseWithImages:(NSArray *)images index:(NSInteger)index;
@end
