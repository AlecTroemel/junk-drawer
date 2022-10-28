(import spork/test)

(use /junk-drawer/ecs)

(test/start-suite 0)
(var a-counter 0)
(var b-counter 0)

(var world (create-world))

(def-component a :val :number)
(def-component-alias b a)

(def-system ab-sys
  {abs [:a :b]}
  (each ab abs
    (+= a-counter 1)
    (+= b-counter 1)))

(def-system b-sys
  {bs [:b]}
  (each b-ent bs
    (+= b-counter 1)))

(register-system world ab-sys)
(register-system world b-sys)

(add-entity world
            (a :val 1)
            (b :val 1))

(:update world 1)
(test/assert (= a-counter 1) "tick 1: a count should be 1")
(test/assert (= b-counter 2) "tick 1: b count should be 2")

(test/end-suite)
