//
//  BLMCollectionView.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 ` ### Anatomy of UICollectionView Sections
 `
 ` Header Origin -> *--------------------------* <- Section Width
 `                  |          Header          |
 ` Header Height -> *--------------------------*
 `                  |                          |
 `                  |   *..................*   |
 `                  |   .    Item Area     .   |
 `                  |   .   ............   .   |
 `                  |   .   .          .   .   |
 `                  |   .   .   Item   .   .   |
 `                  |   .   .   Grid   .   .   |
 `                  |   .   .          .   .   |
 `                  |   .   .          .   .   |
 `                  |   .   ............   .   |
 `                  |   .[Item Grid Insets].   |
 `                  |   *..................*   |
 `                  |  [Content Area Insets]   |
 ` Footer Origin -> *--------------------------*
 `                  |          Footer          |
 ` Footer Height -> *--------------------------* <- Section Height
 `
 */


#pragma mark Constants

typedef struct BLMCollectionViewBasicLayout {
    CGFloat const Height;
    UIEdgeInsets const Insets;
} BLMCollectionViewBasicLayout;


typedef struct BLMCollectionViewGridLayout {
    NSInteger const ColumnCount;
    CGFloat const ColumnSpacing;
    CGFloat const RowSpacing;
    CGFloat const RowHeight;
    UIEdgeInsets const Insets;
} BLMCollectionViewGridLayout;


typedef struct BLMCollectionViewItemAreaLayout {
    BOOL const HasBackground;
    UIEdgeInsets const Insets;
    BLMCollectionViewGridLayout const Grid;
} BLMCollectionViewItemAreaLayout;


typedef struct BLMCollectionViewSectionLayout {
    BLMCollectionViewBasicLayout const Header;
    BLMCollectionViewItemAreaLayout const ItemArea;
    BLMCollectionViewBasicLayout const Footer;
} BLMCollectionViewSectionLayout;


extern BLMCollectionViewSectionLayout const BLMCollectionViewSectionLayoutNull;


extern NSString * _Nonnull const BLMCollectionViewKindHeader;
extern NSString * _Nonnull const BLMCollectionViewKindItemAreaBackground;
extern NSString * _Nonnull const BLMCollectionViewKindItemCell;
extern NSString * _Nonnull const BLMCollectionViewKindFooter;


extern CGFloat const BLMCollectionViewRoundedCornerRadius;


#pragma mark

@interface BLMSectionHeaderView : UICollectionReusableView

@property (nonnull, nonatomic, strong, readonly) UILabel *label;

@end


#pragma mark

@interface BLMItemAreaBackgroundView : UICollectionReusableView

@end


#pragma mark

@interface BLMSectionSeparatorFooterView : UICollectionReusableView

@end


#pragma mark

@protocol BLMCollectionViewCellLayoutDelegate <NSObject>

- (nonnull NSArray<NSLayoutConstraint *> *)uniqueVerticalPositionConstraintsForSubview:(nonnull UIView *)subview;
- (nonnull NSArray<NSLayoutConstraint *> *)uniqueHorizontalPositionConstraintsForSubview:(nonnull UIView *)subview;

@end


#pragma mark

@interface BLMCollectionViewCell : UICollectionViewCell <BLMCollectionViewCellLayoutDelegate>

@property (nonnull, nonatomic, strong, readonly) UILabel *label;
@property (nonnull, nonatomic, strong, readonly) NSIndexPath *indexPath;

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger item;

- (void)updateContent;
- (void)configureLabelSubviewsPreferredMaxLayoutWidth;

+ (nonnull UIColor *)errorColor;

@end


#pragma mark

@class BLMCollectionView;


@protocol BLMCollectionViewLayoutDelegate <UICollectionViewDelegate>

- (BLMCollectionViewSectionLayout)collectionView:(nonnull BLMCollectionView *)collectionView layoutForSection:(NSUInteger)section;

@end


#pragma mark

@interface BLMCollectionView : UICollectionView

@property (nullable, nonatomic, weak) id<BLMCollectionViewLayoutDelegate> delegate;

@end


#pragma mark

@interface BLMCollectionViewLayout : UICollectionViewLayout

@property (nullable, nonatomic, readonly) BLMCollectionView *collectionView;

@end
