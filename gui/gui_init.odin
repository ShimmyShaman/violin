package violin_gui

import "core:c/libc"
import "core:fmt"
import "core:mem"
import "core:strings"

import sdl2 "vendor:sdl2"

import vi "violin:vsr"
ProcHandleGUIEvent :: proc(control: ^Control, event: ^sdl2.Event) -> (handled: bool, err: vi.Error)
ProcFrameUpdate :: proc(control: ^Control, dt: f32) -> vi.Error
ProcUpdateControlLayout :: proc(control: ^Control, available_area: vi.Rectf, update_x: bool = true, update_y: bool = true,
  update_width: bool = true, update_height: bool = true, update_children: bool = true)
ProcDetermineControlExtents :: proc(gui_root: ^GUIRoot, control: ^Control, restraints: LayoutExtentRestraints) -> vi.Error
ProcRenderControl :: proc (using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error)
ProcDestroyControl :: proc(ctx: ^vi.Context, control: ^Control)

ControlType :: enum {
  GUIRoot = 1,
  Label = 100,
  Button,
  Textbox,
  StackContainer,
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
  margin: Extent,

  determined_width_extent, determined_height_extent: f32,

  z_layer_index: int,
}

_ControlDelegates :: struct {
  update_control_layout: ProcUpdateControlLayout,
  determine_layout_extents: ProcDetermineControlExtents,
  handle_gui_event: ProcHandleGUIEvent,
  frame_update: ProcFrameUpdate,
  render_control: ProcRenderControl,
  destroy_control: ProcDestroyControl,
}

_ControlInfo :: struct {
  ctype: ControlType,
  using _layout: _ControlLayout,
  _delegates: _ControlDelegates,
  id: string,
  parent: ^_ContainerControlInfo,
  disabled, visible: bool,
  properties: ControlProperties,

  bounds: vi.Rectf,
}

_ContainerControlInfo :: struct {
  using _ctrlnfo: _ControlInfo,
  children: [dynamic]^Control,
}

GUIRoot :: struct {
  using _confo: _ContainerControlInfo,

  // The context this gui is created and rendered in
  vctx: ^vi.Context,
  default_font: vi.FontResourceHandle,
}

Control :: struct #raw_union {
  using _info: _ControlInfo,
  root: GUIRoot,
  label: Label,
  // button: Button,
  // textbox: Textbox,
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

create_gui_root :: proc(ctx: ^vi.Context, default_font_path: string = DEFAULT_FONT_PATH, default_font_size: f32 = 16) \
    -> (gui_root: ^GUIRoot, err: vi.Error) {
  fh := vi.load_font(ctx, default_font_path, default_font_size) or_return

  gui_root = new(GUIRoot)
  gui_root.vctx = ctx

  gui_root._delegates.determine_layout_extents = determine_layout_extents
  gui_root._delegates.render_control = nil
  gui_root._delegates.destroy_control = nil
  gui_root._delegates.update_control_layout = update_control_layout

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

destroy_gui :: proc(ctx: ^vi.Context, gui_root: ^^GUIRoot) {
  // Children
  for child in gui_root^.children {
    if child._delegates.destroy_control != nil {
      child._delegates.destroy_control(ctx, child)
    }
    mem.free(child)
  }

  vi.destroy_font(ctx, gui_root^.default_font)

  mem.free(gui_root^)
  gui_root^ = nil
}

@(private)_get_gui_root :: proc(p_control: rawptr) -> (gui_root: ^GUIRoot, err: vi.Error) {
  cnfo: ^_ControlInfo = auto_cast p_control
  if cnfo.ctype == .GUIRoot {
    gui_root = auto_cast p_control
  } else {
    gui_root = _get_gui_root(cnfo.parent) or_return
  }

  // todo("Handle case where control is not part of a gui")

  return
}

@(private) _add_control :: proc(parent: rawptr, control: ^_ControlInfo) -> (err: vi.Error) {
  // Obtain the gui root
  gui_root: ^GUIRoot = _get_gui_root(parent) or_return

  // Validate that all delegates are set
  if control._delegates.update_control_layout == nil {
    fmt.println("Missing GUI delegate: update_control_layout for control:", control.id)
    return .MissingGUIProcDelegate
  }
  if control._delegates.determine_layout_extents == nil {
    fmt.println("Missing GUI delegate: determine_layout_extents for control:", control.id)
    return .MissingGUIProcDelegate
  }
  if control._delegates.handle_gui_event == nil {
    fmt.println("Missing GUI delegate: handle_gui_event for control:", control.id)
    return .MissingGUIProcDelegate
  }
  if control._delegates.render_control == nil {
    fmt.println("Missing GUI delegate: render_control for control:", control.id)
    return .MissingGUIProcDelegate
  }
  if control._delegates.destroy_control == nil {
    fmt.println("Missing GUI delegate: destroy_control for control:", control.id)
    return .MissingGUIProcDelegate
  }
  
  // Set the parent
  control.parent = auto_cast parent
  iterative_count := 1
  unique_name_loop: for {
    // Create the name
    iterative_name: string
    if iterative_count == 1 {
      iterative_name = control.id
    } else {
      iterative_name = fmt.aprint(args={control.id, iterative_count}, sep = "")
    }
    
    // Iterate through children in other parent
    for child in control.parent.children {
      if child.id == iterative_name {
        if iterative_count > 1 do delete_string(iterative_name)
        iterative_count += 1
        continue unique_name_loop
      }
    }

    // Set
    control.id = iterative_name
    break
  }

  // Add the control to the parent children
  append(&(cast(^_ContainerControlInfo)parent).children, auto_cast control)

  // fmt.println("Added control:", control.id, "to parent:", (cast(^_ContainerControlInfo)parent).id)

  return
}