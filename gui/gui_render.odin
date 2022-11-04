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
  return _render_container_control(&grc, gui_root)
}

_render_container_control :: proc(using grc: ^GUIRenderContext, container: ^_ContainerControlInfo) -> (err: vi.Error) {
  if container.children == nil do return

  for child in container.children {
    child._delegates.render_control(grc, child)
  }
  return
}