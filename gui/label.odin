package violin_gui

import "core:fmt"

import vi "violin:vsr"

Label :: struct {
  using _ctrlnfo: _ControlInfo,

  text: string,
  font: vi.FontResourceHandle,
  font_color: vi.Color,
  background_color: vi.Color,
  clip_text_to_bounds: bool,
}

add_control :: proc(parent: rawptr, control: ^_ControlInfo) -> (err: vi.Error) {
  // Obtain the gui root
  gui_root: ^GUIRoot = _get_gui_root(parent) or_return

  // TODO parent check
  // _name_control(label, name_id) TODO -- proper name control
  control.parent = auto_cast parent

  append(&(cast(^_ContainerControlInfo)parent).children, auto_cast control)

  return
}

create_label :: proc(name_id: string = "Label") -> (label: ^Label, err: vi.Error) {
  // Create the label
  label = new(Label)

  // Set the control info
  label.ctype = .Label
  label.id = name_id
  label.visible = true

  label._delegates.determine_control_extents = _determine_control_extents
  label._delegates.render_control = _render_label_control

  label.properties = { .TextRestrained }
  // label.bounds = vi.Rectf{0.0, 0.0, 80.0, 20.0}
  // label.bounds.left = 0.0
  // label.bounds.top = 0.0
  // label.bounds.right = 80.0
  // label.bounds.bottom = 20.0

  // Default Settings
  label._layout.min_width = 8;
  label._layout.min_height = 8;
  label._layout.padding = { 1, 1, 1, 1 }

  // Set the label info
  label.text = "Label"
  label.font = 0
  label.font_color = vi.COLOR_White
  label.background_color = vi.COLOR_DarkSlateGray
  label.clip_text_to_bounds = false

  // label._layout.requires_layout_update = true

  return
}

_render_label_control :: proc(using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error) {
  label: ^Label = auto_cast control

  fmt.println("Rendering label: ", label.font)
  label_font := label.font if label.font != auto_cast 0 else gui_root.default_font
  fmt.println("label: ", label.font, "&& label_font: ", label_font)

  if label.background_color.a > 0.0 {
    vi.stamp_colored_rect(rctx, stamprr, &label.bounds, &label.background_color) or_return
  }

  if label.text != "" && label.font_color.a > 0.0 {
    // fmt.print("Rendering text:", label.text, "at:", label.bounds.x, "x", label.bounds.y + label.bounds.height)
    // fmt.println(" with color:", label.font_color)
    vi.stamp_text(rctx, stamprr, label_font, label.text, label.bounds.x, label.bounds.y + label.bounds.height, &label.font_color) or_return
  }

  return
}