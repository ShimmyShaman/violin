package violin_gui

import "core:fmt"
import "vendor:sdl2"

import vi "violin:vsr"

Label :: struct {
  using _ctrlnfo: _ControlInfo,

  text: string,
  font: vi.FontResourceHandle,
  font_color: vi.Color,
  background_color: vi.Color,
  clip_text_to_bounds: bool,
}

create_label :: proc(parent: ^Control, name_id: string = "Label") -> (label: ^Label, err: vi.Error) {
  // Create the label
  label = new(Label)

  // Set the control info
  label.ctype = .Label
  label.id = name_id
  label.visible = true

  label._delegates.determine_layout_extents = _determine_label_extents
  label._delegates.render_control = _render_label
  label._delegates.update_control_layout = update_control_layout
  label._delegates.destroy_control = _destroy_label_control
  label._delegates.handle_gui_event = _handle_label_gui_event

  label.properties = { .TextRestrained }
  // label.bounds = vi.Rectf{0.0, 0.0, 80.0, 20.0}
  // label.bounds.left = 0.0
  // label.bounds.top = 0.0
  // label.bounds.right = 80.0
  // label.bounds.bottom = 20.0

  // Default Settings
  label._layout.min_width = 8;
  label._layout.min_height = 8;
  label._layout.margin = { 1, 1, 1, 1 }

  // Set the label info
  label.text = "Label"
  label.font = 0
  label.font_color = vi.COLOR_White
  label.background_color = vi.COLOR_DarkSlateGray
  label.clip_text_to_bounds = false

  // label._layout.requires_layout_update = true

  _add_control(parent, auto_cast label) or_return

  return
}

@(private) _render_label :: proc(using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error) {
  label: ^Label = auto_cast control

  // fmt.println("Rendering label: ", label.font)
  label_font := label.font if label.font != auto_cast 0 else gui_root.default_font
  // fmt.println("label: ", label.font, "&& label_font: ", label_font)

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

@(private) _handle_label_gui_event :: proc(control: ^Control, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
  // Do nothing
  // -- Click Through --
  return
}

@(private) _determine_label_extents :: proc(gui_root: ^GUIRoot, control: ^Control, restraints: LayoutExtentRestraints) -> vi.Error {
  label: ^Label = auto_cast control

  label_font := label.font if label.font != auto_cast 0 else gui_root.default_font

  text_width, text_height := vi.determine_text_display_dimensions(gui_root.vctx, label_font, label.text) or_return

  return determine_text_restrained_control_extents(gui_root, control, restraints, text_width, text_height)
}

@(private) _destroy_label_control :: proc(ctx: ^vi.Context, control: ^Control) {
  label: ^Label = auto_cast control
  if label.font != 0 do vi.destroy_font(ctx, label.font)
}