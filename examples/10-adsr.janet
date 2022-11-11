(use /junk-drawer)

# ADSR is short for Attack Decay Sustain Release.
# targets and durations are required,
# but tweens are optional (default to linear)
(var *adsr* (adsr/create
               :attack-target 50 :attack-duration 20 :attack-tween tweens/in-cubic
               :decay-target 25 :decay-duration 15
               :sustain-duration 10
               :release-duration 15 :release-tween tweens/in-out-quad))

# call begin on adsr to move it off the :idle  state
(:begin *adsr*)

# call tick to iterate to the next step
(for i 0 60
  (let [v (:tick *adsr*)]
    (for j 0 (math/round v) (prin "="))
    (print "")))
