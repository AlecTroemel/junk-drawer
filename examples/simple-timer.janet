(import /kitchen-sink/timer)

(def t (timer/init))

(:during t 5 (fn [h dt] (print " during 5, dt " dt)))
(:every t 2 (fn [h] (print "  every 2")))
(:after t 3 (fn [h] (print "  after 3")))

# Simulate dt ticking
(for dt 0 10
  (print "tick: " dt)
  (:update t 1))
