(use /junk-drawer/ecs)

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

  This uses the ECS, and requires registering "timers/update-sys" system
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

  This uses the ECS, and requires registering "timers/update-sys" system
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

  This uses the ECS, and requires registering "timers/update-sys" system
  ```
  [world delay after-fn &opt count]

  (default count math/inf)
  (add-entity world
              (timer :time 0
                     :limit delay
                     :count count
                     :during noop
                     :after after-fn)))


# (defn- deep-delta [subject target]
#   "Creates a table of the same structure of target,
#    with the deltas between subject and target as the values"
#   (match (type target)
#     :number (- target subject)
#     :tuple (map
#             |(let [(i v) $]
#                (tween-deep-delta (subject i) v))
#             (pairs target))
#     :struct (table
#              ;(mapcat
#                |(let [(key val) $]
#                   [key (tween-deep-delta (subject key) val)])
#                (pairs target)))
#     _ nil))

# (defn- deep-update [subject delta ds]
#   ""
#   (match (type delta)
#     :number (+ subject (* delta ds))
#     :tuple (map
#             |(let [(i v) $]
#                (tween-deep-update (subject i) v ds))
#             (pairs delta))
#     :struct (table
#              ;(mapcat
#                |(let [(key val) $]
#                   [key (tween-deep-update (subject key) val ds)])
#                (pairs delta)))
#     _ nil))

# (defn- tween [self len subject target method after]
#   "tween the subject to target with the given method over the length"
#   (let [tween-fn (symbol "tweens/" method)
#                  deltas (tween-deep-delta subject target)
#                  during-fn (fn [handle dt]
#                              (let [h-time (get handle :time)
#                                           last-s (get handle :last-s 0)
#                                           s (tween-fn (min 1 (/ h-time len)))
#                                           ds (- s last-s)]
#                                (put handle :last-s s)
#                                (tween-deep-update subject deltas ds)))]
#     (:during self len during-fn after)))
