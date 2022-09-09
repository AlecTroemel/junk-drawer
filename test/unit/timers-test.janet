(import spork/test)
(import /junk-drawer/ecs)
(import /junk-drawer/timers)

# timers/after
(test/start-suite 0)
(let [world (ecs/create-world)]
  (ecs/register-system world timers/update-sys)
  (var called-count 0)

  (timers/after world 2
                (fn [wld dt] (+= called-count 1)))

  (:update world 1)
  (test/assert (= called-count 0) "After callback NOT called after 1 tick")
  (:update world 1)
  (test/assert (= called-count 1) "After callback called once after 2 ticks")
  (:update world 1)
  (test/assert (= called-count 1) "After callback still called once after 3 ticks"))
(test/end-suite)

# timers/during
(test/start-suite 1)
(let [world (ecs/create-world)]
  (ecs/register-system world timers/update-sys)
  (var called-count 0)

  (timers/during world 3
                 (fn [wld dt] (+= called-count 1))
                 (fn [wld dt] (+= called-count 1)))

  (:update world 1)
  (test/assert (= called-count 1) "tick 1: called 1")
  (:update world 1)
  (test/assert (= called-count 2) "tick 2: called 2")
  (:update world 1)
  (test/assert (= called-count 4) "tick 3: called 4"))
(test/end-suite)

# timers/after
(test/start-suite 2)
(let [world (ecs/create-world)]
  (ecs/register-system world timers/update-sys)
  (var called-count 0)

  (timers/every world 2
                (fn [wld dt] (+= called-count 1))
                4)

  (:update world 1)
  (test/assert (= called-count 0) "tick 1: called 0")
  (:update world 1)
  (test/assert (= called-count 1) "tick 2: called 1")
  (:update world 1)
  (test/assert (= called-count 1) "tick 3: called 1")
  (:update world 1)
  (test/assert (= called-count 2) "tick 4: called 2")
  (:update world 1)
  (:update world 1)
  (test/assert (= called-count 3) "tick 6: called 3")
  (:update world 1)
  (:update world 1)
  (test/assert (= called-count 4) "tick 8: called 4")
  (:update world 1)
  (:update world 1)
  (test/assert (= called-count 4) "tick 8: still called 4, since all done"))
(test/end-suite)
