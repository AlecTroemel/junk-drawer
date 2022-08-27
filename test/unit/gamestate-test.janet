(import spork/test)
(import /junk-drawer/gamestate)

(test/start-suite 0)
(var *GS* (gamestate/init))

(test/assert (= nil (:current *GS*)) "GS current state is nil to start.")
(test/assert-no-error "calling Update on nil state is ok."
                      (:update *GS*))
(test/assert-no-error "calling Draw on nil state is ok."
                      (:draw *GS*))

(var state-a @{:init (fn [self] (put self :init-called true))
               :enter (fn [self prev & args] (put self :enter-called true))
               :leave (fn [self from] (put self :leave-called true))
               :resume (fn [self prev & args] (put self :resume-called true))
               :update (fn [self dt] (put self :update-called true))
               :draw (fn [self] (put self :draw-called true))})

(:switch *GS* state-a)
(test/assert (state-a :init-called) "State A init called after switching.")

(:update *GS* 2)
(test/assert (state-a :update-called) "State A updated called.")

(:draw *GS*)
(test/assert (state-a :draw-called) "State A draw called.")

(:push *GS* {})
(:pop *GS*)
(test/assert (state-a :resume-called) "State A resume called.")

(:switch *GS* {})
(test/assert (state-a :leave-called) "State A leave called.")

(test/end-suite)
