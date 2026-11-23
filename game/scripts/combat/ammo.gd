extends RefCounted
## Five shots, then a complete reload after 30 seconds of active game time.
const CAPACITY = 5
const RELOAD_SECONDS = 30.0
const SHOT_INTERVAL = 0.3
var remaining: int = CAPACITY
var reload_left: float = 0.0
var shot_wait: float = 0.0
func can_fire() -> bool:
 return remaining > 0 and reload_left <= 0.0 and shot_wait <= 0.0
func fire() -> bool:
 if not can_fire(): return false
 remaining -= 1
 shot_wait = SHOT_INTERVAL
 if remaining == 0: reload_left = RELOAD_SECONDS
 return true
func advance(delta: float) -> void:
 if delta <= 0 or not is_finite(delta): return
 shot_wait = maxf(0.0, shot_wait - delta)
 if reload_left > 0:
  reload_left = maxf(0.0, reload_left - delta)
  if reload_left == 0: remaining = CAPACITY
func label() -> String:
 return "Herladen %ds" % ceili(reload_left) if reload_left > 0 else "%d/%d" % [remaining, CAPACITY]
