//
//  BLMCollectionView.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


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

extern NSString *const BLMCollectionViewKindHeader;
extern NSString *const BLMCollectionViewKindItemAreaBackground;
extern NSString *const BLMCollectionViewKindItemCell;
extern NSString *const BLMCollectionViewKindFooter;


extern CGFloat const BLMCollectionViewRoundedCornerRadius;


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


#pragma mark

@interface BLMSectionHeaderView : UICollectionReusableView

@property (nonatomic, strong, readonly) UILabel *label;

@end


#pragma mark

@interface BLMItemAreaBackgroundView : UICollectionReusableView

@end


#pragma mark

@interface BLMSectionSeparatorFooterView : UICollectionReusableView

@end


#pragma mark

@class BLMCollectionViewCell;


@protocol BLMCollectionViewCellDataSource <NSObject>

- (NSString *)labelTextForCollectionViewCell:(BLMCollectionViewCell *)cell;

@optional
- (UIColor *)backgroundColorForCollectionViewCell:(BLMCollectionViewCell *)cell;

@end


@protocol BLMCollectionViewCellLayoutDelegate <NSObject>

- (NSArray<NSLayoutConstraint *> *)uniqueVerticalPositionConstraintsForSubview:(UIView *)subview;
- (NSArray<NSLayoutConstraint *> *)uniqueHorizontalPositionConstraintsForSubview:(UIView *)subview;

@end


#pragma mark

@interface BLMCollectionViewCell : UICollectionViewCell <BLMCollectionViewCellLayoutDelegate>

@property (nonatomic, weak) id<BLMCollectionViewCellDataSource> dataSource;
@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) NSIndexPath *indexPath;

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger item;

- (void)updateContent;
- (void)updateLabelSubviewsPreferredMaxLayoutWidthWithLayoutRequired:(BOOL *)layoutRequired;

+ (UIColor *)errorColor;

@end


#pragma mark

@class BLMCollectionView;


@protocol BLMCollectionViewLayoutDelegate <UICollectionViewDelegate>

- (BLMCollectionViewSectionLayout)collectionView:(BLMCollectionView *)collectionView layoutForSection:(NSUInteger)section;

@end


#pragma mark

@interface BLMCollectionView : UICollectionView

@property (nullable, nonatomic, weak) id<BLMCollectionViewLayoutDelegate> delegate;

@end


#pragma mark

@interface BLMCollectionViewLayout : UICollectionViewLayout

@property (nullable, nonatomic, readonly) BLMCollectionView *collectionView;

@end


NS_ASSUME_NONNULL_END
