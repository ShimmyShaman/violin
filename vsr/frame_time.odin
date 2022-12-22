package graphics

// import "core:os"
import "core:fmt"
// import "core:c/libc"
// import "core:mem"
// import "core:sync"
// import "core:strings"
import "core:time"

FrameTime :: struct {
  _prev_fps_check: f32,

  init_time: time.Time,
  prev_frame_time: time.Time,
  now: time.Time,
  
  min_fps, max_fps: int,
  recent_frame_count, historical_frame_count: int,
  frame_elapsed, total_elapsed: f32,
}

init_frame_time :: proc(using frame_time: ^FrameTime) {
  init_time = time.now()
  prev_frame_time = init_time
  now = init_time

  min_fps = 10000000
  max_fps = 0
}

frame_time_update :: proc(using frame_time: ^FrameTime) {
  now = time.now()
  frame_elapsed = auto_cast time.duration_seconds(time.diff(prev_frame_time, now))
  total_elapsed += frame_elapsed
  prev_frame_time = now

  // if now._nsec / 1000000000 > last {
  //   last = auto_cast (now._nsec / 1000000000)
  //   // fmt.println("cpy len(lnc.manifest.transfer.data):", len(lnc.manifest.transfer.data))
  // }

  if total_elapsed - _prev_fps_check >= 1.0 {
    historical_frame_count += recent_frame_count
    max_fps = max(max_fps, recent_frame_count)
    min_fps = min(min_fps, recent_frame_count)
    defer recent_frame_count = 0

    @(static) mod := 0
    if mod += 1; mod % 10 == 3 {
      fmt.println("fps:", recent_frame_count)
      // break loop
    }
    
    _prev_fps_check = total_elapsed
  }

  recent_frame_count += 1
}