package violin_gui

import "core:fmt"
import "core:mem"

import "vendor:sdl2"

import vi "violin:vsr"

LayoutExtentRestraints :: distinct bit_set[LayoutExtentRestraint; u8]
LayoutExtentRestraint :: enum(u8) {
  Horizontal,
  Vertical,
}

handle_gui_event :: proc(gui: ^GUIRoot, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
  return
}

update_gui :: proc(gui_root: ^GUIRoot) {
  if gui_root.children == nil do return

  _determine_control_and_children_extents(auto_cast gui_root, {})

  // Update the layout of each child
  for child in gui_root.children {
    _update_control_layout(child, gui_root.bounds)
  }
}

// int mca_determine_typical_node_extents_halt_propagation(mc_node *node, layout_extent_restraints restraints)
// {
mca_determine_control_extents :: proc(control: ^Control, restraints: LayoutExtentRestraints) {
  MAX_EXTENT_VALUE :: 1000000
  layout := &control._layout

  fmt.println("Determine extents for control: ", control._info)

  // Width
  if layout.preferred_width != 0 {
    // Set to preferred width
    layout.determined_width_extent = layout.preferred_width
  }
  else {
    if .Horizontal in restraints {
      if layout.min_width != 0 {
        layout.determined_width_extent = layout.min_width
      }
      else {
        layout.determined_width_extent = 0
      }
    }
    else {
      // Padding adjusted from available
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

  // Height
  if layout.preferred_height != 0 {
    // Set to preferred height
    layout.determined_height_extent = layout.preferred_height
  }
  else {
    if .Vertical in restraints {
      if layout.min_height != 0 {
        layout.determined_height_extent = layout.min_height
      }
      else {
        layout.determined_height_extent = 0
      }
    }
    else {
      // Padding adjusted from available
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
}

_determine_control_and_children_extents :: proc(control: ^Control, restraints: LayoutExtentRestraints) {
  mca_determine_control_extents(control, restraints)

  // Containers
  if .Container not_in control.properties do return 
  
  container: ^_ContainerControlInfo = auto_cast control
  if container.children == nil do return

  // Foreach container child
  for child in container.children {
    if .TextRestrained in child.properties {
      _determine_text_restrained_control_and_children_extents(child, restraints)
    }
    else {
      _determine_control_and_children_extents(child, restraints)
    }
  }
}

// int mca_update_typical_node_layout_partially(mc_node *node, mc_rectf const *available_area, bool update_x,
//   bool update_y, bool update_width, bool update_height, bool update_children)
_update_control_layout :: proc(control: ^Control, available_area: vi.Rectf, update_x: bool = true, update_y: bool = true,
    update_width: bool = true, update_height: bool = true, update_children: bool = true) {

  next: vi.Rectf
  layout: ^_ControlLayout = &control._info._layout
  layout.requires_layout_update = false  
    
  // Width
  if update_width {
    // Width
    if layout.preferred_width != 0.0 {
      // Set to preferred width
      next.width = layout.preferred_width
    }
    else {
      // Padding adjusted from available
      next.width = available_area.width - layout.padding.right - layout.padding.left
    }
  }

  // Apply the determined extent
  if next.width > layout.determined_width_extent {
    next.width = layout.determined_width_extent
  }

  if next.width != control.bounds.width {
    control.bounds.width = next.width
    // TODO -- change/rerender flag?
  }

  // Height
  if update_height {
    // Height
    if layout.preferred_height != 0.0 {
      // Set to preferred height
      next.height = layout.preferred_height
    }
    else {
      // Padding adjusted from available
      next.height = available_area.height - layout.padding.top - layout.padding.bottom
    }
  }
  
  // Apply the determined extent
  if next.height > layout.determined_height_extent {
    next.height = layout.determined_height_extent
  }
  
  if next.height != control.bounds.height {
    control.bounds.height = next.height
    // TODO -- change/rerender flag?
  }

  // Left
  if update_x {
    switch layout.horizontal_alignment {
      case .Left:
        next.x = available_area.x + layout.padding.left
      case .Right:
        next.x = available_area.x + available_area.width - layout.padding.right - next.width
      case .Centred:
        next.x = available_area.x + layout.padding.left +
          (available_area.width - (layout.padding.left + next.width + layout.padding.right)) / 2.0
    }

    if next.x != control.bounds.x {
      control.bounds.x = next.x
      // TODO -- change/rerender flag?
    }
  }

  // Top
  if update_y {
    switch layout.vertical_alignment {
      case .Top:
        next.y = available_area.y + layout.padding.top
      case .Bottom:
        next.y = available_area.y + available_area.height - layout.padding.bottom - next.height
      case .Centred:
        next.y = available_area.y + layout.padding.top +
          (available_area.height - (layout.padding.bottom + next.height + layout.padding.top)) / 2.0
    }

    if next.y != control.bounds.y {
      control.bounds.y = next.y
      // TODO -- change/rerender flag?
    }
  }

  // Children
  if !update_children do return
  
  switch control.ctype {
    // Non-container controls have no children
    case .Button, .Label, .Textbox:
      return
    case .GUIRoot: // TODO -- GUIRoot should not be passed to this method, place it here till another container control is created
      as_parent: ^_ContainerControlInfo = cast(^_ContainerControlInfo)control
      if as_parent.children != nil {
        for child in as_parent.children {
          fmt.println("Updating child: ", child)
          // _update_control_layout(child, control.bounds)
        }
      }
  }

  return
}