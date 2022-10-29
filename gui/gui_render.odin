package violin_gui

import "core:fmt"
import "core:mem"

import "vendor:sdl2"

import vi "../../violin"

render_gui :: proc(using rctx: ^vi.RenderContext, stamprr: vi.StampRenderResourceHandle, gui_root: ^GUIRoot) -> vi.Error {
  // Update the layout of each child
  return _render_container_control(rctx, stamprr, gui_root)
}

_render_container_control :: proc(using rctx: ^vi.RenderContext, stamprr: vi.StampRenderResourceHandle, container: ^_ParentControlInfo) -> (err: vi.Error) {
  if container.children == nil do return

  for child in container.children {
    switch child.ctype {
      case .Label:
        _render_label_control(rctx, stamprr, auto_cast child) or_return
      case .GUIRoot, .Button, .Textbox:
        fallthrough
      case:
        fmt.println("Unknown child control type:", child.ctype)
        err = .NotYetImplemented
        return
    }
  }
  return
}

_render_label_control :: proc(using rctx: ^vi.RenderContext, stamprr: vi.StampRenderResourceHandle, label: ^Label) -> (err: vi.Error) {
  if label.background_color.a > 0.0 {
    vi.stamp_colored_rect(rctx, stamprr, &label.bounds, &label.background_color) or_return
  }

  if label.text != "" && label.font_color.a > 0.0 {
    fmt.println("Rendering text:", label.text, "at:", label.bounds)
    vi.stamp_text(rctx, stamprr, label.font, label.text, label.bounds.x, label.bounds.y + label.bounds.height, &label.font_color) or_return
  }

  return
}