/*
 ==============================================================================

 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers.

 See LICENSE.txt for  more info.

 ==============================================================================
*/

#pragma once

// Pure C++ (no AppKit) so it can be unit tested on its own.
//
// Where a popup menu lands on screen. IGraphicsMac anchors NSMenus by converting a view point
// through the view's NSWindow to screen coordinates. For an AUv2 hosted out of process
// (Logic's AUHostingService) that NSWindow is a stand-in whose screen geometry is kept in sync
// by the host, and it can go stale: in Logic, collapsing the plugin window's header moves the
// view inside the host window without the stand-in following, so the menu opened offset from
// the control while mouse hit-testing (view-local) stayed correct.
//
// The fix measures that error at the moment of the click: the true cursor position from the
// window server, minus where the window's geometry says the click was. The same error is then
// added to the menu anchor. In process the two agree and the correction is zero.

struct IGMacScreenPoint
{
  double x = 0.0;
  double y = 0.0;
};

/** How far the window's own geometry is off from the real screen, measured at a mouse-down.
 * @param cursorOnScreen The real cursor position ([NSEvent mouseLocation]) at the mouse-down
 * @param clickViaWindow The same click converted to screen through the view's window */
inline IGMacScreenPoint IGMacPopupAnchorCorrection(IGMacScreenPoint cursorOnScreen, IGMacScreenPoint clickViaWindow)
{
  return {cursorOnScreen.x - clickViaWindow.x, cursorOnScreen.y - clickViaWindow.y};
}

/** The screen point to open a popup at.
 * @param anchorViaWindow The anchor converted to screen through the view's window
 * @param correction From IGMacPopupAnchorCorrection at the most recent mouse-down
 * @param correctionAgeSeconds Time since that mouse-down, negative if there was none
 * @param maxAgeSeconds A correction older than this is not trusted (the window may have moved
 * since); the anchor is then used as the window reports it, which is the old behaviour */
inline IGMacScreenPoint IGMacCorrectedPopupAnchor(IGMacScreenPoint anchorViaWindow, IGMacScreenPoint correction,
                                                  double correctionAgeSeconds, double maxAgeSeconds = 2.0)
{
  if (correctionAgeSeconds < 0.0 || correctionAgeSeconds > maxAgeSeconds)
    return anchorViaWindow;

  return {anchorViaWindow.x + correction.x, anchorViaWindow.y + correction.y};
}
