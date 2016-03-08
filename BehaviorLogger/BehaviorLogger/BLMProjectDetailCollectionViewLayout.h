//
//  BLMProjectDetailCollectionViewLayout.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMProjectDetailController.h"


@class BLMProjectDetailCollectionViewLayout;


@protocol BLMProjectDetailCollectionViewLayoutDelegate <UICollectionViewDelegate>

- (BLMCollectionViewSectionLayout)projectDetailCollectionViewLayout:(BLMProjectDetailCollectionViewLayout *)layout layoutForSection:(BLMProjectDetailSection)section;

@end


#pragma mark

@interface BLMProjectDetailCollectionViewLayout : UICollectionViewLayout

@end
