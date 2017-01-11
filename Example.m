[[EMRReorderTableCells alloc] initWithTableView:_taskTableView
                                                                elements:[_tasks objectAtIndex:0]
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


// With Cells offset.
[[EMRReorderTableCells alloc] initWithTableView:_taskTableView
                                                                elements:[_tasks objectAtIndex:0]
                                                                elementsOffset:4
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