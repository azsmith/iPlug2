/*
 ==============================================================================

  MIT License

  iPlug2 Visage Support
  Copyright (c) 2025 Oliver Larkin

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

 ==============================================================================
*/

#include "IPlugVisageEditorDelegate.h"

BEGIN_IPLUG_NAMESPACE

VisageEditorDelegate::VisageEditorDelegate(int nParams)
: IEditorDelegate(nParams)
{
}

VisageEditorDelegate::~VisageEditorDelegate()
{
  CloseWindow();
}

void* VisageEditorDelegate::OpenWindow(void* pParent)
{
  mEditor = std::make_unique<visage::ApplicationEditor>();
  mEditor->setBounds(0, 0, GetEditorWidth(), GetEditorHeight());

  mEditor->onDraw() = [this](visage::Canvas& canvas) {
    OnDraw(canvas);
  };

  mEditor->onMouseDown() = [this](const visage::MouseEvent& e) {
    OnMouseDown(e);
  };

  mEditor->onMouseDrag() = [this](const visage::MouseEvent& e) {
    OnMouseDrag(e);
  };

  mEditor->onMouseUp() = [this](const visage::MouseEvent& e) {
    OnMouseUp(e);
  };

  mEditor->onMouseMove() = [this](const visage::MouseEvent& e) {
    OnMouseMove(e);
  };

  mEditor->onMouseWheel() = [this](const visage::MouseEvent& e) {
    return OnMouseWheel(e);
  };

  mWindow = visage::createPluginWindow(mEditor->width(), mEditor->height(), pParent);
  mEditor->addToWindow(mWindow.get());
  mWindow->show();

  OnUIOpen();
  return mWindow->nativeHandle();
}

void VisageEditorDelegate::CloseWindow()
{
  OnUIClose();
  if (mEditor)
    mEditor->removeFromWindow();
  mWindow.reset();
  mEditor.reset();
}

void VisageEditorDelegate::OnParentWindowResize(int width, int height)
{
  if (mWindow && mEditor)
  {
    int logical_width = width;
    int logical_height = height;
    float scale = mWindow->dpiScale();

    if (scale > 1.01f)
    {
      int current_native_width = mWindow->clientWidth();
      int current_native_height = mWindow->clientHeight();
      int current_logical_width = std::round(current_native_width / scale);
      int current_logical_height = std::round(current_native_height / scale);

      bool width_is_native = std::abs(width - current_native_width) <= 2 ||
                             width > current_logical_width * 3 / 2;
      bool height_is_native = std::abs(height - current_native_height) <= 2 ||
                              height > current_logical_height * 3 / 2;

      if (width_is_native)
        logical_width = std::round(width / scale);
      if (height_is_native)
        logical_height = std::round(height / scale);
    }

    mWindow->setWindowSize(logical_width, logical_height);
    mEditor->setBounds(0, 0, logical_width, logical_height);
  }
}

END_IPLUG_NAMESPACE
