(import spork/test)
(import /junk-drawer/gamestate)

(test/start-suite 0)
(var *GS* (gamestate/init))

(test/assert (= nil (:current *GS*)) "GS current state is nil to start.")
(test/assert-no-error "calling Update on nil state is ok."
                      (:update *GS* 1))
(test/assert-no-error "calling Draw on nil state is ok."
                      (:draw *GS*))

(gamestate/def-state state-a
   :init (fn ainit [self] (put self :init-called true))
   :enter (fn aenter[self from] (put self :enter-called true))
   :leave (fn aleave [self to] (put self :leave-called true))
   :update (fn aupdate [self dt] (put self :update-called true))
   :draw (fn adraw [self] (put self :draw-called true)))

(gamestate/def-state state-b
   :init (fn binit [self] (put self :init-b-called true))
   :enter (fn benter [self from] (put self :enter-b-called true))
   :leave (fn bleave [self to] (put self :leave-b-called true))
   :update (fn bupdate [self dt] (put self :update-b-called true))
   :draw (fn bdraw [self] (put self :draw-b-called true)))

(:add-state *GS* state-a)
(:add-state *GS* state-b)
(:add-edge *GS* (gamestate/transition :my-transition :state-a :state-b))

(:goto *GS* :state-a)
# (test/assert (state-a :init-called) "State A init called after switching.")
# (:update *GS* 2)
# (test/assert (state-a :update-called) "State A updated called.")
# (:draw *GS*)
# (test/assert (state-a :draw-called) "State A draw called.")

# (:my-transition *GS*)
# (test/assert (state-a :init-b-called) "State B init called after switching.")

# (:update *GS* 2)
# (test/assert (state-a :update-b-called) "State A updated called.")
# (:draw *GS*)
# (test/assert (state-a :draw-b-called) "State A draw called.")


(test/end-suite)
