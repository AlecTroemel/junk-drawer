(import spork/test)
(import /junk-drawer/adsr)

(test/start-suite 0)

(let [*adsr* (adsr/create
             :attack-target 10 :attack-duration 10
             :decay-target 5 :decay-duration 10
             :sustain-duration 10
             :release-duration 10)]
  (test/assert (= (*adsr* :current) :idle) "starts in idle")

  (:begin *adsr*)
  (test/assert (= (*adsr* :current) :attack) "attack after begin")

  (for i 0 10 (:tick *adsr*))
  (test/assert (= (*adsr* :value) 10) "end of attack is 10")
  (test/assert (= (*adsr* :current) :decay) "decay after 10 ticks of attack")


  (for i 0 10 (:tick *adsr*))
  (test/assert (= (*adsr* :value) 5) "end of decay is 5")
  (test/assert (= (*adsr* :current) :sustain) "sustain after 10 ticks of decay")


  (for i 0 10 (:tick *adsr*))
  (test/assert (= (*adsr* :value) 5) "end of sustain is still 5")
  (test/assert (= (*adsr* :current) :release) "release after 10 ticks of sustain")

  (for i 0 10 (:tick *adsr*))
  (test/assert (= (*adsr* :value) 0) "end of sustain is 0")
  (test/assert (= (*adsr* :current) :idle) "idle after 10 ticks of release"))

(test/end-suite)
