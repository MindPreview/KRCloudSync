//
//  KRResourceFilter.m
//  CloudSync
//
//  Created by allting on 12. 11. 18..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRResourceFilter.h"

@implementation KRResourceFilter

-(NSPredicate*)createPredicate{
	return [NSPredicate predicateWithFormat:@"(%K like '*')", NSMetadataItemFSNameKey];
}

-(BOOL)shouldPass:(NSString*)path{
	return YES;
}

@end

@implementation KRResourceExtensionFilter
-(id)initWithFilters:(NSArray*)filters{
	self = [super init];
	if(self){
		self.filters = filters;
	}
	return self;
}

-(NSPredicate*)createPredicate{
	if(1 == [_filters count]){
		NSString* filter = [_filters objectAtIndex:0];
		return [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemFSNameKey, filter];
	}
	
	NSMutableArray* predicates = [NSMutableArray arrayWithCapacity:[_filters count]];
	
	for(NSString* filter in _filters){
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemFSNameKey, filter];
		[predicates addObject:predicate];
	}
	
	return [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
}

-(BOOL)shouldPass:(NSString*)path{
	NSString* ext = [path pathExtension];
	
	for(NSString* filter in _filters){
		if([filter isEqualToString:ext])
			return YES;
	}
	return NO;
}

@end