(use jaylib)
(use /junk-drawer)

(init-window 1000 480 "Envelopes Visualizer")
(set-target-fps 30)
(hide-cursor)

(var *adsr* (envelopes/adsr
             :attack-target 200 :attack-duration 60 :attack-tween tweens/out-linear
             :decay-target 120 :decay-duration 40
             :release-duration 50 :release-tween tweens/in-out-quad))

(:trigger *adsr*)

(begin-drawing)
(clear-background 0x222034ff)

(for i 0 150
  (draw-circle (+ 20 (* i 4))
               (math/round (- 400 (:tick *adsr*)))
               3
               (match (*adsr* :current)
                 :idle 0xcbdbfcff
                 :attack 0x99e550ff
                 :decay 0xd95763ff
                 :sustain 0x5fcde4ff)))

(:release *adsr*)

(for i 150 200
  (draw-circle (+ 20 (* i 4))
               (math/round (- 400 (:tick *adsr*)))
               3 0xfbf236ff))
(end-drawing)

(while (not (window-should-close)) nil)

(close-window)
