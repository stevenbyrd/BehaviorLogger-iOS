//
//  BLMProjectDetailCollectionViewLayout.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


@class BLMCollectionView;


@interface BLMProjectDetailCollectionViewLayout : UICollectionViewLayout

@property (nullable, nonatomic, readonly) BLMCollectionView *collectionView;

@end
