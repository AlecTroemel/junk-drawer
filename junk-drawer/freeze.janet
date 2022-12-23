(use ./ecs)
(use ./timers)

(setdyn :doc ```
A common game "juice" is to use freeze frames, this module provides an framework for
that built on top the ECS and timers modules. Define systems that will only execute
when there is no "freezer" entity that matches component tags.

NOTE: To use this module you must register the timers update system
      (register-system world timers/update-sys)
```)

(def-tag freezer)

(defmacro def-freeze-system
  ```
  Define a new freezable system. only eval the body when there is a
  frezzer ent with the matching tags/components. Adding tags makes the
  freezer entity requirement more specific, which means an empty list
  will cause the system to freeze for ANY freezer, regardless of tags.

  (def-tag hotdog)

  (def-freeze-system pizza [:hotdog]
      {moveables [:position :velocity]}
      (each [pos vel] moveables
          (pp pos)))

  (freeze! world 10 (hotdog))
  ```
  [name tags queries & body]
  ~(as-macro ,def-system ,name
     ,(merge queries {'freezers ~[:freezer ,;tags]})
     (when (empty? freezers)
       ,;body)))

(defn freeze! [world ticks & tags]
  ```
  Create a new freeze entity that will last for "tick" ticks.
  tags can be any component, but it usually makes the most sense to just use def-tag's

  (def-tag hotdog)

  (freeze! world 10 (hotdog))
  ```
  (let [ent (add-entity world (freezer) ;tags)]
    (after world ticks (fn [wld dt] (remove-entity wld ent)))))
