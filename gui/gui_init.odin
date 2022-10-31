package violin_gui

import "core:fmt"
import "core:mem"

import vi "violin:vsr"

ControlType :: enum {
  GUIRoot = 1,
  Label = 100,
  Button,
  Textbox,
}

ControlProperties :: distinct bit_set[ControlProperty; u8]
ControlProperty :: enum(u8) {
  Container,
  TextRestrained,
}

HorizontalAlignment :: enum {
  Left,
  Centred,
  Right,
}

VerticalAlignment :: enum {
  Top,
  Centred,
  Bottom,
}

Extent :: struct {
  left, top, right, bottom: f32,
}

_ControlLayout :: struct {
  requires_layout_update: bool,

  focused_child: ^Control,

  // Layout Properties
  horizontal_alignment: HorizontalAlignment,
  vertical_alignment: VerticalAlignment,
  preferred_width, preferred_height: f32,
  min_width, min_height: f32,
  max_width, max_height: f32,
  padding: Extent,

  determined_width_extent, determined_height_extent: f32,

  z_layer_index: int,
}

_ControlInfo :: struct {
  ctype: ControlType,
  _layout: _ControlLayout,
  id: string,
  parent: ^_ContainerControlInfo,
  visible: bool,
  properties: ControlProperties,

  bounds: vi.Rectf,
}

_ContainerControlInfo :: struct {
  using _ctrlnfo: _ControlInfo,
  children: [dynamic]^Control,
}

GUIRoot :: struct {
  using _pcnfo: _ContainerControlInfo,

  // The context this gui is created and rendered in
  vctx: ^vi.Context,
  default_font: vi.FontResourceHandle,
}

Label :: struct {
  using _ctrlnfo: _ControlInfo,

  text: string,
  font: vi.FontResourceHandle,
  font_color: vi.Color,
  background_color: vi.Color,
  clip_text_to_bounds: bool,
}

Button :: struct {
  using _ctrlnfo: _ControlInfo,
}

Textbox :: struct {
  using _ctrlnfo: _ControlInfo,
}

Control :: struct #raw_union {
  using _info: _ControlInfo,
  root: GUIRoot,
  label: Label,
  button: Button,
  textbox: Textbox,
}

when ODIN_OS == .Windows {
  DEFAULT_FONT_PATH :: "C:/Windows/Fonts/arial.ttf"
}
when ODIN_OS == .Linux {
  DEFAULT_FONT_PATH :: "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
}
when ODIN_OS == .Darwin {
  DEFAULT_FONT_PATH :: "/Library/Fonts/Arial.ttf"
}

create_gui_root :: proc(ctx: ^vi.Context, default_font_path: string = DEFAULT_FONT_PATH) -> (gui_root: ^GUIRoot, err: vi.Error) {
  fh := vi.load_font(ctx, default_font_path, 16) or_return

  gui_root = new(GUIRoot)
  gui_root.vctx = ctx

  gui_root.ctype = .GUIRoot
  gui_root.id = "GUIRoot"
  gui_root.parent = nil
  gui_root.visible = true
  gui_root.properties = { .Container }

  gui_root.default_font = fh

  gui_root.bounds.x = 0.0
  gui_root.bounds.y = 0.0
  gui_root.bounds.width = auto_cast ctx.swap_chain.extent.width
  gui_root.bounds.height = auto_cast ctx.swap_chain.extent.height

  // append(ctx.resize_callbacks, resize_callback) // TODO

  return
}

@(private) _destroy_control :: proc(ctx: ^vi.Context, control: rawptr) {
  #partial switch (cast(^_ControlInfo)control).ctype {
    case .GUIRoot:
      gui_root: ^GUIRoot = auto_cast control
      for child in gui_root.children {
        _destroy_control(ctx, child)
      }
      vi.destroy_font(ctx, gui_root.default_font)
      mem.free(control)
    case:
      fmt.println("Unsupported control type:", (cast(^_ControlInfo)control).ctype)
    case .Label:
      label: ^Label = auto_cast control
      mem.free(label)
    // case .Button:
    //   delete(control)
    // case .Textbox:
    //   delete(control)
  }
}

destroy_gui :: proc(ctx: ^vi.Context, gui_root: ^^GUIRoot) {
  _destroy_control(ctx, gui_root^)
  gui_root^ = nil
}

@(private)_get_gui_root :: proc(p_control: rawptr) -> (gui_root: ^GUIRoot) {
  cnfo: ^_ControlInfo = auto_cast p_control
  if cnfo.ctype == .GUIRoot {
    gui_root = auto_cast p_control
  } else {
    gui_root = _get_gui_root(cnfo.parent)
  }
  return
}

// @(private)_name_control :: proc(control: rawptr, name: string) {
//   cnfo: ^_ControlInfo = auto_cast control



//   cnfo.id = name
// }

create_label :: proc(parent: rawptr, name_id: string = "label") -> (label: ^Label, err: vi.Error) {
  // Obtain the gui root
  gui_root: ^GUIRoot = _get_gui_root(parent)
  
  // Create the label
  label = new(Label)

  // Set the control info
  label.ctype = .Label
  label.id = name_id
  // TODO parent check
  // _name_control(label, name_id) TODO -- proper name control
  label.parent = auto_cast parent
  append(&(cast(^_ContainerControlInfo)parent).children, auto_cast label)
  label.visible = true

  label.properties = { .TextRestrained }
  // label.bounds = vi.Rectf{0.0, 0.0, 80.0, 20.0}
  // label.bounds.left = 0.0
  // label.bounds.top = 0.0
  // label.bounds.right = 80.0
  // label.bounds.bottom = 20.0

  // Default Settings
  label._layout.min_width = 10;
  label._layout.min_height = 20;
  label._layout.padding = { 1, 1, 1, 1 }

  // Set the label info
  label.text = "Label"
  label.font = gui_root.default_font
  label.font_color = vi.Color{1.0, 1.0, 1.0, 1.0}
  label.background_color = vi.Color{0.0, 0.0, 0.0, 0.0}
  label.clip_text_to_bounds = false

  // label._layout.requires_layout_update = true

  return
}

// create_button :: proc(parent: rawptr, name_id: string) -> (button: ^Button, err: vi.Error) {
//   return
// }

// create_textbox :: proc(parent: rawptr, name_id: string) -> (textbox: ^Textbox, err: vi.Error) {
//   return
// }