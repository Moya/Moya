//
//  OHPathHelpers.m
//  Pods
//
//  Created by Olivier Halligon on 18/04/2015.
//
//

#import "OHPathHelpers.h"

NSString* OHPathForFile(NSString* fileName, Class inBundleForClass)
{
    NSBundle* bundle = [NSBundle bundleForClass:inBundleForClass];
    return OHPathForFileInBundle(fileName, bundle);
}

NSString* OHPathForFileInBundle(NSString* fileName, NSBundle* bundle)
{
    return [bundle pathForResource:[fileName stringByDeletingPathExtension]
                            ofType:[fileName pathExtension]];
}

NSString* OHPathForFileInDocumentsDir(NSString* fileName)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = (paths.count > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:fileName];
}

NSBundle* OHResourceBundle(NSString* bundleBasename, Class inBundleForClass)
{
    NSBundle* classBundle = [NSBundle bundleForClass:inBundleForClass];
    return [NSBundle bundleWithPath:[classBundle pathForResource:bundleBasename
                                                         ofType:@"bundle"]];
}