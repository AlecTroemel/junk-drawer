(import /kitchen-sink/timer)

(def t (timer/init))

(:during t 5 (fn [h dt] (print " during 5, dt " dt)))
(:every t 2 (fn [h] (print "  every 2")))
(:after t 3 (fn [h] (print "  after 3")))

# you can even do tweening
(def color @{:r 0 :g 0 :b 0})
(:tween t 10 color {:r 255 :g 255 :b 255} :in-out-quad)

# Simulate dt ticking
(for dt 0 10
  (print "tick: " dt)
  (:update t 1))
