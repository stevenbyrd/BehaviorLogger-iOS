//
//  BLMCollectionViewCell.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol BLMCollectionViewCellIndexing

- (NSIndexPath *)cellIndexPath;

@end


@interface BLMCollectionViewCell : UICollectionViewCell <BLMCollectionViewCellIndexing>

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger item;

- (void)updateContent;

@end
