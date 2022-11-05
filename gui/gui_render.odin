package violin_gui

import "core:fmt"
import "core:mem"

import "vendor:sdl2"

import vi "violin:vsr"

ProcRenderControl :: proc (using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error)

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

  // Update the layout of each child
  if gui_root.children != nil {
    for child in gui_root.children {
      child._delegates.render_control(&grc, child) or_return
    }
  }

  return .Success
}