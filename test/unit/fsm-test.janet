(import spork/test)
(import /junk-drawer/fsm)

(test/start-suite 0)

(var enter-c-called false)
(var leave-c-called false)

(fsm/define
 a2b
 (fsm/state :a)
 (fsm/transition :goto-b :a :b)
 (fsm/transition :goto-c :a :c)

 (fsm/state :b :field "value")
 (fsm/transition :goto-a :b :a)

 (fsm/state :c
    :enter (fn [self] (set enter-c-called true))
    :leave (fn [self] (set leave-c-called true)))
 (fsm/transition :goto-a :b :a))

(let [*state* (a2b :a)]
  (test/assert (= :a (*state* :current)) "Start at state A.")
  (:goto-b *state*)
  (test/assert (= :b (*state* :current)) "In state B after moving to it.")
  (test/assert (= "value" (*state* :field)) "Copies state data to root of FSM.")
  (:goto-a *state* "arg data")
  (test/assert (= :a (*state* :current)) "Move back to state A, with arg passed in.")
  (test/assert (= (*state* :field) nil) "no more data from state B.")

  (test/assert-error "transition fn does not exist"
                     (:goto-dne *state*))

  (:goto-c *state*)
  (test/assert enter-c-called "Enter fn for state C called.")
  (:goto-a *state*)
  (test/assert leave-c-called "Leave fn for state C called."))

(test/end-suite)
