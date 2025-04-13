// GMICWrapper.h - pure Objective-C header
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GMIC : NSObject

- (instancetype)init;

// Existing methods
- (BOOL)runCommands:(NSString *)commands
		  inputPath:(NSString *)inputPath
		 outputPath:(NSString *)outputPath
			  error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)runCommands:(NSString *)commands
		  inputPath:(NSString *)inputPath
		 outputPath:(NSString *)outputPath
			  error:(NSError * _Nullable * _Nullable)error;

// New methods for executing arbitrary G'MIC commands
- (BOOL)executeScript:(NSString *)script
				error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)executeScript:(NSString *)script
				error:(NSError * _Nullable * _Nullable)error;

// Advanced method for working directly with image data
- (BOOL)executeScript:(NSString *)script
			imageList:(NSArray<NSData *> * _Nullable)inputImages
		 outputImages:(NSArray<NSData *> * _Nullable * _Nullable)outputImages
				error:(NSError * _Nullable * _Nullable)error;

//- (void)launchQT:(NSString *)inputPath;

@end

NS_ASSUME_NONNULL_END
