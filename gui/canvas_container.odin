package violin_gui

import "core:fmt"
import la "core:math/linalg"
import mem "core:mem"

import vi "violin:vsr"

vec2 :: la.Vector2f32

CanvasContainer :: struct {
  using _confo: _ContainerControlInfo,

  _children_extents: vec2,

  background_color: vi.Color,
}

create_canvas_container :: proc(parent: ^Control, name_id: string = "CanvasContainer") -> (canvas: ^CanvasContainer, err: vi.Error) {
  // Create the canvas container
  canvas = new(CanvasContainer)

  // Set the control info
  canvas.ctype = .CanvasContainer
  canvas.id = name_id
  canvas.visible = true

  canvas._delegates.handle_gui_event = _handle_gui_event_container_default_rect
  canvas._delegates.frame_update = _frame_update_canvas_container
  canvas._delegates.determine_layout_extents = _determine_canvas_container_extents
  canvas._delegates.update_control_layout = _update_canvas_container_layout
  canvas._delegates.render_control = _render_canvas_container
  canvas._delegates.destroy_control = _destroy_canvas_container

  canvas.properties = { .Container }

  // Default Settings
  canvas._layout.min_width = 8;
  canvas._layout.min_height = 8;
  canvas._layout.margin = { 1, 1, 1, 1 }

  canvas.background_color = vi.COLOR_DarkSlateGray

  _add_control(parent, auto_cast canvas) or_return

  set_control_requires_layout_update(auto_cast canvas)

  return
}

@(private) _frame_update_canvas_container :: proc(control: ^Control, dt: f32) -> (err: vi.Error) {
  canvas: ^CanvasContainer = auto_cast control

  // Update the children
  for i := len(canvas.children) - 1; i >= 0; i -= 1 {
    child := canvas.children[i]
    if child._delegates.frame_update != nil {
      child._delegates.frame_update(child, dt)
    }
  }

  return
}

// Placeholder for determining layout extents for the CanvasContainer
@(private) _determine_canvas_container_extents :: proc(gui_root: ^GUIRoot, control: ^Control, restraints: LayoutExtentRestraints) -> (err: vi.Error) {
  canvas: ^CanvasContainer = auto_cast control

  // Initialize variables to hold the calculated extents
  canvas._children_extents = {0, 0}

  if canvas.children != nil {
    // Determine child extents
    for child in canvas.children {
      if child._delegates.determine_layout_extents != nil {
        child._delegates.determine_layout_extents(gui_root, child, restraints)

        // Update canvas extents based on children
        canvas._children_extents.x = max(canvas._children_extents.x, child._layout.determined_width_extent)
        canvas._children_extents.y = max(canvas._children_extents.y, child._layout.determined_height_extent)
      }
    }
  }

  // Calculate container extents based on children's sizes
  container_width := canvas._children_extents.x + 2 * canvas._layout.margin.x
  container_height := canvas._children_extents.y + 2 * canvas._layout.margin.y

  // Set the determined extents for the CanvasContainer
  canvas._layout.determined_width_extent = container_width
  canvas._layout.determined_height_extent = container_height

  return
}

// Placeholder for updating layout for the CanvasContainer
@(private) _update_canvas_container_layout :: proc(control: ^Control, available_area: vi.Rectf, update_x: bool = true, update_y: bool = true, update_width: bool = true, update_height: bool = true, update_children: bool = true) {
  // TODO: Implement update layout for CanvasContainer
  // Placeholder code here
}

// Placeholder for rendering the CanvasContainer
@(private) _render_canvas_container :: proc(using grc: ^GUIRenderContext, control: ^_ControlInfo) -> (err: vi.Error) {
  // TODO: Implement rendering for CanvasContainer
  // Placeholder code here

  return
}

// Placeholder for destroying the CanvasContainer
@(private) _destroy_canvas_container :: proc(ctx: ^vi.Context, control: ^Control) {
  // TODO: Implement destruction for CanvasContainer
  // Placeholder code here
}
