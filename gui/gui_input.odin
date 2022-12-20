package violin_gui

import "core:c"
import "core:fmt"
import "core:mem"
import "core:strings"

import "vendor:sdl2"

import vi "violin:vsr"

handle_gui_event :: proc(control: ^GUIRoot, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
  
  // Propagate to children
  handled, err = _propagate_handle_gui_event_to_children(auto_cast control, event)

  return
}

_propagate_handle_gui_event_to_children :: proc(control: ^Control, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
  container: ^_ContainerControlInfo = auto_cast control

  // Children
  for child in container.children {
    handled, err = child._delegates.handle_gui_event(child, event)
    
    if err != .Success || handled do return
  }

  return
}

_handle_gui_event_container_default_rect :: proc(control: ^Control, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
 
  // Propagate to children
  handled, err = _propagate_handle_gui_event_to_children(control, event)
  if err != .Success || handled do return

  // Container Base
  handled, err = _handle_gui_event_default_rect(control, event)
  return
}

_handle_gui_event_default_rect :: proc(control: ^Control, event: ^sdl2.Event) -> (handled: bool, err: vi.Error) {
  // Test if event is within control rect


  #partial switch event.type {
    case .MOUSEMOTION:
      x: f32 = auto_cast event.motion.x
      y: f32 = auto_cast event.motion.y
      if x >= control.bounds.x && x < control.bounds.x + control.bounds.width && y >= control.bounds.y && y < control.bounds.y +
          control.bounds.height {
        // Do nothing
        handled = true
      }
    case .MOUSEBUTTONDOWN:
      x: f32 = auto_cast event.button.x
      y: f32 = auto_cast event.button.y
      if x >= control.bounds.x && x < control.bounds.x + control.bounds.width && y >= control.bounds.y && y < control.bounds.y +
          control.bounds.height {
        // Handled
        handled = true

        // Set Focus To Control
        err = focus_control(control)
      }
    case .KEYMAPCHANGED,
         .KEYDOWN,
         .KEYUP,
         .TEXTINPUT,
         .TEXTEDITING,
         .MOUSEBUTTONUP,
         .MOUSEWHEEL:
      // Handled
      handled = true
    case:
      fmt.println("Unhandled GUI Event:", event.type, " - ", control.ctype)
      err = .NotYetImplemented
      return
  }

  return
}

get_control_path :: proc(control: ^Control) -> (path: string) {
  path = control.id

  parent: ^_ContainerControlInfo = control.parent
  for parent != nil {
    path = strings.join({parent.id, path}, "->")
    parent = parent.parent
  }

  return
}

focus_control :: proc(control: ^Control) -> (err: vi.Error) {
  fmt.println("focus_control:", get_control_path(control))

  if control.parent == nil && control.ctype != .GUIRoot {
    // TODO
    fmt.println("Cannot focus control that is not attached to a GUI Root")
    err = .UnattachedToGUIRoot
    return
  }

  // Set Focus Status on all parent nodes
  hco: ^Control = control
  for {
    hpr: ^_ContainerControlInfo = auto_cast hco.parent

    // Set Child Focus
    hpr.focused_child = hco

    // Update layout
    // hn_parent.layout.__requires_rerender = true

    // fmt.println("children before:")
    // for cch in hpr.children {
    //   fmt.println("  ", cch.id, " - ", cch.z_layer_index)
    // }

    // Find the child in the parents children and set it to the highest index amongst its z-index equals or lessers
    found: bool = false
    for i := 0; i < len(hpr.children); i += 1 {
      if hpr.children[i] == hco {
        found = true

        if i + 1 == len(hpr.children) do break

        j := i + 1
        for j < len(hpr.children) {
          if hpr.children[j].z_layer_index > hco.z_layer_index {
            break
          }
          j += 1
        }
        j -= 1
        // fmt.println("focus_control: Moving control from", i, "to", j)

        // Set the control into the new index
        for k := i; k < j; k += 1 {
          hpr.children[k] = hpr.children[k + 1]
        }
        hpr.children[j] = hco
      }
    }

    // fmt.println("children after:")
    // for cch in hpr.children {
    //   fmt.println("  ", cch.id, " - ", cch.z_layer_index)
    // }

    if !found {
      fmt.println("Internal Error: Could not find control in parent's children")
      err = .NotYetDetailed
      return
    }

    // Root Check
    if hpr.ctype == .GUIRoot do break

    // Continue
    hco = auto_cast hpr
  }

  // fmt.println("focus_control: Done")

  return
}
// int mca_focus_node(mc_node *node_to_focus)
// {
//   // Set Focus Status on all parent nodes
//   mc_node *hnode = node_to_focus, *hn_parent;
//   do {
//     hn_parent = hnode->parent;

//     // Set Child Focus
//     if (!hn_parent->layout) {
//       MCerror(9664, "Cannot set focus to node with an ancestor without an initialized layout");
//     }
//     hn_parent->layout->focused_child = hnode;

//     // Update layout
//     hn_parent->layout->__requires_rerender = true;
    
//     // Find the child in the parents children and set it to the highest index amongst its z-index equals or lessers
//     mc_node_list *parents_children = hn_parent->children;
//     bool found = false;
//     for (int i = 0; i < parents_children->count; ++i) {
//       if (parents_children->items[i] == hnode) {
//         found = true;

//         if (i + 1 == parents_children->count)
//           break;

//         int j = i + 1;
//         for (; j < parents_children->count; ++j) {
//           if (parents_children->items[j]->layout &&
//               hnode->layout->z_layer_index < parents_children->items[j]->layout->z_layer_index) {
//             break;
//           }
//         }
//         --j;

//         if (j > i) {
//           // Change Child Order
//           for (int k = i; k < j; ++k) {
//             parents_children->items[k] = parents_children->items[k + 1];
//           }

//           parents_children->items[j] = hnode;
//         }
//       }
//     }

//     if(!found) {
//       printf("mca_focus_node():\n - node_to_focus:");
//       puts("! Couldn't find node in parents children !");
//       printf(" - node_to_focus:");
//       mc_print_node_path(node_to_focus);
//       puts("");
//       printf(" - parent:");
//       mc_print_node_path(hn_parent);
//       puts("");
//       printf(" - node:");
//       mc_print_node_path(hnode);
//       puts("");

//       MCerror(5857, "Couldn't find node in parents children");
//     }

//     // Set the midge-root focus status information
//     if(hn_parent->type == NODE_TYPE_GLOBAL_ROOT) {
//       switch (hnode->type)
//       {
//       case NODE_TYPE_CONSOLE_APP:
//       case NODE_TYPE_VISUAL_PROJECT:
//         app_info->focus_status.project = hnode;
//         app_info->focus_status.project_target = node_to_focus;
//         break;
//       case NODE_TYPE_MODULE_ROOT:
//         app_info->focus_status.module = hnode;
//         app_info->focus_status.module_target = node_to_focus;
//         break;
//       default:
//       // puts("******************");
//       // printf(" - parent:");
//       // mc_print_node_path(hn_parent);
//       // puts("");
//       // printf(" - node:");
//       // mc_print_node_path(hnode);
//       // puts("");
//         MCerror(5857, "Nodes attached to global root should only be a project node or module node: '%i'", hnode->type);
//       }
//       break;
//     }

//     // Continue
//     hnode = hn_parent;

//   } while(1);

//   // printf(" - module_focus:");
//   // mc_print_node_path(app_info->focus_status.module_target);
//   // puts("");
//   // printf(" - project_focus:");
//   // mc_print_node_path(app_info->focus_status.project_target);
//   // puts("");

//   return 0;
// }
