#  ==============================================================================
#
#  This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers.
#
#  See LICENSE.txt for  more info.
#
#  ==============================================================================

# AUv3 (Audio Unit v3) shared definitions for iPlug2 iOS
# Defines iPlug2::AUv3iOS interface and helper functions
# Included by AUv3iOSFramework.cmake and AUv3iOSAppex.cmake

include(${CMAKE_CURRENT_LIST_DIR}/IPlug.cmake)

if(NOT TARGET iPlug2::AUv3iOS)
  if(NOT IOS)
    message(WARNING "AUv3iOS is only supported when building for iOS (CMAKE_SYSTEM_NAME=iOS)")
    return()
  endif()

  add_library(iPlug2::AUv3iOS INTERFACE IMPORTED)

  # iPlug2 AUv3 wrapper sources (same as macOS)
  set(AUV3_IOS_IPLUG_SRC
    ${IPLUG_DIR}/AUv3/IPlugAUv3.mm
    ${IPLUG_DIR}/AUv3/IPlugAUAudioUnit.mm
    ${IPLUG_DIR}/AUv3/IPlugAUViewController.mm
  )

  target_sources(iPlug2::AUv3iOS INTERFACE ${AUV3_IOS_IPLUG_SRC})

  target_include_directories(iPlug2::AUv3iOS INTERFACE
    ${IPLUG_DIR}/AUv3
  )

  target_compile_definitions(iPlug2::AUv3iOS INTERFACE
    AUv3_API
    IPLUG_EDITOR=1
    IPLUG_DSP=1
  )

  # iOS AUv3 headers need UIKit (not Cocoa like macOS)
  # Force-include ObjC prefix header to customize class names and avoid conflicts
  # Note: Use $<COMPILE_LANGUAGE:> to avoid applying to Swift sources (Swift doesn't support -include)
  target_compile_options(iPlug2::AUv3iOS INTERFACE
    "$<$<NOT:$<COMPILE_LANGUAGE:Swift>>:SHELL:-include ${IPLUG_DIR}/IPlugOBJCPrefix.pch>"
  )

  # iOS-specific frameworks for AUv3
  target_link_libraries(iPlug2::AUv3iOS INTERFACE
    "-framework AudioToolbox"
    "-framework AVFoundation"
    "-framework CoreAudioKit"
    "-framework CoreMIDI"
    "-framework UIKit"
    "-framework QuartzCore"
    "-framework CoreText"
    "-framework CoreGraphics"
    "-framework UniformTypeIdentifiers"
    iPlug2::IPlug
  )
endif()

# ============================================================================
# Get or generate the appex source file for iOS
# Returns the path in APPEX_SOURCE_OUT variable
# ============================================================================
function(iplug_get_auv3ios_appex_source project_name APPEX_SOURCE_OUT)
  # Check for existing appex source with either naming convention
  if(EXISTS "${PLUG_RESOURCES_DIR}/${project_name}AUv3Appex.m")
    set(${APPEX_SOURCE_OUT} "${PLUG_RESOURCES_DIR}/${project_name}AUv3Appex.m" PARENT_SCOPE)
  else()
    # Generate a minimal appex source file
    set(GENERATED_APPEX "${CMAKE_CURRENT_BINARY_DIR}/${project_name}AUv3Appex-iOS.m")
    file(WRITE ${GENERATED_APPEX}
"// Auto-generated AUv3 appex source for iOS
#import <Foundation/Foundation.h>
// Dummy function to ensure linking
void AUv3iOSAppexDummy(void) {}
")
    set(${APPEX_SOURCE_OUT} "${GENERATED_APPEX}" PARENT_SCOPE)
  endif()
endfunction()

# ============================================================================
# Embed AUv3 appex and framework in an existing iOS APP target
# iOS structure: framework at App/Frameworks/, appex at App/PlugIns/
# (Note: iOS uses flat bundle structure, not Contents/ like macOS)
# ============================================================================
function(iplug_embed_auv3ios_in_app app_target project_name)
  set(appex_target ${project_name}AUv3-ios-appex)
  set(framework_target ${project_name}AU-ios-framework)

  add_dependencies(${app_target} ${appex_target})

  # Embed framework and appex in iOS app bundle
  if(XCODE AND CMAKE_VERSION VERSION_GREATER_EQUAL "3.20")
    # Use native Xcode embedding — works correctly with archive builds
    set_target_properties(${app_target} PROPERTIES
      XCODE_EMBED_FRAMEWORKS "${framework_target}"
      XCODE_EMBED_FRAMEWORKS_CODE_SIGN_ON_COPY YES
      XCODE_EMBED_FRAMEWORKS_REMOVE_HEADERS_ON_COPY YES
      XCODE_EMBED_APP_EXTENSIONS "${appex_target}"
      XCODE_EMBED_APP_EXTENSIONS_CODE_SIGN_ON_COPY YES
    )
  else()
    # Fallback: manual post-build copy for non-Xcode generators
    add_custom_command(TARGET ${app_target} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_BUNDLE_DIR:${app_target}>/Frameworks"
      COMMAND cp -R
        "${CMAKE_BINARY_DIR}/out/${project_name}AU.framework"
        "$<TARGET_BUNDLE_DIR:${app_target}>/Frameworks/"
      COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_BUNDLE_DIR:${app_target}>/PlugIns"
      COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_BINARY_DIR}/out/${project_name}AUv3.appex"
        "$<TARGET_BUNDLE_DIR:${app_target}>/PlugIns/${project_name}AUv3.appex"
      COMMENT "Embedding iOS AUv3 (framework + appex) in ${project_name}.app"
    )
  endif()
endfunction()
