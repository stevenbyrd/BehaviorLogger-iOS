//
//  BLMCollectionViewCell.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BLMCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger item;

- (void)updateContent;

@end
