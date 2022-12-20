package violin_gui

import "core:fmt"

import sdl2 "vendor:sdl2"

import vi "violin:vsr"

Button :: struct {
  using _ctrlnfo: _ControlInfo,
  
  text: string,
  font: vi.FontResourceHandle,
  font_color: vi.Color,
  background_color: vi.Color,
  // clip_text_to_bounds: bool,
}

create_button :: proc(parent: ^Control, name_id: string = "Button") -> (button: ^Button, err: vi.Error) {
  // Create the label
  button = new(Button)

  // Set the control info
  button.ctype = .Button
  button.id = name_id
  button.visible = true

  button._delegates.determine_layout_extents = _determine_button_extents
  button._delegates.render_control = _render_button
  button._delegates.update_control_layout = update_control_layout
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
  button.background_color = vi.COLOR_DarkSlateGray
  // button.clip_text_to_bounds = false

  // label._layout.requires_layout_update = true

  _add_control(parent, auto_cast button) or_return

  return
}

@(private) _render_button :: proc(using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error) {
  button: ^Button = auto_cast control

  // fmt.println("Rendering button: ", button.text)
  button_font := button.font if button.font != auto_cast 0 else gui_root.default_font
  // fmt.println("button: ", button.font, "&& button_font: ", button_font)

  if button.background_color.a > 0.0 {
    vi.stamp_colored_rect(rctx, stamprr, &button.bounds, &button.background_color) or_return
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

// void _mcu_button_handle_gui_event(mc_node *button_node, mci_input_event *input_event)
// {
//   // printf("_mcu_button_handle_gui_event\n");
//   mcu_button *button = (mcu_button *)button_node->data;

//   if (!button->enabled)
//     return;

//   if (input_event->type == INPUT_EVENT_MOUSE_PRESS) {
//     // printf("_mcu_button_handle_gui_event-1\n");
//     if (button->left_click && (mc_mouse_button_code)input_event->button_code == MOUSE_BUTTON_LEFT) {
//       // printf("_mcu_button_handle_gui_event-2\n");
//       // Fire left-click
//       // TODO fptr casting
//       // TODO int this delegate for error handling
//       void (*left_click)(mci_input_event *, mcu_button *) =
//           (void (*)(mci_input_event *, mcu_button *))button->left_click;
//       // TODO -- MCcall(below) - have to make handle input event int
//       left_click(input_event, button);
//     }
//   }

//   input_event->handled = true;
// }

@(private) _handle_button_input_event :: proc(control: ^Control, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
  button: ^Button = auto_cast control

  fmt.println("GUI Input Event: ", event.type, " for button: ", button.text)
  return
}

@(private) _destroy_button_control :: proc(ctx: ^vi.Context, control: ^Control) {
  button: ^Button = auto_cast control
  if button.font != 0 do vi.destroy_font(ctx, button.font)
}