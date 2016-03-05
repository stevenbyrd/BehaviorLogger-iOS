//
//  BLMCollectionViewCell.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionViewCell.h"
#import "BLMViewUtils.h"


@implementation BLMCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    [self resetIndexPathState];

    return self;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    [self resetIndexPathState];
}


- (void)resetIndexPathState {
    self.section = NSNotFound;
    self.item = NSNotFound;
}


- (void)updateContent {
    assert([NSThread isMainThread]);
    assert(self.section != NSNotFound);
    assert(self.item != NSNotFound);
}

@end
