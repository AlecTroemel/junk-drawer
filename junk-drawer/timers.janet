(use /junk-drawer/ecs)

(setdyn :doc ```
Its common to want to delay the execution of something an amount of time,
or to run something at an interval. This module contains building blocks
for just that! Simply register the update system

(register-system world timers/update-sys)

then create your timers.
```)

(defn- noop [& args] nil)

(def-component timer
  :time :number
  :limit :number
  :count :number
  :during :function
  :after :function)

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

(defn after
  ```
  Schedule a fn to run once after 'delay' ticks. the provided callback
  has the signature (fn [world dt] nil).

  (timers/after world 10 (fn [wld dt] (print "10 ticks have passed")))
  ```
  [world delay after-fn]

  (add-entity world
              (timer :time 0
                     :limit delay
                     :count 1
                     :during noop
                     :after after-fn)))

(defn during
  ```
  Schedule a during-fn to run every tick until 'delay' ticks have passed,
  then optionally run after-fn. Both callbacks have the signature
  (fn [world dt] nil).

  (timers/during world 5
               (fn [wld dt] (print "0-5 ticks"))
               (fn [wld dt] (print "5 ticks have passed")))
  ```
  [world delay during-fn &opt after-fn]

  (default after-fn noop)
  (add-entity world
              (timer :time 0
                     :limit delay
                     :count 1
                     :during during-fn
                     :after after-fn)))

(defn every
  ```
  Schedule a fn to run every 'delay' ticks, up to count (default is infinity).
  Callback has the signature (fn [world dt] nil).

  (timers/every world 2
              (fn [wld dt] (print "every 2, but only 3 times"))
              3)
  ```
  [world delay after-fn &opt count]

  (default count math/inf)
  (add-entity world
              (timer :time 0
                     :limit delay
                     :count count
                     :during noop
                     :after after-fn)))
