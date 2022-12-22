package violin_gui

import "core:fmt"
import la "core:math/linalg"

import sdl2 "vendor:sdl2"

import vi "violin:vsr"

ButtonVisualState :: enum {
  Normal,
  Hover,
  Pressed,
  Disabled,
}

ButtonState :: struct {
  visual_state: ButtonVisualState,
  background_draw_color: vi.Color,
}

Button :: struct {
  using _ctrlnfo: _ControlInfo,

  _state: ButtonState,
  
  text: string,
  font: vi.FontResourceHandle,
  font_color: vi.Color,

  background_color, background_highlight_color, background_pressed_color, background_disabled_color: vi.Color,

  tag: rawptr,
}

create_button :: proc(parent: ^Control, name_id: string = "Button") -> (button: ^Button, err: vi.Error) {
  // Create the label
  button = new(Button)

  // Set the control info
  button.ctype = .Button
  button.id = name_id
  button.visible = true

  button._delegates.determine_layout_extents = _determine_button_extents
  button._delegates.frame_update = _frame_update_control
  button._delegates.render_control = _render_button
  button._delegates.update_control_layout = update_control_layout
  button._delegates.handle_gui_event = _handle_button_gui_event
  button._delegates.destroy_control = _destroy_button_control

  button.properties = { .TextRestrained }
  // label.bounds = vi.Rectf{0.0, 0.0, 80.0, 20.0}
  // label.bounds.left = 0.0
  // label.bounds.top = 0.0
  // label.bounds.right = 80.0
  // label.bounds.bottom = 20.0

  // Default Settings
  button._layout.min_width = 8;
  button._layout.min_height = 8;
  button._layout.margin = { 1, 1, 1, 1 }

  // Set the label info
  button.text = "Button"
  button.font = 0
  button.font_color = vi.COLOR_White

  button.background_color = { 0.1, 0.1, 0.1, 1.0 }
  button.background_highlight_color = { 0.2, 0.14, 0.14, 1.0 }
  button.background_pressed_color = { 0.2, 0.2, 0.27, 1.0 }
  button.background_disabled_color = { 0.1, 0.1, 0.1, 0.5 }
  // button.clip_text_to_bounds = false

  set_control_requires_layout_update(auto_cast button)

  _add_control(parent, auto_cast button) or_return

  return
}

@(private) _render_button :: proc(using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error) {
  button: ^Button = auto_cast control

  // fmt.println("Rendering button: ", button.text)
  button_font := button.font if button.font != auto_cast 0 else gui_root.default_font
  // fmt.println("button: ", button.font, "&& button_font: ", button_font)

  if button.background_color.a > 0.0 {
    vi.stamp_colored_rect(rctx, stamprr, &button.bounds, &button._state.background_draw_color) or_return
  }

  if button.text != "" && button.font_color.a > 0.0 {
    // fmt.print("Rendering text:", label.text, "at:", label.bounds.x, "x", label.bounds.y + label.bounds.height)
    // fmt.println(" with color:", label.font_color)
    vi.stamp_text(rctx, stamprr, button_font, button.text, button.bounds.x, button.bounds.y + button.bounds.height, &button.font_color) or_return
  }

  return
}

@(private) _determine_button_extents :: proc(gui_root: ^GUIRoot, control: ^Control, restraints: LayoutExtentRestraints) -> vi.Error {
  button: ^Button = auto_cast control

  button_font := button.font if button.font != auto_cast 0 else gui_root.default_font

  text_width, text_height := vi.determine_text_display_dimensions(gui_root.vctx, button_font, button.text) or_return

  return determine_text_restrained_control_extents(gui_root, control, restraints, text_width, text_height)
}

@(private) _handle_button_gui_event :: proc(control: ^Control, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
  button: ^Button = auto_cast control

  mouse_leaves, mouse_enters := false, false

  // fmt.println("GUI Input Event: ", event.type, " for button: ", button.text)
  #partial switch event.type {
    case .MOUSEMOTION:
      x, y: f32 = auto_cast event.motion.x, auto_cast event.motion.y
      mouse_is_over := x >= button.bounds.x && x < button.bounds.x + button.bounds.width && y >= button.bounds.y &&
        y < button.bounds.y + button.bounds.height
      switch button._state.visual_state {
        case .Disabled:
          handled = false
        case .Normal:
          if mouse_is_over {
            button._state.visual_state = .Hover
            mouse_enters = true
          }
          handled = mouse_is_over
        case .Hover, .Pressed:
          if !mouse_is_over {
            button._state.visual_state = .Normal
            mouse_leaves = true
          }
          handled = mouse_is_over
      }
    case .MOUSEBUTTONDOWN:
      if button._state.visual_state == .Hover {
        button._state.visual_state = .Pressed
      }
      handled = button._state.visual_state == .Pressed
    case .MOUSEBUTTONUP:
      if button._state.visual_state == .Pressed {
        button._state.visual_state = .Hover
      }
      handled = button._state.visual_state == .Hover
    case .KEYMAPCHANGED:
      handled = false
    case:
      fmt.println("Warning Unhandled GUI Input Event: ", event.type, " for button: ", button.id)
  }

  // fmt.println("Button: ", button.text, " handled: ", handled, " state: ", button._state.visual_state)
  // TODO MouseEnters, MouseLeaves

  handled = true
  return
}

@(private) _frame_update_control :: proc(control: ^Control, dt: f32) -> (err: vi.Error) {
  button: ^Button = auto_cast control

  if button.disabled do button._state.visual_state = .Disabled
  // fmt.println("Button: ", button.text, " state: ", button._state.visual_state)
  switch button._state.visual_state {
    case .Normal:
      button._state.background_draw_color = button.background_color
    case .Hover:
      button._state.background_draw_color = button.background_highlight_color
    case .Pressed:
      button._state.background_draw_color = button.background_pressed_color
    case .Disabled:
      button._state.background_draw_color = button.background_disabled_color
  }
  return
}

@(private) _destroy_button_control :: proc(ctx: ^vi.Context, control: ^Control) {
  button: ^Button = auto_cast control
  if button.font != 0 do vi.destroy_font(ctx, button.font)
}