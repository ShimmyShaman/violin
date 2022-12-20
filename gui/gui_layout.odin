package violin_gui

import "core:c"
import "core:fmt"
import "core:mem"

import "vendor:sdl2"

import vi "violin:vsr"

LayoutExtentRestraints :: distinct bit_set[LayoutExtentRestraint; u8]
LayoutExtentRestraint :: enum(u8) {
  Horizontal,
  Vertical,
}

update_gui :: proc(gui_root: ^GUIRoot) -> (err: vi.Error) {
  if gui_root.children == nil do return

  gui_root._delegates.determine_layout_extents(gui_root, auto_cast gui_root, {}) or_return

  // Update the layout of each child
  w, h: c.int
  sdl2.GetWindowSize(gui_root.vctx.window, &w, &h) // TODO -- this should be updated by swapchain resize callback instead?
  gui_root._delegates.update_control_layout(auto_cast gui_root, vi.Rectf{0, 0, auto_cast w, auto_cast h})

  return
}

determine_layout_extents :: proc(gui_root: ^GUIRoot, control: ^Control, restraints: LayoutExtentRestraints) -> vi.Error {
  MAX_EXTENT_VALUE :: 1000000
  layout := &control._layout

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
  // fmt.println("Determined extents for control: ", control.ctype, " - ", layout.determined_width_extent, "x", layout.determined_height_extent)

  if .Container in control.properties {
    // Determine extents for each child
    container: ^_ContainerControlInfo = auto_cast control
    if container.children != nil {
      for child in container.children {
        child._delegates.determine_layout_extents(gui_root, child, restraints)
      }
    }
  }

  return .Success
}

determine_text_restrained_control_extents :: proc(gui_root: ^GUIRoot, control: ^Control, restraints: LayoutExtentRestraints,
  text_width, text_height: f32) -> vi.Error {
  layout := &control._layout

  // fmt.println("Determined text dimensions for control: ", control.ctype, " - ", str_width, "x", str_height)

  // Width
  if layout.preferred_width != 0 {
    // Set to preferred width
    layout.determined_width_extent = layout.preferred_width
  }
  else {
    if .Horizontal in restraints {
      layout.determined_width_extent = max(max(layout.min_width, text_width), 0.0)
    }
    else {
      // Padding adjusted from available
      layout.determined_width_extent = text_width

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
      layout.determined_height_extent = max(max(layout.min_height, text_height), 0.0)
    }
    else {
      // Padding adjusted from available
      layout.determined_height_extent = text_height

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

  if .Container in control.properties {
    // Determine extents for each child
    container: ^_ContainerControlInfo = auto_cast control
    if container.children != nil {
      for child in container.children {
        child._delegates.determine_layout_extents(gui_root, child, restraints)
      }
    }
  }

  // fmt.println("Determined extents for control: ", control.ctype, " - ", layout.determined_width_extent, "x", layout.determined_height_extent)
  return .Success
}

// int mca_update_typical_node_layout_partially(mc_node *node, mc_rectf const *available_area, bool update_x,
//   bool update_y, bool update_width, bool update_height, bool update_children)
update_control_layout :: proc(control: ^Control, available_area: vi.Rectf, update_x: bool = true, update_y: bool = true,
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
      next.width = available_area.width - layout.margin.right - layout.margin.left
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
      next.height = available_area.height - layout.margin.top - layout.margin.bottom
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
        next.x = available_area.x + layout.margin.left
      case .Right:
        next.x = available_area.x + available_area.width - layout.margin.right - next.width
      case .Centred:
        next.x = available_area.x + layout.margin.left +
          (available_area.width - (layout.margin.left + next.width + layout.margin.right)) / 2.0
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
        next.y = available_area.y + layout.margin.top
      case .Bottom:
        next.y = available_area.y + available_area.height - layout.margin.bottom - next.height
      case .Centred:
        next.y = available_area.y + layout.margin.top +
          (available_area.height - (layout.margin.bottom + next.height + layout.margin.top)) / 2.0
    }

    if next.y != control.bounds.y {
      control.bounds.y = next.y
      // TODO -- change/rerender flag?
    }
  }
  // fmt.println("Determined layout for control: ", control.ctype, " - ", control.bounds)

  // Children
  if .Container in control.properties {
    // Determine extents for each child
    container: ^_ContainerControlInfo = auto_cast control
    if container.children != nil {
      for child in container.children {
        child._delegates.update_control_layout(child, control.bounds)
      }
    }
  }

  return
}