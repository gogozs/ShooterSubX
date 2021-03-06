//
//  SZTableViewDropperView.m
//  ShooterSubX
//
//  Created by Song Zhou on 6/1/14.
//  Copyright (c) 2014 SongZhou. All rights reserved.
//

#import "SZTableViewDropperView.h"

@implementation SZTableViewDropperView {
    BOOL highlight;
}

- (void)awakeFromNib {
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
	[self setAllowsMultipleSelection:YES];
	
	//Add sortDescriptor for each col.The first sort descript is for filename sorting, the second one is for filesize sorting
	NSSortDescriptor *filenameSortDescriptor=[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES];
	NSSortDescriptor *filesizeSortDescriptor=[NSSortDescriptor sortDescriptorWithKey:@"fileBytes" ascending:YES];
	
	[[self.tableColumns objectAtIndex:0] setSortDescriptorPrototype:filenameSortDescriptor];
	[[self.tableColumns objectAtIndex:1] setSortDescriptorPrototype:filesizeSortDescriptor];
	
	//do not allow col selecting, but users can resize col for each col
	[self setAllowsColumnSelection:NO];
	[self setAllowsColumnResizing:YES];
	
}

// Stop the NSTableView implementation geeting in the way.
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    return [self draggingEntered:sender];
}

#pragma mark -- traverse directory
-(NSMutableArray *) getAllFilenameIn:(NSMutableArray *) pasteFilenames
{
    // Acceptable video extention names.
    NSArray *vExt = [NSArray arrayWithObjects:@"MKV", @"MOV", @"MP4", @"RMVB", @"AVI", @"MPEG", @"MPG",@"TS", nil];
    
	NSMutableArray *filenames =[[NSMutableArray alloc] init];
	for (int i=0;i<[pasteFilenames count];i++)
	{
		BOOL isDir = NO;
		//Could not find this directory or files,just pass this item
		if (![[NSFileManager defaultManager] fileExistsAtPath:[pasteFilenames objectAtIndex:i] isDirectory:&isDir]) continue;
		if (isDir)
		{
			//if the filename[i] points to a directory
			NSError *fileLoadingError;
			NSArray *contentOfFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[pasteFilenames objectAtIndex:i] error:&fileLoadingError];
			if (fileLoadingError)
			{
				//if something wrong with loading the file or directory
				NSLog(@"Can't load the next level at %@",[pasteFilenames objectAtIndex:i]);
				continue;
			}
			//traverse the nextlayer of the current directory
			for (int j=0;j<[contentOfFolder count];j++)
			{
				BOOL isSubDir = NO;
				NSString *nextLayerFilename=[[pasteFilenames objectAtIndex:i] stringByAppendingPathComponent:[contentOfFolder objectAtIndex:j]];
				[[NSFileManager defaultManager] fileExistsAtPath:nextLayerFilename isDirectory:&isSubDir];
				if (isSubDir)
				{
					//if the program find another directory, add it to the pasteFilename array so we can deal with the directory recursively
					[pasteFilenames addObject:nextLayerFilename];
				}
				else
				{
					//if this nextLayerFilename is a file, just add it to the result filename array
                    // If the file's extension is qualified to the definition of video.
                    ([vExt containsObject:[[nextLayerFilename pathExtension] uppercaseString]])?
					[filenames addObject:nextLayerFilename]:
                    NSLog(@"Not acceptable video extention: %@", [nextLayerFilename pathExtension]);
                    
				}
			}
		}
		else
		{
			//if the original filenamep[i] is a file, just add it to the result filename array
            // If the file's extension is qualified to the definition of video.
            ([vExt containsObject:[[[pasteFilenames objectAtIndex:i] pathExtension] uppercaseString]])?
              [filenames addObject:[pasteFilenames objectAtIndex:i]]:
            NSLog(@"Not acceptable video extention: %@", [[pasteFilenames objectAtIndex:i] pathExtension]);
           
		}
	}
	return filenames;
}



#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSLog(@"performDragOperation in SZTableViewDropper.h");
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSMutableArray *pasteFilenames = [pboard propertyListForType:NSFilenamesPboardType];
    NSMutableArray *filenames =[self getAllFilenameIn:pasteFilenames];
	
    id delegate = [self delegate];
    
    if ([delegate respondsToSelector:@selector(fileStuff:)]) {
        [delegate performSelector:@selector (fileStuff:) withObject:filenames];
    }
    
    highlight = NO;
    [self setNeedsDisplay: YES];
    
    return YES;
}

- (BOOL)prepareForDragOperation:(id)sender {
    NSLog(@"prepareForDragOperation called in TableViewDropper.h");
    return YES;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if (highlight == NO) {
        NSLog(@"drag enterd in SZTableViewDropper.h");
        highlight = YES;
        [self setNeedsDisplay: YES];
    }
    
    return NSDragOperationCopy;
}

- (void)draggingExited:(id)sender {
    highlight = NO;
    
    [self setNeedsDisplay: YES];
    NSLog(@"drag exit in SZTableViewDropper.h");
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    if (highlight) {
        // highlight by oberlaying a gray border.
        [[NSColor colorWithCalibratedRed:0.226 green:0.6041 blue:0.8 alpha:0.5] set];
        [NSBezierPath setDefaultLineWidth: 6];
        [NSBezierPath strokeRect: dirtyRect];
    }
}

@end
