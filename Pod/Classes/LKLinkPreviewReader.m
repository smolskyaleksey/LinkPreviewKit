//
//  LKLinkPreviewReader.m
//  LinkPreviewKit
//
//  Created by Andreas Kompanez on 13.04.15.
//  Copyright (c) 2015 Andreas Kompanez. All rights reserved.
//

#import "LKLinkPreviewReader.h"

#import "LKLinkPreview.h"
#import "LKLinkPreviewHTMLReader.h"
#import <HTMLReader/HTMLReader.h>
#import "NSString+Extension.h"
#import "LKTemplateLibrary.h"

NSString *const LKLinkPreviewKitErrorDomain = @"LKLinkPreviewKitErrorDomain";



@implementation LKLinkPreviewReader

+ (void)linkPreviewFromURL:(NSURL *)URL completionHandler:(LKLinkPreviewKitHandler)handler
{
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            if (handler) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    handler(nil, error);
                });
            }
        } else {
            NSString *responseURL = response.URL.absoluteString;
            if (responseURL.isImage) {
                LKTemplateLibrary *library = [LKTemplateLibrary new];
                LKLinkPreview *preview = [library fetchOrRegisterNewLinkPreviewByKind:LKTemplateKindStandard];
                [preview setContent:responseURL forProperty:@"image"];
                [preview setContent:responseURL forProperty:@"url"];
                if (handler) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        handler(@[preview], error);
                    });
                }
            } else {
                NSURL *finalResult = response.URL;
                NSString *contentType = nil;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
                    contentType = headers[@"Content-Type"];
                }
                HTMLDocument *document = [HTMLDocument documentWithData:data
                                                      contentTypeHeader:contentType];
                LKLinkPreviewHTMLReader *htmlReader = [LKLinkPreviewHTMLReader new];
                [htmlReader linkPreviewFromHTMLDocument:document completionHandler:^(NSArray *previews, NSError *error) {
                    if (finalResult != nil) {
                        [previews makeObjectsPerformSelector:@selector(setURL:) withObject:finalResult];
                    }
                    if (handler) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            handler(previews, error);
                        });
                    }
                }];
            }
        }
    }] resume];
}

@end


