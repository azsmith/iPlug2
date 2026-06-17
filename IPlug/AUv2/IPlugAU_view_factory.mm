/*
 ==============================================================================
 
 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers. 
 
 See LICENSE.txt for  more info.
 
 ==============================================================================
*/
 
#import <Cocoa/Cocoa.h>
#include <AudioUnit/AudioUnit.h>
#include <AudioUnit/AUCocoaUIView.h>

#include "config.h"   // This is your plugin's config.h.
#include "IPlugAPIBase.h"

using namespace iplug;

static const AudioUnitPropertyID kIPlugObjectPropertyID = UINT32_MAX-100;

@interface AUV2_VIEW_CLASS : NSObject <AUCocoaUIBase>
{
  IPlugAPIBase* mPlug;
}
- (id) init;
- (NSView*) uiViewForAudioUnit: (AudioUnit) audioUnit withSize: (NSSize) preferredSize;
- (unsigned) interfaceVersion;
- (NSString*) description;
@end

@implementation AUV2_VIEW_CLASS

- (id) init
{
  TRACE  
  mPlug = nullptr;
  return [super init];
}

- (NSView*) uiViewForAudioUnit: (AudioUnit) audioUnit withSize: (NSSize) preferredSize
{
  TRACE

  void* pointers[1];
  UInt32 propertySize = sizeof (pointers);
  
  if (AudioUnitGetProperty (audioUnit, kIPlugObjectPropertyID,
                            kAudioUnitScope_Global, 0, pointers, &propertySize) == noErr)
  {
    mPlug = (IPlugAPIBase*) pointers[0];
    
    if (mPlug)
    {
      if (mPlug->HasUI())
      {
#if __has_feature(objc_arc)
        NSView* pView = (__bridge NSView*) mPlug->OpenWindow(nullptr);
#else
        NSView* pView = (NSView*) mPlug->OpenWindow(nullptr);
#endif
        return pView;
      }
    }
  }
  return 0;
}

- (unsigned) interfaceVersion
{
  return 0;
}

- (NSString*) description
{
  return [NSString stringWithUTF8String:PLUG_NAME " View"];
}

@end

// Returns a +1 retained CFURLRef (caller must CFRelease) for the bundle that
// contains this AU's Cocoa view factory class, or NULL. Used as a fallback in
// IPlugAU::GetProperty(kAudioUnitProperty_CocoaUI) when
// CFBundleGetBundleWithIdentifier() returns NULL — which happens in
// out-of-process validation/host contexts (auval, Logic) where CoreFoundation
// has not instantiated a CFBundle for the dlopen'd component. Resolving by the
// loaded class' own Mach-O image is the source of truth for "where is my UI",
// so the host can still locate and load the view class.
extern "C" CFURLRef IPlugAUCocoaViewBundleURL(void)
{
  NSBundle* bundle = [NSBundle bundleForClass:[AUV2_VIEW_CLASS class]];
  NSURL* url = bundle ? [bundle bundleURL] : nil;
  if (!url)
    return NULL;
#if __has_feature(objc_arc)
  return (CFURLRef) CFBridgingRetain(url);
#else
  return (CFURLRef) [url retain];
#endif
}


