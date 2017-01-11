//
//  EMRReorderTableCells.m
//
//  Created by Enrique Ismael Mendoza Robaina on 26/8/15.
//  Copyright © 2015 Enrique Ismael Mendoza Robaina. All rights reserved.
//

#import "EMRReorderTableCells.h"

@implementation EMRReorderTableCells{
    
    CADisplayLink *_scrollDisplayLink;
    CGFloat _scrollRate;
    UIView *snapshot; // A snapshot of the row user is moving.
    NSIndexPath *sourceIndexPath; // Initial index path, where gesture begins.
    NSIndexPath *lastBrotherIndexPath; // last valid brother index path
}

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
        completionBlock:(void (^)(id element))completionBlock {
    if (self = [super init]) {
        _tableView = aTableView;
        _elements = arrayOfElements;
        _elementsOffset = elementsOffset;
        _collapseSubElements = collapseSubElements;
        _collapseSubCellsAtIndexPathBlock = collapseSubCellsAtIndexPathBlock;
        _removeSubElementsForElementBlock = removeSubElementsForElementBlock;
        _removeSubElementsForElementAtIndexPathBlock = removeSubElementsForElementAtIndexPathBlock;
        _areBrothersElements = areBrothersElements;
        _isSubElementBlock = isSubElementBlock;
        _isHidingSubElementsBlock = isHidingSubElementsBlock;
        _completionBlock = completionBlock;
        
        _reorderGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                                   initWithTarget:self action:@selector(longPressGestureRecognized:)];
        
        [_tableView addGestureRecognizer:_reorderGestureRecognizer];
        
        UIView *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_elementsOffset inSection:0]];
        _elementsOffsetInPixels = cell.frame.origin.y;
        
        _lastElementPositionPlusHeight = [self lastElementPixelPositionPlusHeight];
    }
    
    return self;
}

- (id)initWithTableView:(UITableView *)aTableView
               elements:(NSMutableArray *)arrayOfElements
    collapseSubElements:(BOOL)collapseSubElements
collapseSubCellsAtIndexPathBlock:(void (^)(NSUInteger idx))collapseSubCellsAtIndexPathBlock
removeSubElementsForElementBlock:(void (^)(id element))removeSubElementsForElementBlock
removeSubElementsForElementAtIndexPathBlock:(void (^)(NSIndexPath *indexPath))removeSubElementsForElementAtIndexPathBlock
    areBrothersElements:(BOOL (^)(id source, id target))areBrothersElements
      isSubElementBlock:(BOOL (^)(id element))isSubElementBlock
isHidingSubElementsBlock:(BOOL (^)(id element))isHidingSubElementsBlock
        completionBlock:(void (^)(id element))completionBlock {
    return [self initWithTableView:aTableView
                          elements:arrayOfElements
                    elementsOffset:0
               collapseSubElements:collapseSubElements
  collapseSubCellsAtIndexPathBlock:collapseSubCellsAtIndexPathBlock
  removeSubElementsForElementBlock:removeSubElementsForElementBlock
removeSubElementsForElementAtIndexPathBlock:removeSubElementsForElementAtIndexPathBlock
               areBrothersElements:areBrothersElements
                 isSubElementBlock:isSubElementBlock
          isHidingSubElementsBlock:isHidingSubElementsBlock
                   completionBlock:completionBlock];
}

-(void) cancelReorder{
    [_tableView removeGestureRecognizer:_reorderGestureRecognizer];
}

-(void) gestureRecognizerCancel:(UIGestureRecognizer *) gestureRecognizer
{ // See: http://stackoverflow.com/a/4167471/143378
    gestureRecognizer.enabled = NO;
    gestureRecognizer.enabled = YES;
}

- (IBAction)longPressGestureRecognized:(id)sender {
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    _reorderGestureRecognizer = (UILongPressGestureRecognizer *)sender;
    
    CGPoint location = [_reorderGestureRecognizer locationInView:_tableView];
    NSIndexPath *indexPath = [self getCellIndexPathWithPoint:location];
    //static UIView *snapshot;        ///< A snapshot of the row user is moving.
    //static NSIndexPath *sourceIndexPath; ///< Initial index path, where gesture begins.
    
    UIGestureRecognizerState state = _reorderGestureRecognizer.state;
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            NSLog(@"UIGestureRecognizerStateBegan");

            [appDelegate stopTimer];
            
            // Inicializamos como primer hermano a él mismo
            lastBrotherIndexPath = indexPath;
            
            //const CGPoint location = [_reorderGestureRecognizer locationInView:_tableView];
            NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:location];
            if (indexPath == nil)// || ![_tableView canMoveRowAtIndexPath:indexPath])
            {
                [self gestureRecognizerCancel:_reorderGestureRecognizer];
                break;
            }
            
            // For scrolling while dragging
            _scrollDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollTableWithCell:)];
            [_scrollDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            
            // Check for the right indexes (between margins of offset
            if (indexPath.row >=_elementsOffset && indexPath.row < [_elements count]+_elementsOffset){
                NSLog(@"Índice correcto");
                if (indexPath) {
                    sourceIndexPath = indexPath;
                    
                    id sourceElement = [_elements objectAtIndex:sourceIndexPath.row-_elementsOffset];
                    NSLog(@"superElement: | state[%ld], indexpath.row: %@, actualPosition: %@", (long)state, @(indexPath.row), [sourceElement valueForKey:@"position"]);
                    
                    if (_collapseSubElements){
                        if (!_isSubElementBlock(sourceElement)){
                            [self collapseAllElementsWithSubelements];
                            sourceIndexPath = indexPath = [NSIndexPath indexPathForRow:[_elements indexOfObjectIdenticalTo:sourceElement]+_elementsOffset inSection:0];
                        }
                    }
                    snapshot = [self createSnapshotForCellAtIndexPath:indexPath withPosition:location];
                }
            } else {
                sourceIndexPath = nil;
                snapshot = nil;
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            
            [self calculateScroll:_reorderGestureRecognizer];
            
            if (sourceIndexPath != nil && indexPath.row >=_elementsOffset && indexPath.row < [_elements count]+_elementsOffset){
                [self updateSnapshotWithPosition:location];
                
                // Is destination valid and is it different from source?
                if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                    if (indexPath.row - sourceIndexPath.row <= 1){
                        
                        /*//scrollViewWillEndDragging:withVelocity:targetContentOffset:
                        NSArray *indexVisibles = [_tableView indexPathsForVisibleRows];
                        NSInteger indexForObject = [indexVisibles indexOfObject:indexPath];
                        NSLog(@"%ld", (long)indexForObject);
                        
                        NSLog(@"CONTENT OFFSET : %f - %f",_tableView.contentOffset.x, _tableView.contentOffset.y);
                        if (indexForObject == 0 && indexPath.row > 0){
                            [UIView animateWithDuration:0.2
                                             animations:^{
                                                 [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:0]
                                                                            atScrollPosition:UITableViewScrollPositionMiddle
                                                                                    animated:NO];
                                             }
                                             completion:^(BOOL finished){ }];
                            
                        }*/
                        
                        id sourceElement = [_elements objectAtIndex:sourceIndexPath.row-_elementsOffset];
                        id targetElement = [_elements objectAtIndex:indexPath.row-_elementsOffset];
                        NSLog(@"UIGestureRecognizerStateChanged: %ld - %ld -  %@", (long)indexPath.row, (long)sourceIndexPath.row, [sourceElement valueForKey:@"position"]);
                        
                        // Solamente se pueden mover tareas dentro del mismo nivel
                        if (_areBrothersElements(sourceElement, targetElement)){
                            
                            //[self exchangeElement:sourceElement byElement:targetElement];
                            
                            // ... and update source so it is in sync with UI changes.
                            sourceIndexPath = [self exchangeElement:sourceElement byElement:targetElement];
                            lastBrotherIndexPath = indexPath;
                            NSLog(@"BRO %ld - %ld",(long)sourceIndexPath.row, (long)lastBrotherIndexPath.row);
                        }
                    }
                    
                }
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        {
            NSLog(@"UIGestureRecognizerStateEnded");
            
            // For scrolling while dragging
            [_scrollDisplayLink invalidate];
            _scrollDisplayLink = nil;
            _scrollRate = 0;
            
            // Check if it is the last element
            if (sourceIndexPath != nil){
                id element;
                if (sourceIndexPath.row <=_elementsOffset){
                    element = [_elements firstObject];
                } else if (sourceIndexPath.row > [_elements count]-1+_elementsOffset){
                    element = [_elements lastObject];
                } else {
                    element = [_elements objectAtIndex:sourceIndexPath.row-_elementsOffset];
                }
                NSLog(@"httpClient: element: indexpath.row: %@, editedposition: %@", @(sourceIndexPath.row), [element valueForKey:@"position"]);
                _completionBlock(element);
                
            }

        }
            
        default: {
            // Clean up.
            [self deleteSnapshotForRowAtIndexPath:sourceIndexPath];
            
            [appDelegate startTimer];
            
            break;
        }
    }
}

#pragma mark - Helper methods

// Get the indexPath for cell you are moving
- (NSIndexPath *) getCellIndexPathWithPoint:(CGPoint)point{
    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:point];
    
    // Check if the pointer is bigger than the table height to set indexPath as the last cell
    if (_tableView.contentSize.height<point.y) {
        indexPath = [NSIndexPath indexPathForRow:[_tableView numberOfRowsInSection:0]-1 inSection:0];
    }
    
    return indexPath;
}

/** @brief Returns a customized snapshot of a given view. */
- (UIView *)customSnapshoFromView:(UIView *)inputView {
    
    // Make an image from the input view.
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Create an image view.
    snapshot = [[UIImageView alloc] initWithImage:image];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}

- (void) collapseAllElementsWithSubelements{
    //NSMutableArray *elementToRemove = [[NSMutableArray alloc] init];
    NSMutableArray *indexPathToRemove = [[NSMutableArray alloc] init];
    
    __block NSUInteger removedElementsCount = 0;
    // Get the elements not collapsed
    [_elements enumerateObjectsUsingBlock:^(id  __nonnull obj, NSUInteger idx, BOOL * __nonnull stop) {
        if (_isHidingSubElementsBlock(obj)){
            //_collapseSubCellsAtIndexPathBlock(idx+_elementsOffset);
            //[elementToRemove addObject:obj];
            [indexPathToRemove addObject:[NSIndexPath indexPathForRow:idx-removedElementsCount+_elementsOffset inSection:0]];
        } else if (_isSubElementBlock(obj)){
            removedElementsCount++;
        }
    }];
    
    /*[elementToRemove enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        _removeSubElementsForElementBlock(obj);
    }];
    [_tableView reloadData];*/
    
    [indexPathToRemove enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        _removeSubElementsForElementAtIndexPathBlock(obj);
    }];
}


-(UIView *)createSnapshotForCellAtIndexPath:(NSIndexPath *)indexPath withPosition:(CGPoint)location{
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    
    // Take a snapshot of the selected row using helper method.
    snapshot = [self customSnapshoFromView:cell];
    
    // Add the snapshot as subview, centered at cell's center...
    __block CGPoint center = cell.center;
    snapshot.center = center;
    snapshot.alpha = 0.0;
    
    [_tableView addSubview:snapshot];
    [UIView animateWithDuration:0.25 animations:^{
        
        // Offset for gesture location.
        center.y = location.y;
        snapshot.center = center;
        snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
        snapshot.alpha = 0.98;
        cell.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        cell.hidden = YES;
    }];
    
    return snapshot;
}

-(void)updateSnapshotWithPosition:(CGPoint)location{
    CGPoint center = snapshot.center;
    center.y = location.y;
    snapshot.center = center;
}

-(void)deleteSnapshotForRowAtIndexPath:(NSIndexPath *)sourceIndexPath{
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:sourceIndexPath];
    cell.hidden = NO;
    cell.alpha = 0.0;
    
    [UIView animateWithDuration:0.25 animations:^{
        
        snapshot.center = cell.center;
        snapshot.transform = CGAffineTransformIdentity;
        snapshot.alpha = 0.0;
        cell.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        //sourceIndexPath = nil;
        [snapshot removeFromSuperview];
        //snapshot = nil;
        
    }];
}

-(NSIndexPath *)exchangeElement:(id)sourceElement byElement:(id)targetElement{
    
    NSUInteger sourcePosition = [_elements indexOfObject:sourceElement]+_elementsOffset;
    NSUInteger targetPosition = [_elements indexOfObject:targetElement]+_elementsOffset;
    
    // ... update element position
    NSNumber *sourceElementPosition = [sourceElement valueForKey:@"position"];
    NSNumber *targetElementPosition = [targetElement valueForKey:@"position"];
    
    _temporalValues = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                       sourceElementPosition, @"position", nil];
    [targetElement updateWithValues: _temporalValues];
    
    _temporalValues = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                       targetElementPosition, @"position", nil];
    [sourceElement updateWithValues: _temporalValues];
    
    /*NSLog(@"targetPosition: %lu - elements: %u - array: %u",(unsigned long)targetPosition, [_elements count]-1,targetPosition-_elementsOffset+1);
    while (targetPosition-_elementsOffset<[_elements count]-1 && _isSubElementBlock([_elements objectAtIndex:targetPosition-_elementsOffset+1])){
        targetPosition++;
        NSLog(@"endPosition: %lu", (unsigned long)targetPosition);
    }*/
    
    // ... get elements index path
    NSIndexPath *sourceIndexPath = [NSIndexPath indexPathForRow:sourcePosition inSection:0];
    NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:targetPosition inSection:0];
    
    // ... update data source.
    [_elements exchangeObjectAtIndex:targetIndexPath.row-_elementsOffset withObjectAtIndex:sourceIndexPath.row-_elementsOffset];
    
    // ... move the rows.
    [_tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:targetIndexPath];
    
    sourcePosition = [_elements indexOfObject:sourceElement]+_elementsOffset;
    
    return [NSIndexPath indexPathForRow:sourcePosition inSection:0];
}

-(void)calculateScroll:(UIGestureRecognizer *)gestureRecognizer{
    
    const CGPoint location = [gestureRecognizer locationInView:_tableView];
    
    CGRect rect = _tableView.bounds;
    // adjust rect for content inset as we will use it below for calculating scroll zones
    rect.size.height -= _tableView.contentInset.top;
    
    //[self updateCurrentLocation:gestureRecognizer];
    
    // tell us if we should scroll and which direction
    CGFloat scrollZoneHeight = rect.size.height / 6;
    CGFloat bottomScrollBeginning = _tableView.contentOffset.y + _tableView.contentInset.top + rect.size.height - scrollZoneHeight;
    CGFloat topScrollBeginning = _tableView.contentOffset.y + _tableView.contentInset.top  + scrollZoneHeight;
    
    // we're in the bottom zone
    if (location.y >= bottomScrollBeginning)
    {
        _scrollRate = (location.y - bottomScrollBeginning) / scrollZoneHeight;
    }
    // we're in the top zone
    else if (location.y <= topScrollBeginning)
    {
        _scrollRate = (location.y - topScrollBeginning) / scrollZoneHeight;
    }
    else
    {
        _scrollRate = 0;
    }

}

- (void)scrollTableWithCell:(NSTimer *)timer
{
    UILongPressGestureRecognizer *gesture = _reorderGestureRecognizer;
    const CGPoint location = [gesture locationInView:_tableView];
    
    CGPoint currentOffset = _tableView.contentOffset;
    CGPoint newOffset = CGPointMake(currentOffset.x, currentOffset.y + _scrollRate * 10);
    
    if (newOffset.y < -_tableView.contentInset.top)
    {
        newOffset.y = -_tableView.contentInset.top;
    }
    else if (_tableView.contentSize.height + _tableView.contentInset.bottom < _tableView.frame.size.height)
    {
        newOffset = currentOffset;
    }
    else if (newOffset.y > (_tableView.contentSize.height + _tableView.contentInset.bottom) - _tableView.frame.size.height)
    {
        newOffset.y = (_tableView.contentSize.height + _tableView.contentInset.bottom) - _tableView.frame.size.height;
    }
    
    [_tableView setContentOffset:newOffset];
    
    if (location.y >= 0 && location.y <= _tableView.contentSize.height + 50)
    {
        //_reorderDragView.center = CGPointMake(_tableView.center.x, location.y);
        // draggingView.center = CGPointMake(_tableView.center.x, location.y);
        //NSLog(@" Location: %f", location.y);
        
        NSIndexPath *indexPath = [self getCellIndexPathWithPoint:location];
        
        // CHeck if element is between offset limits.
        if (![indexPath isEqual:sourceIndexPath] &&
            indexPath.row >= _elementsOffset &&
            indexPath.row - _elementsOffset < [_elements count] &&
            sourceIndexPath.row >= _elementsOffset &&
            sourceIndexPath.row - _elementsOffset < [_elements count]){
            NSLog(@" Row: %ld", (long)indexPath.row);
            id sourceElement = [_elements objectAtIndex:sourceIndexPath.row-_elementsOffset];
            id targetElement = [_elements objectAtIndex:indexPath.row-_elementsOffset];
            //[self exchangeElement:sourceElement byElement:targetElement];
            // Solamente se pueden mover tareas dentro del mismo nivel
            if (_areBrothersElements(sourceElement, targetElement)){
                [self updateSnapshotWithPosition:location];

                //[self exchangeElement:sourceElement byElement:targetElement];
                
                // ... and update source so it is in sync with UI changes.
                sourceIndexPath = [self exchangeElement:sourceElement byElement:targetElement];
                lastBrotherIndexPath = indexPath;
                NSLog(@"BRO %ld - %ld",(long)sourceIndexPath.row, (long)lastBrotherIndexPath.row);
            } /*else {
                sourceIndexPath = indexPath
            }*/
        }
    }/*
    
    [self updateCurrentLocation:gesture];*/
    
    
}

- (NSUInteger)lastElementPixelPositionPlusHeight{
    UIView *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_elementsOffset+[_elements count] inSection:0]];
    return cell.frame.origin.y + cell.frame.size.height;
}

#pragma mark - Utils
    
- (BOOL)canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    return ![_tableView.dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)] || [_tableView.dataSource tableView:_tableView canMoveRowAtIndexPath:indexPath];
}

@end
