(use jaylib)
(use /junk-drawer)

(init-window 800 480 "Envelopes Visualizer")
(set-target-fps 30)
(hide-cursor)

(var *adsr* (envelopes/adsr
             :attack-target 200 :attack-duration 60 :attack-tween tweens/in-linear
             :decay-target 120 :decay-duration 40
             :release-duration 100 :release-tween tweens/in-out-quad))

(:trigger *adsr*)

(begin-drawing)
(clear-background 0x222034ff)

(for i 0 100
  (draw-circle (+ 20 (* i 4))
               (math/round (- 400 (:tick *adsr*)))
               3 0xcbdbfcff))

(:release *adsr*)

(for i 100 200
  (draw-circle (+ 20 (* i 4))
               (math/round (- 400 (:tick *adsr*)))
               3 0xcbdbfcff))
(end-drawing)

(while (not (window-should-close)) nil)

(close-window)
