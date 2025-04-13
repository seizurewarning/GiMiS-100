#import <Foundation/Foundation.h>
#import "include/GmicWrapper.h"

#define cimg_display 0
// Include C++ stuff in implementation ONLY
#include "gmic_internal/gmic.h"
#include <sstream>
#include <string>
#include <stdlib.h>

using namespace std;
using namespace gmic_library;

#ifdef __APPLE__
__attribute__((constructor))
static void disableXQuartz() {
	// Clear the DISPLAY environment variable so no X11 display is attempted.
	setenv("DISPLAY", "", 1);
}
#endif


@interface GMIC () {
	// Persistent G'MIC interpreter instance.
	gmic *_gmic;
}
@end

@implementation GMIC

+ (void)initialize {
	if (self == [GMIC class]) {
		try {
			// Initialize G'MIC resource folder and standard library.
			gmic::init_rc();
		} catch (const gmic_exception &e) {
			fprintf(stderr, "GMIC init_rc() failed: %s\n", e.what());
		}
	}
}

- (instancetype)init {
	self = [super init];
	if (self) {
		try {
			_gmic = new gmic();
		} catch (const gmic_exception &e) {
			NSLog(@"[GMICWrapper] Failed to initialize G'MIC interpreter: %s", e.what());
			return nil;
		}
	}
	return self;
}

- (void)dealloc {
	if (_gmic) {
		delete _gmic;
		_gmic = NULL;
	}
}

- (BOOL)runCommands:(NSString *)commands
		  inputPath:(NSString *)inputPath
		 outputPath:(NSString *)outputPath
			  error:(NSError * _Nullable * _Nullable)error
{
	// Convert NSString paths to C strings.
	const char *inPath = [inputPath fileSystemRepresentation];
	const char *outPath = [outputPath fileSystemRepresentation];
	const char *cmds = [commands UTF8String];
	
	// Build the complete command string.
	// Example: input "/path/to/input.jpg" blur 10,10 output "/path/to/output.png"
	string commandLine = "input \"";
	commandLine += inPath;
	commandLine += "\" ";
	commandLine += cmds;
	commandLine += " output \"";
	commandLine += outPath;
	commandLine += "\"";
	
	try {
		// Reset persistent interpreter state.
		_gmic->assign();
		
		// Use the list-based API instead of the templated run method
		gmic_list<float> images;
		gmic_list<char> image_names;
		_gmic->run(commandLine.c_str(), images, image_names);
	} catch (const gmic_exception &e) {
		if (error) {
			NSString *errMsg = [NSString stringWithUTF8String:e.what()];
			NSDictionary *info = @{ NSLocalizedDescriptionKey: errMsg };
			*error = [NSError errorWithDomain:@"GMICWrapperErrorDomain" code:-1 userInfo:info];
		}
		return NO;
	}
	
	return YES;
}

+ (BOOL)runCommands:(NSString *)commands
		  inputPath:(NSString *)inputPath
		 outputPath:(NSString *)outputPath
			  error:(NSError * _Nullable * _Nullable)error
{
	const char *inPath = [inputPath fileSystemRepresentation];
	const char *outPath = [outputPath fileSystemRepresentation];
	const char *cmds = [commands UTF8String];
	
	string commandLine = "input \"";
	commandLine += inPath;
	commandLine += "\" ";
	commandLine += cmds;
	commandLine += " output \"";
	commandLine += outPath;
	commandLine += "\"";
	
	try {
		// Use the list-based API for the class method too
		gmic_list<float> images;
		gmic_list<char> image_names;
		
		// Create a temporary G'MIC instance and use the non-template version of run
		gmic gmic_temp;
		gmic_temp.run(commandLine.c_str(), images, image_names);
	} catch (const gmic_exception &e) {
		if (error) {
			NSString *errMsg = [NSString stringWithUTF8String:e.what()];
			NSDictionary *info = @{ NSLocalizedDescriptionKey: errMsg };
			*error = [NSError errorWithDomain:@"GMICWrapperErrorDomain" code:-1 userInfo:info];
		}
		return NO;
	}
	
	return YES;
}

// New method to run arbitrary G'MIC scripts
- (BOOL)executeScript:(NSString *)script
				error:(NSError * _Nullable * _Nullable)error
{
	const char *scriptStr = [script UTF8String];
	
	try {
		// Reset persistent interpreter state
		_gmic->assign();
		
		// Create empty image lists for input/output
		gmic_list<float> images;
		gmic_list<char> image_names;
		
		// Run the script directly
		_gmic->run(scriptStr, images, image_names);
	} catch (const gmic_exception &e) {
		if (error) {
			NSString *errMsg = [NSString stringWithUTF8String:e.what()];
			NSDictionary *info = @{ NSLocalizedDescriptionKey: errMsg };
			*error = [NSError errorWithDomain:@"GMICWrapperErrorDomain" code:-1 userInfo:info];
		}
		return NO;
	}
	
	return YES;
}

// Class method to run arbitrary G'MIC scripts
+ (BOOL)executeScript:(NSString *)script
				error:(NSError * _Nullable * _Nullable)error
{
	const char *scriptStr = [script UTF8String];
	
	try {
		// Create empty image lists for input/output
		gmic_list<float> images;
		gmic_list<char> image_names;
		
		// Create a temporary G'MIC instance and run the script
		gmic gmic_temp;
		gmic_temp.run(scriptStr, images, image_names);
	} catch (const gmic_exception &e) {
		if (error) {
			NSString *errMsg = [NSString stringWithUTF8String:e.what()];
			NSDictionary *info = @{ NSLocalizedDescriptionKey: errMsg };
			*error = [NSError errorWithDomain:@"GMICWrapperErrorDomain" code:-1 userInfo:info];
		}
		return NO;
	}
	
	return YES;
}

// Advanced method to work with image data directly
- (BOOL)executeScript:(NSString *)script
			imageList:(NSArray<NSData *> *)inputImages
		 outputImages:(NSArray<NSData *> * _Nullable * _Nullable)outputImages
				error:(NSError * _Nullable * _Nullable)error
{
	const char *scriptStr = [script UTF8String];
	
	try {
		// Reset persistent interpreter state
		_gmic->assign();
		
		// Create image lists for input/output
		gmic_list<float> images;
		gmic_list<char> image_names;
		
		// If input images are provided, convert them to G'MIC format
		if (inputImages && inputImages.count > 0) {
			// Resize the list to match the number of input images
			images.assign((unsigned int)inputImages.count);
			
			// Convert each NSData object to a G'MIC image
			for (unsigned int i = 0; i < inputImages.count; ++i) {
				NSData *imageData = inputImages[i];
				
				// This is a simplified example - in a real implementation,
				// you'd need to parse the image data format (JPEG, PNG, etc.)
				// and convert it properly to float pixel values
				
				// Assuming RGBA format with known dimensions for simplicity
				// In real code, you'd detect dimensions from the image data
				unsigned int width = 320;   // Example width
				unsigned int height = 200;  // Example height
				unsigned int depth = 1;     // 2D image
				unsigned int spectrum = 4;  // RGBA
				
				// Allocate memory for the image
				gmic_image<float>& img = images[i];
				img.assign(width, height, depth, spectrum);
				
				// Copy pixel data (simplified - real code would do proper conversion)
				const unsigned char *srcPtr = (const unsigned char *)imageData.bytes;
				float *dstPtr = img;
				
				// Convert 8-bit values to float (0-255 -> 0.0-255.0)
				for (unsigned int j = 0; j < width * height * spectrum; ++j) {
					*(dstPtr++) = (float)*(srcPtr++);
				}
			}
		}
		
		// Run the script with our image list
		_gmic->run(scriptStr, images, image_names);
		
		// If the caller wants the output images, convert them back to NSData
		if (outputImages && images._width > 0) {
			NSMutableArray *resultImages = [NSMutableArray arrayWithCapacity:images._width];
			
			for (unsigned int i = 0; i < images._width; ++i) {
				gmic_image<float>& img = images[i];
				
				// Calculate the size of the output buffer (RGBA 8-bit)
				unsigned int pixelCount = img._width * img._height * img._depth * img._spectrum;
				unsigned int bufferSize = pixelCount * sizeof(unsigned char);
				
				// Create a buffer for the converted image data
				unsigned char *buffer = (unsigned char *)malloc(bufferSize);
				
				// Convert float values back to 8-bit (simplified)
				float *srcPtr = img;
				unsigned char *dstPtr = buffer;
				
				for (unsigned int j = 0; j < pixelCount; ++j) {
					// Clamp values to 0-255 range
					float val = *(srcPtr++);
					val = val < 0 ? 0 : (val > 255 ? 255 : val);
					*(dstPtr++) = (unsigned char)val;
				}
				
				// Create NSData from the buffer and add to result array
				NSData *imageData = [NSData dataWithBytesNoCopy:buffer
														 length:bufferSize
												   freeWhenDone:YES];
				[resultImages addObject:imageData];
			}
			
			*outputImages = resultImages;
		}
	} catch (const gmic_exception &e) {
		if (error) {
			NSString *errMsg = [NSString stringWithUTF8String:e.what()];
			NSDictionary *info = @{ NSLocalizedDescriptionKey: errMsg };
			*error = [NSError errorWithDomain:@"GMICWrapperErrorDomain" code:-1 userInfo:info];
		}
		return NO;
	}
	
	return YES;
}

//- (void)launchQT:(NSString *)inputPath {
//	// Configure the task to launch the gmic-qt executable.
//	NSTask *task = [[NSTask alloc] init];
//	
//	// Update the path below to where your gmic-qt executable is located.
//	NSString *command = [NSString stringWithFormat:@"\"/Users/user/Documents/gmac/Gmac/Sources/Gmic/lib/gmic_qt\" \"%@\"", inputPath];
//	[task setLaunchPath:@"/bin/bash"];
//
//	
//	// Pass the inputPath as an argument to gmic-qt.
//	// You might need to adjust the arguments based on how gmic-qt accepts parameters.
//	[task setArguments:@[@"-c", command]];
//	
//	// Optionally, configure environment variables or the working directory.
//	
//	@try {
//		[task launch];
//	} @catch (NSException *exception) {
//		NSLog(@"Failed to launch gmic-qt: %@", exception);
//	}
//}

@end
