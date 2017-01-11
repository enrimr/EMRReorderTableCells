//
//  EMRReorderTableCells.h
//
//  Created by Enrique Ismael Mendoza Robaina on 26/8/15.
//  Copyright © 2015 Enrique Ismael Mendoza Robaina. All rights reserved.
//
//
//  IMPORTANT: element class have to implement a property called position
//

#import <Foundation/Foundation.h>

@interface EMRReorderTableCells : NSObject

@property (strong, nonatomic) NSMutableDictionary *temporalValues;

@property UITableView *tableView;
@property NSMutableArray *elements;
@property NSUInteger elementsOffset; // Difference between table elements and array of elements' length (Example of use: sidebar [5])
@property NSUInteger elementsOffsetInPixels; // Difference between table elements and array of elements' length (Example of use: sidebar [5]) in pixels
@property NSUInteger lastElementPositionPlusHeight;
@property (nonatomic) BOOL collapseSubElements;
@property (nonatomic, copy) void (^collapseCellsBlock)(id element);
@property (nonatomic, copy) void (^collapseSubCellsAtIndexPathBlock)(NSUInteger idx);
@property (nonatomic, copy) void (^removeSubElementsForElementBlock)(id element);
@property (nonatomic, copy) void (^removeSubElementsForElementAtIndexPathBlock)(NSIndexPath *indexPath);
@property (nonatomic, copy) BOOL (^areBrothersElements)(id source, id target);
@property (nonatomic, copy) BOOL (^isSubElementBlock)(id element);
@property (nonatomic, copy) BOOL (^isHidingSubElementsBlock)(id element);
@property (nonatomic, copy) void (^completionBlock)(id element);

@property (nonatomic, readonly) UILongPressGestureRecognizer *reorderGestureRecognizer;

- (id)initWithTableView:(UITableView *)aTableView
               elements:(NSMutableArray *)arrayOfElements
         elementsOffset:(NSUInteger)elementsOffset
    collapseSubElements:(BOOL)collapseSubElements
collapseSubCellsAtIndexPathBlock:(void (^)(NSUInteger idx))collapseSubCellsAtIndexPathBlock
removeSubElementsForElementBlock:(void (^)(id element))removeSubElementsForElementBlock
removeSubElementsForElementAtIndexPathBlock:(void (^)(NSIndexPath *indexPath))removeSubElementsForElementAtIndexPathBlock
    areBrothersElements:(BOOL (^)(id source, id target))areBrothersElements
      isSubElementBlock:(BOOL (^)(id element))isSubElementBlock
isHidingSubElementsBlock:(BOOL (^)(id element))isHidingSubElementsBlock
        completionBlock:(void (^)(id element))completionBlock;

- (id)initWithTableView:(UITableView *)aTableView
               elements:(NSMutableArray *)arrayOfElements
    collapseSubElements:(BOOL)collapseSubElements
collapseSubCellsAtIndexPathBlock:(void (^)(NSUInteger idx))collapseSubCellsAtIndexPathBlock
removeSubElementsForElementBlock:(void (^)(id element))removeSubElementsForElementBlock
removeSubElementsForElementAtIndexPathBlock:(void (^)(NSIndexPath *indexPath))removeSubElementsForElementAtIndexPathBlock
    areBrothersElements:(BOOL (^)(id source, id target))areBrothersElements
      isSubElementBlock:(BOOL (^)(id element))isSubElementBlock
isHidingSubElementsBlock:(BOOL (^)(id element))isHidingSubElementsBlock
        completionBlock:(void (^)(id element))completionBlock;

- (void) cancelReorder;

- (IBAction)longPressGestureRecognized:(id)sender;

@end
