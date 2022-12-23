(import spork/test)
(import /junk-drawer/ecs)
(import /junk-drawer/timers)
(import /junk-drawer/freeze)

# No tags
(test/start-suite 0)
(let [world (ecs/create-world)]
  (var called-count 0)
  (ecs/def-tag thing)

  (freeze/def-freeze-system counter []
    {things [:thing]}
    (+= called-count 1))

  (ecs/register-system world counter)
  (ecs/register-system world timers/update-sys)

  (ecs/add-entity world (thing))
  (freeze/freeze! world 2)

  (:update world 1)
  (test/assert (= called-count 0) "frozen after 1 tick")

  (:update world 1)
  (test/assert (= called-count 0) "frozen after 2 ticks")

  (:update world 1)
  (test/assert (= called-count 1) "not frozen after 3 ticks"))
(test/end-suite)

# With tags
(test/start-suite 1)
(let [world (ecs/create-world)]
  (var called-count 0)
  (var called2-count 0)
  (var called3-count 0)
  (ecs/def-tag thing)
  (ecs/def-tag freeze-tag)
  (ecs/def-tag dne-tag)

  (freeze/def-freeze-system counter []
                            {things [:thing]}
                            (+= called-count 1))

  (freeze/def-freeze-system counter-2 [:freeze-tag]
                            {things [:thing]}
                            (+= called2-count 1))

  (freeze/def-freeze-system counter-3 [:freeze-tag :dne-tag]
                            {things [:thing]}
                            (+= called3-count 1))

  (ecs/register-system world counter)
  (ecs/register-system world counter-2)
  (ecs/register-system world counter-3)
  (ecs/register-system world timers/update-sys)

  (ecs/add-entity world (thing))
  (freeze/freeze! world 2 (freeze-tag))

  (:update world 1)
  (test/assert (= called-count 0) "no tags, frozen by any freezer")
  (test/assert (= called2-count 0) "frozen by freezer with matching tag")
  (test/assert (= called3-count 1) "not frozen by freezer because doesnt match all tags")

  (:update world 1)
  (test/assert (= called-count 0) "no tags, frozen by any freezer")
  (test/assert (= called2-count 0) "frozen by freezer with matching tag")
  (test/assert (= called3-count 2) "not frozen by freezer because doesnt match all tags")

  (:update world 1)
  (test/assert (= called-count 1) "freezer gone")
  (test/assert (= called2-count 1) "freezer gone")
  (test/assert (= called3-count 3) "freezer gone but never mattered"))
(test/end-suite)
