package violin_gui

import "core:fmt"
import "vendor:sdl2"

import vi "violin:vsr"

TextBox :: struct {
  using _ctrlnfo: _ControlInfo,

  hint_text: string,
  text: string,
  font: vi.FontResourceHandle,
  font_color, hint_font_color: vi.Color,
  background_color: vi.Color,
  clip_text_to_bounds: bool,
}

create_textbox :: proc(parent: ^Control, name_id: string = "TextBox") -> (textbox: ^TextBox, err: vi.Error) {
  // Create the textbox
  textbox = new(TextBox)

  // Set the control info
  textbox.ctype = .TextBox
  textbox.id = name_id
  textbox.visible = true

  textbox._delegates.determine_layout_extents = _determine_textbox_extents
  textbox._delegates.render_control = _render_textbox
  textbox._delegates.update_control_layout = update_control_layout
  textbox._delegates.destroy_control = _destroy_textbox_control
  textbox._delegates.handle_gui_event = _handle_textbox_gui_event

  textbox.properties = { .TextRestrained }
  // textbox.bounds = vi.Rectf{0.0, 0.0, 80.0, 20.0}
  // textbox.bounds.left = 0.0
  // textbox.bounds.top = 0.0
  // textbox.bounds.right = 80.0
  // textbox.bounds.bottom = 20.0

  // Default Settings
  textbox._layout.min_width = 8;
  textbox._layout.min_height = 8;
  textbox._layout.margin = { 1, 1, 1, 1 }

  // Set the textbox info
  textbox.text = ""
  textbox.hint_text = ""
  textbox.font = 0
  textbox.font_color = vi.COLOR_White
  textbox.hint_font_color = {0.4, 0.4, 0.4, 1.0}
  textbox.background_color = vi.COLOR_DarkSlateGray
  textbox.clip_text_to_bounds = false

  set_control_requires_layout_update(auto_cast textbox)

  _add_control(parent, auto_cast textbox) or_return

  return
}

@(private) _render_textbox :: proc(using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error) {
  textbox: ^TextBox = auto_cast control

  // fmt.println("Rendering textbox: ", textbox.font)
  textbox_font := textbox.font if textbox.font != auto_cast 0 else gui_root.default_font
  // fmt.println("textbox: ", textbox.font, "&& textbox_font: ", textbox_font)

  if textbox.background_color.a > 0.0 {
    vi.stamp_colored_rect(rctx, stamprr, &textbox.bounds, &textbox.background_color) or_return
  }

  if textbox.text == "" {
    if textbox.hint_text != "" {
      vi.stamp_text(rctx, stamprr, textbox_font, textbox.hint_text, textbox.bounds.x, textbox.bounds.y + textbox.bounds.height,
        &textbox.hint_font_color) or_return
    }
  } else if textbox.font_color.a > 0.0 {
    // fmt.print("Rendering text:", textbox.text, "at:", textbox.bounds.x, "x", textbox.bounds.y + textbox.bounds.height)
    // fmt.println(" with color:", textbox.font_color)
    vi.stamp_text(rctx, stamprr, textbox_font, textbox.text, textbox.bounds.x, textbox.bounds.y + textbox.bounds.height,
      &textbox.font_color) or_return
  }

  return
}

@(private) _handle_textbox_gui_event :: proc(control: ^Control, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
  textbox: ^TextBox = auto_cast control

  handled = false

  #partial switch event.type {
    case .KEYDOWN:
      #partial switch event.key.keysym.sym {
        // textbox.text = textbox.text[0:textbox.text.len - 1]
        // set_control_requires_layout_update(auto_cast textbox)
        // handled = true
      case:
        fmt.println("_handle_textbox_gui_event: Unhandled KEYDOWN:", event.key.keysym.sym)
        err = .NotYetImplemented
        return
        }
    case:
      fmt.println("_handle_textbox_gui_event: Unhandled event type:", event.type)
      err = .NotYetImplemented
      return
  }

  // } else if event.type == sdl2.EVENT_TEXTINPUT {
  //   textbox.text += event.text.text
  //   set_control_requires_layout_update(auto_cast textbox)
  //   handled = true
  // }

  return
}

@(private) _determine_textbox_extents :: proc(gui_root: ^GUIRoot, control: ^Control, restraints: LayoutExtentRestraints) -> vi.Error {
  textbox: ^TextBox = auto_cast control

  textbox_font := textbox.font if textbox.font != auto_cast 0 else gui_root.default_font

  text_width, text_height: f32
  if len(textbox.text) > 0 {
    text_width, text_height = vi.determine_text_display_dimensions(gui_root.vctx, textbox_font, textbox.text) or_return
  } else {
    text_width, text_height = vi.determine_text_display_dimensions(gui_root.vctx, textbox_font, textbox.hint_text) or_return
    fmt.println("Hint text:", textbox.hint_text, "has dimensions:", text_width, "x", text_height)
  }

  return determine_text_restrained_control_extents(gui_root, control, restraints, text_width, text_height)
}

@(private) _destroy_textbox_control :: proc(ctx: ^vi.Context, control: ^Control) {
  textbox: ^TextBox = auto_cast control
  if textbox.font != 0 do vi.destroy_font(ctx, textbox.font)
}