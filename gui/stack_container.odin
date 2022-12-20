package violin_gui

import "core:fmt"
import la "core:math/linalg"
import mem "core:mem"

import vi "violin:vsr"

vec2 :: la.Vector2f32

StackOrientation :: enum {
  None = 0,
  Vertical,
  Horizontal,
}

StackContainer :: struct {
  using _confo: _ContainerControlInfo,

  _children_extents: vec2,

  orientation: StackOrientation,
  background_color: vi.Color,
}

create_stack_container :: proc(parent: ^Control, name_id: string = "StackContainer") -> (stack: ^StackContainer, err: vi.Error) {
  // Create the label
  stack = new(StackContainer)

  // Set the control info
  stack.ctype = .StackContainer
  stack.id = name_id
  stack.visible = true

  stack._delegates.determine_layout_extents = _determine_stack_container_extents
  stack._delegates.render_control = _render_stack_container
  stack._delegates.update_control_layout = update_control_layout
  stack._delegates.handle_gui_event = _handle_gui_event_default_rect
  stack._delegates.destroy_control = _destroy_stack_container

  stack.properties = { .Container }

  // Default Settings
  stack._layout.min_width = 8;
  stack._layout.min_height = 8;
  stack._layout.margin = { 1, 1, 1, 1 }

  // Set the stack container info
  stack.orientation = .None
  stack.background_color = vi.COLOR_DarkSlateGray

  // label._layout.requires_layout_update = true
  _add_control(parent, auto_cast stack) or_return

  return
}

@(private) _render_stack_container :: proc(using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error) {
  stack: ^StackContainer = auto_cast control

  if stack.background_color.a > 0.0 && stack.bounds.width > 0.0 && stack.bounds.height > 0.0 {
    vi.stamp_colored_rect(grc.rctx, grc.stamprr, &stack.bounds, &stack.background_color) or_return
  }

  // Children
  if stack.children != nil {
    for child in stack.children {
      if child._delegates.render_control != nil {
        child._delegates.render_control(grc, child)
      }
    }
  }

  return
}

@(private) _determine_stack_container_extents :: proc(gui_root: ^GUIRoot, control: ^Control, restraints: LayoutExtentRestraints) \
  -> (err: vi.Error) {
  stack: ^StackContainer = auto_cast control
  
  // Apply Orientation
  stack_restraints := restraints
  child_restraints: LayoutExtentRestraints
  switch stack.orientation {
    case .None:
      // Do nothing
    case .Horizontal:
      child_restraints = {.Horizontal}
      stack_restraints |= {.Horizontal}
    case .Vertical:
      child_restraints = {.Vertical}
      stack_restraints |= {.Vertical}
  }

  // Children
  stack._children_extents = {0, 0}
  if stack.children != nil {
    // Determine child extents
    for child in stack.children {
      if child._delegates.determine_layout_extents != nil {
        child._delegates.determine_layout_extents(gui_root, child, child_restraints)

        // Propagate to the stack_container
        if stack.orientation == .Horizontal {
          stack._children_extents.x += child._layout.determined_width_extent
        }
        else if child._layout.determined_width_extent > stack._children_extents.x {
          stack._children_extents.x = child._layout.determined_width_extent
        }
        if stack.orientation == .Vertical {
          stack._children_extents.y += child._layout.determined_height_extent
        }
        else if child._layout.determined_height_extent > stack._children_extents.y {
          stack._children_extents.y = child._layout.determined_height_extent
        }
      }
    }
  }

  // Determine Extents
  MAX_EXTENT_VALUE :: 1000000
  layout := &control._layout

  // -- Width
  if layout.preferred_width != 0 {
    // Set to preferred width
    layout.determined_width_extent = layout.preferred_width
  }
  else {
    if .Horizontal in restraints {
      // if layout.min_width != 0 {
      //   layout.determined_width_extent = layout.min_width
      // }
      // else {
      //   layout.determined_width_extent = 0
      // }
      layout.determined_width_extent = max(stack._children_extents.x, layout.min_width)
    }
    else {
      // padding adjusted from available
      layout.determined_width_extent = MAX_EXTENT_VALUE

      // Specified bounds
      if layout.min_width != 0 && layout.determined_width_extent < layout.min_width {
        layout.determined_width_extent = layout.min_width
      }
      if layout.max_width != 0 && layout.determined_width_extent > layout.max_width {
        layout.determined_width_extent = layout.max_width
      }

      if layout.determined_width_extent < 0 {
        layout.determined_width_extent = 0
      }
    }
  }

  // -- Height
  if layout.preferred_height != 0 {
    // Set to preferred height
    layout.determined_height_extent = layout.preferred_height
  }
  else {
    if .Vertical in restraints {
      // if layout.min_height != 0 {
      //   layout.determined_height_extent = layout.min_height
      // }
      // else {
      //   layout.determined_height_extent = 0
      // }
      layout.determined_height_extent = max(stack._children_extents.y, layout.min_height)
    }
    else {
      // padding adjusted from available
      layout.determined_height_extent = MAX_EXTENT_VALUE

      // Specified bounds
      if layout.min_height != 0 && layout.determined_height_extent < layout.min_height {
        layout.determined_height_extent = layout.min_height
      }
      if layout.max_height != 0 && layout.determined_height_extent > layout.max_height {
        layout.determined_height_extent = layout.max_height
      }

      if layout.determined_height_extent < 0 {
        layout.determined_height_extent = 0
      }
    }
  }

  return
}

@(private) _destroy_stack_container :: proc(ctx: ^vi.Context, control: ^Control) {
  stack: ^StackContainer = auto_cast control

  // Children
  for child in stack.children {
    if child._delegates.destroy_control != nil {
      child._delegates.destroy_control(ctx, child)
    }
    mem.free(child)
  }
}