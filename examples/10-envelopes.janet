(use /junk-drawer)

(defn print-bar [v]
  (for j 0 (math/round v) (prin "="))
  (print ""))

# Envelopes are multi-state tweens. Lets look at the most complicated one, ADSR
#
# ADSR is short for Attack Decay Sustain Release. Targets and durations are required,
# but tweens are optional (default to linear).
(var *adsr* (envelopes/adsr
               :attack-target 50 :attack-duration 20 :attack-tween tweens/in-cubic
               :decay-target 25 :decay-duration 15
               :release-duration 15 :release-tween tweens/in-out-quad))

# call begin on adsr to move it off the :idle  state
(:trigger *adsr*)

# call tick to iterate to the next step.. though we'll get trapped in the sustain state
(for i 0 40 (print-bar (:tick *adsr*)))

(:release *adsr*)
(print "RELEASED")

(for i 0 15 (print-bar (:tick *adsr*)))

# There are also the simpler ASR and AR envelopes.
# ALSO, you can release or (re)trigger early from any relevent state
