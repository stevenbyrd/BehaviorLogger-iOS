//
//  BLMProjectDetailController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class BLMProject;


typedef NS_ENUM(NSUInteger, BLMProjectDetailSection) {
    BLMProjectDetailSectionBasicInfo,

    BLMProjectDetailSectionCount,
    
    BLMProjectDetailSectionSessionProperties,
    BLMProjectDetailSectionBehaviors,
    BLMProjectDetailSectionActionButtons,

};


typedef NS_ENUM(NSUInteger, BLMBasicInfoSectionItem) {
    BLMBasicInfoSectionItemProjectName,
    BLMBasicInfoSectionItemClientName,
    BLMBasicInfoSectionItemCount
};


typedef NS_ENUM(NSUInteger, BLMSessionPropertiesSectionItem) {
    BLMSessionPropertiesSectionItemCondition,
    BLMSessionPropertiesSectionItemLocation,
    BLMSessionPropertiesSectionItemTherapist,
    BLMSessionPropertiesSectionItemObserver,
    BLMSessionPropertiesSectionItemCount
};


typedef NS_ENUM(NSUInteger, BLMActionButtonsSectionItem) {
    BLMActionButtonsSectionItemCreateSession,
    BLMActionButtonsSectionItemViewPastSessions,
    BLMActionButtonsSectionItemDeleteProject,
    BLMActionButtonsSectionItemCount
};


#pragma mark

@interface BLMBasicInfoCell : UICollectionViewCell

@end


#pragma mark

@interface BLMSessionPropertyCell : UICollectionViewCell

@end


#pragma mark

@interface BLMBehaviorCell : UICollectionViewCell

@end


#pragma mark

@interface BLMAddBehaviorCell : UICollectionViewCell

@end


#pragma mark

@interface BLMActionButtonCell : UICollectionViewCell

@end


#pragma mark

@interface BLMSectionHeaderView : UICollectionReusableView

@property (nonatomic, strong, readonly) UILabel *label;

@end


#pragma mark

@interface BLMSectionFooterView : UICollectionReusableView

@end


#pragma mark

@interface BLMProjectDetailCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, assign, readonly) CGSize collectionViewContentSize;
@property (nonatomic, copy, readonly) NSMutableArray<NSValue *> *sectionFrameList;
@property (nonatomic, copy, readonly) NSMutableArray<NSMutableArray<NSIndexPath *> *> *sessionIndexPathList;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *itemAttributesByIndexPath;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *> *supplementaryViewAttributesByIndexPathByKind;

@end


#pragma mark

@interface BLMProjectDetailController : UIViewController

@property (nonatomic, strong, readonly) NSNumber *projectUid;

- (instancetype)initWithProject:(BLMProject *)project;

@end
