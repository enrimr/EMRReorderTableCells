This Objective-C class allows you to reorder cells in a UITableView. Each element in cells have to implement a property called "position".

You can use this to reorder simple elements or tables with subelements (i.e. tasks with subtasks)

Example of call:

     [[EMRReorderTableCells alloc] initWithTableView:_taskTableView
                                                                elements:[_tasks objectAtIndex:0]
                                                                elementsOffset:5
                                                     collapseSubElements:YES
                                        collapseSubCellsAtIndexPathBlock:^(NSUInteger idx) {
                                            // In case you have subelements
                                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                                            [self expandCollapseSubtasksAtIndexPath:indexPath];
                                        } removeSubElementsForElementBlock:^(id element) {
                                            [self removeSubtasksForTask:(Task *)element];
                                        } removeSubElementsForElementAtIndexPathBlock:^(NSIndexPath *indexPath) {
                                            [self removeSubtasksAtIndexPath:indexPath];
                                        } areBrothersElements:^BOOL(id source, id target) {
                                            return [(Task *)source isBrotherOfTask:(Task *)target];
                                        } isSubElementBlock:^BOOL(id element) {
                                            return ![[(Task *)element subtask] isEqualToString:@"0"];
                                        } isHidingSubElementsBlock:^BOOL(id element) {
                                            return [[(Task *)element hidesubtasks] isEqualToNumber:@0];
                                        } completionBlock:^(id element) {
                                            // Update element
                                            [_httpClient createUpdateRequestForObject:element withPath:@"task/" withRegeneration:NO];
                                            [_httpClient update:nil];
                                        }];

Params:
***elements***

NSArray with elements to reorder.

***elementsOffset***

Integer with an offset. Imagine a main menu where you have three main sections and a list of custom sections. If you want to allow only to reorder the custom sections, you have to specify an offset of 3. The first three cells will be locked.

***collapseSubElements***

Bool that specify if you want to collapse subelements or not
Blocks meaning:
***collapseSubCellsAtIndexPathBlock***

A block that implement the action of collapsing subelements' cells

***removeSubElementsForElementBlock***

A block that implement the action of removing subelements from the element list for a given element.

***removeSubElementsForElementAtIndexPathBlock***

A block that implement the action of removing subelements from the element list for a given index path.

***areBrothersElements***

A block that return true if both elements are brothers (they are in the same level) or false if they are father and son or cousins.

***isSubElementBlock***

A block that return true if element is a subelement and false if is a single element without children.

***isHidingSubElementsBlock***

A block that return true if element is a subelement and false if is a single element without children.

***completionBlock***

A block that perform and action after finishing the reorder.

**Example of blocks**
    -(void)expandCollapseSubtasksAtIndexPath:(NSIndexPath *)indexPath{
        NSLog(@"Row: %ld - Section: %ld", (long)indexPath.row, (long)indexPath.section);
        if (indexPath != nil)
        {
            Task *task = [[_tasks objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            TaskTitleCell *cell = (TaskTitleCell *)[_taskTableView cellForRowAtIndexPath:indexPath];
            UILabel *subtasksNumberLabel = (UILabel *)[cell viewWithTag:107];
            UIButton *subtasksButton = (UIButton *)[cell viewWithTag:108];
            
            NSMutableArray *subtasksIndexPaths = [[NSMutableArray alloc] init];
            
            NSDictionary *subtasksAndIndexesDictionary = [task getSubtasksIndexesInTaskCollection:[_tasks objectAtIndex:indexPath.section] ofList:task.list];
            //NSDictionary *subtasksAndIndexesDictionary = [task getSubtasksIndexesInTaskCollection:[_tasks objectAtIndex:indexPath.section] ofList:task.list filteredBy:(int)_selectedFilter];
            
            NSIndexSet *indexes = [subtasksAndIndexesDictionary objectForKey:@"indexes"];
            NSArray *subtasks = [subtasksAndIndexesDictionary objectForKey:@"subtasks"];
            
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                NSIndexPath *subtaskIndexPath = [NSIndexPath indexPathForRow:idx inSection:indexPath.section];
                [subtasksIndexPaths addObject:subtaskIndexPath];
            }];
            
            NSNumber *hidden;
            //Expand
            if (!subtasksButton.selected){
                hidden = @0;
                //[task setHidesubtasks:@0];
                subtasksNumberLabel.textColor = [UIColor colorWithRed:72.0/255.0 green:175.0/255.0 blue:237.0/255.0 alpha:1.0];
                
                [[_tasks objectAtIndex:indexPath.section] insertObjects:subtasks atIndexes:indexes];
                
                [_taskTableView insertRowsAtIndexPaths:subtasksIndexPaths withRowAnimation:UITableViewRowAnimationTop];
                
                //Collapse
            }else{
                hidden = @1;
                //[task setHidesubtasks:@1];
                subtasksNumberLabel.textColor = [UIColor whiteColor];
                
                NSArray *subtasks = [task getSubtasks];
                
                if (subtasks){
                    
                    [[_tasks objectAtIndex:indexPath.section] removeObjectsInArray:subtasks];
                    
                    [_taskTableView deleteRowsAtIndexPaths:subtasksIndexPaths withRowAnimation:UITableViewRowAnimationBottom];
                }
                
            }
            
            subtasksButton.selected = !subtasksButton.selected;
            //task.hidesubtasksValue = !subtasksButton.selected;
            task.hidesubtasks = hidden;
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        }
    }

    -(void)removeSubtasksForTask:(Task *)task{
            NSNumber *hidden = @1;
            
            NSArray *subtasks = [task getSubtasks];
        
            [_tasks removeObjectsInArray:subtasks];
            
            task.hidesubtasks = hidden;
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    }

    -(void)removeSubtasksAtIndexPath:(NSIndexPath *)indexPath{
        // TODO: arreglar el sort
        Task *task = [_tasks objectAtIndex:indexPath.row];
        TaskTitleCell *cell = (TaskTitleCell *)[_taskTableView cellForRowAtIndexPath:indexPath];
        UILabel *subtasksNumberLabel = (UILabel *)[cell viewWithTag:107];
        UIButton *subtasksButton = (UIButton *)[cell viewWithTag:108];
        
        NSMutableArray *subtasksIndexPaths = [[NSMutableArray alloc] init];
        NSNumber *hidden = @1;

        subtasksNumberLabel.textColor = [UIColor whiteColor];
        
        NSArray *subtasks = [task getSubtasks];
        
        [_tasks removeObjectsInArray:subtasks];
        
        for (int i=1;i<=subtasks.count; i++){
            NSIndexPath *subtaskIndexPath = [NSIndexPath indexPathForRow:indexPath.row+i inSection:0];
            [subtasksIndexPaths addObject:subtaskIndexPath];
        }
        
        [_taskTableView deleteRowsAtIndexPaths:subtasksIndexPaths withRowAnimation:UITableViewRowAnimationBottom];
        
        subtasksButton.selected = !subtasksButton.selected;
        task.hidesubtasks = hidden;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    }

*Documentation*


I have use some inspiration from https://github.com/hpique/HPReorderTableView

**A. Manage gestureRecognition**

***longPressGestureRecognized:***

    - (IBAction)longPressGestureRecognized:(id)sender {
        
        _reorderGestureRecognizer = (UILongPressGestureRecognizer *)sender;
        
        CGPoint location = [_reorderGestureRecognizer locationInView:_tableView];
        NSIndexPath *indexPath = [self getCellIndexPathWithPoint:location];
        
        UIGestureRecognizerState state = _reorderGestureRecognizer.state;
        switch (state) {
            case UIGestureRecognizerStateBegan: {
                
                NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:location];
                if (indexPath == nil)
                {
                    [self gestureRecognizerCancel:_reorderGestureRecognizer];
                    break;
                }
                
                // For scrolling while dragging
                _scrollDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollTableWithCell:)];
                [_scrollDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
                
                // Check for the right indexes (between margins of offset
                if (indexPath.row >=_elementsOffset && indexPath.row < [_elements count]+_elementsOffset){
    
                    if (indexPath) {
                        sourceIndexPath = indexPath;
                        
                        id sourceElement = [_elements objectAtIndex:sourceIndexPath.row-_elementsOffset];
    
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
                            
                            id sourceElement = [_elements objectAtIndex:sourceIndexPath.row-_elementsOffset];
                            id targetElement = [_elements objectAtIndex:indexPath.row-_elementsOffset];
                            
                            sourceIndexPath = [self exchangeElement:sourceElement byElement:targetElement];
                        }
                        
                    }
                }
                break;
            }
                
            case UIGestureRecognizerStateEnded:
            {
                // For scrolling while dragging
                [_scrollDisplayLink invalidate];
                _scrollDisplayLink = nil;
                _scrollRate = 0;
                
                
                // Check if it is the last element
                if (sourceIndexPath != nil){
                    id element;
                    if (indexPath.row <=_elementsOffset){
                        element = [_elements firstObject];
                    } else if (indexPath.row > [_elements count]-1+_elementsOffset){
                        element = [_elements lastObject];
                    } else {
                        element = [_elements objectAtIndex:indexPath.row-_elementsOffset];
                    }  
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


***gestureRecognizerCancel:***

It is use to cancel gesture recognition to finish the reorder action.

    -(void) gestureRecognizerCancel:(UIGestureRecognizer *) gestureRecognizer
    { // See: http://stackoverflow.com/a/4167471/143378
        gestureRecognizer.enabled = NO;
        gestureRecognizer.enabled = YES;
    }


***scrollTableWithCell:***

The method it is called to make scrolling movement when you are in the limits of the table (up and down)

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
    
            [self updateSnapshotWithPosition:location];
            NSIndexPath *indexPath = [self getCellIndexPathWithPoint:location];
            
            // CHeck if element is between offset limits.
            if (![indexPath isEqual:sourceIndexPath] &&
                indexPath.row >= _elementsOffset &&
                indexPath.row - _elementsOffset < [_elements count] &&
                sourceIndexPath.row >= _elementsOffset &&
                sourceIndexPath.row - _elementsOffset < [_elements count])
            {
                id sourceElement = [_elements objectAtIndex:sourceIndexPath.row-_elementsOffset];
                id targetElement = [_elements objectAtIndex:indexPath.row-_elementsOffset];
                [self exchangeElement:sourceElement byElement:targetElement];
                sourceIndexPath = indexPath;
            }
        }
    }

**B. Snapshot management**

***createSnapshotForCellAtIndexPath:withPosition***

Method that creates a snapshot (a image copy) of the cell you are moving

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

***customSnapshoFromView:***

Returns a customized snapshot of a given view. */

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

***updateSnapshotWithPosition:***

Given a CGPoint, it changes the snapshot position to show the cell you are moving in the right place of the _tableView

    -(void)updateSnapshotWithPosition:(CGPoint)location{
        CGPoint center = snapshot.center;
        center.y = location.y;
        snapshot.center = center;
    }

***deleteSnapshotForRowAtIndexPath:***

When dragging finishes, you need to delete the snapshot from the _tableView

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
            [snapshot removeFromSuperview];
        }];
    }
***calculateScroll***

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

**C. How to use it**

In your init method, assign a gesture recognizer to the table view. Assign as action the method `longPressGestureRecognized:` as follows:

        _reorderGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                                   initWithTarget:self action:@selector(longPressGestureRecognized:)];
        
        [_tableView addGestureRecognizer:_reorderGestureRecognizer];


Declare the variables you will need to use the above code explained

    @implementation YourClassName{
        
        CADisplayLink *_scrollDisplayLink;
        CGFloat _scrollRate;
        UIView *snapshot; // A snapshot of the row user is moving.
        NSIndexPath *sourceIndexPath; // Initial index path, where gesture begins.
    }
