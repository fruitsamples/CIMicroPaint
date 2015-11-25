/* CIMicroPaintView.h - subclass of SampleCIView to handle painting 
 
 Version: 1.1
 
 © Copyright 2006-2009 Apple, Inc. All rights reserved.
 
 IMPORTANT:  This Apple software is supplied to 
 you by Apple Computer, Inc. ("Apple") in 
 consideration of your agreement to the following 
 terms, and your use, installation, modification 
 or redistribution of this Apple software 
 constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, 
 install, modify or redistribute this Apple 
 software.
 
 In consideration of your agreement to abide by 
 the following terms, and subject to these terms, 
 Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this 
 original Apple software (the "Apple Software"), 
 to use, reproduce, modify and redistribute the 
 Apple Software, with or without modifications, in 
 source and/or binary forms; provided that if you 
 redistribute the Apple Software in its entirety 
 and without modifications, you must retain this 
 notice and the following text and disclaimers in 
 all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or 
 logos of Apple Computer, Inc. may be used to 
 endorse or promote products derived from the 
 Apple Software without specific prior written 
 permission from Apple.  Except as expressly 
 stated in this notice, no other rights or 
 licenses, express or implied, are granted by 
 Apple herein, including but not limited to any 
 patent rights that may be infringed by your 
 derivative works or by other works in which the 
 Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS 
 IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR 
 IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED 
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY 
 AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING 
 THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE 
 OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY 
 SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF 
 THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER 
 UNDER THEORY OF CONTRACT, TORT (INCLUDING 
 NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN 
 IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF 
 SUCH DAMAGE.
 
 */

#import "CIMicroPaintView.h"


@implementation CIMicroPaintView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self == nil)
	return nil;

    brushSize = 25.0;

    color = [NSColor colorWithDeviceRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0];
    [color retain];

    brushFilter = [CIFilter filterWithName: @"CIRadialGradient" keysAndValues:
		   @"inputColor1", [CIColor colorWithRed:0.0 green:0.0
		   blue:0.0 alpha:0.0], @"inputRadius0", [NSNumber numberWithDouble:0.0], nil];
    [brushFilter retain];

    compositeFilter = [CIFilter filterWithName: @"CISourceOverCompositing"];
    [compositeFilter retain];

    return self;
}

- (void)dealloc
{
    [imageAccumulator release];
    [brushFilter release];
    [compositeFilter release];
    [color release];
    [super dealloc];
}

- (void)viewBoundsDidChange:(NSRect)bounds
{
    CIImageAccumulator *c;
    CIFilter *f;

    if (imageAccumulator != nil
	&& CGRectEqualToRect (*(CGRect *)&bounds, [imageAccumulator extent]))
    {
	return;
    }

    /* Create a new accumulator and composite the old one over the it. */

    c = [[CIImageAccumulator alloc]
	 initWithExtent:*(CGRect *)&bounds format:kCIFormatRGBA16];
    f = [CIFilter filterWithName:@"CIConstantColorGenerator"
	 keysAndValues:@"inputColor",
	 [CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], nil];
    [c setImage:[f valueForKey:@"outputImage"]];

    if (imageAccumulator != nil)
    {
	f = [CIFilter filterWithName:@"CISourceOverCompositing"
	     keysAndValues:@"inputImage", [imageAccumulator image],
	     @"inputBackgroundImage", [c image], nil];
	[c setImage:[f valueForKey:@"outputImage"]];
    }

    [imageAccumulator release];
    imageAccumulator = c;

    [self setImage:[imageAccumulator image]];
}

- (void)mouseDragged:(NSEvent *)event
{
    CGRect   rect;
    NSPoint  loc = [self convertPoint: [event locationInWindow] fromView: nil];
    CIColor *cicolor;

    rect = CGRectMake(loc.x-brushSize, loc.y-brushSize,
        2.0*brushSize, 2.0*brushSize);
    [brushFilter setValue: [NSNumber numberWithDouble:brushSize]
        forKey: @"inputRadius1"];
    cicolor = [[CIColor alloc] initWithColor: color];
    [brushFilter setValue: cicolor  forKey: @"inputColor0"];
    [cicolor release];	//cicolor is retained by the brushFilter
    [brushFilter setValue: [CIVector vectorWithX: loc.x Y:loc.y]
        forKey: @"inputCenter"];
    
    [compositeFilter setValue: [brushFilter valueForKey: @"outputImage"]
        forKey: @"inputImage"];
    [compositeFilter setValue: [imageAccumulator image]
        forKey: @"inputBackgroundImage"];
    
    [imageAccumulator setImage: [compositeFilter valueForKey: @"outputImage"]
        dirtyRect: rect];

    [self setImage: [imageAccumulator image] dirtyRect: rect];
}

- (void)mouseDown:(NSEvent *)event
{
    [self mouseDragged: event];
}

@end
