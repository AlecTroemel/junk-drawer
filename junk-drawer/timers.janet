(use ./ecs)

(defn- noop [& args] nil)

(def-component timer
  [time limit count during after])

(def-system update-sys
  {timers [:entity :timer] wld :world}
  (each [ent tmr] timers
    (put tmr :time (+ (tmr :time) dt))
    ((tmr :during) wld dt)
    (when (and (>= (tmr :time) (tmr :limit))
               (> (tmr :count) 0))

      ((get tmr :after) wld dt)
      (put tmr :time (- (tmr :time) (tmr :limit)))
      (put tmr :count (- (tmr :count) 1)))
    (when (= 0 (tmr :count))
      (remove-entity wld ent))))

(defn after [world delay after-fn]
  "Schedule a fn to run after 'delay' seconds."
  (add-entity world (timer 0 delay 1 noop after-fn)))

(defn during [world delay during-fn &opt after-fn]
  "run during fn every 'delay' seconds, then optionally run after fn."
  (default after-fn noop)
  (add-entity world (timer 0 delay 1 during-fn after-fn)))

(defn every [world delay after-fn &opt count]
  "Schedule a fn to run every 'delay' seconds, up to count (default is infinity)."
  (default count math/inf)
  (add-entity world (timer 0 delay count noop after-fn)))
