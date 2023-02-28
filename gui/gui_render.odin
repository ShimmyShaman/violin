package violin_gui

import "core:fmt"
import "core:mem"

import "vendor:sdl2"

import vi "violin:vsr"

GUIRenderContext :: struct {
  gui_root: ^GUIRoot,
  rctx: ^vi.RenderContext,
  stamprr: vi.StampRenderResourceHandle,
}

render_gui :: proc(using rctx: ^vi.RenderContext, stamprr: vi.StampRenderResourceHandle, gui_root: ^GUIRoot) -> vi.Error {
  grc := GUIRenderContext {
    gui_root = gui_root,
    rctx = rctx,
    stamprr = stamprr,
  }

  // Render the gui tree
  if gui_root.children != nil {
    for child in gui_root.children {
      if child.visible do child._delegates.render_control(&grc, child) or_return
    }
  }

  return .Success
}