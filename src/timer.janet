(import /tweens)

(defn- update-timer-handle [handle dt]
  (let [{:time h-time
         :limit h-limit
         :count h-count} handle
        new-time (+ h-time dt)]
    (put handle :time new-time)
    (when (not (nil? (handle :during)))
      (:during handle dt))
    (when (and (>= new-time h-limit) (> h-count 0))
      (when (handle :after)
        (:after handle))
      (put handle :time (- new-time h-limit))
      (put handle :count (- h-count 1)))))

(defn- during [self delay during-fn &opt after-fn]
  "run during fn every 'delay' seconds, then optionally run after fn."
  (let [handle @{:time 0
                 :limit delay
                 :count 1
                 :during during-fn
                 :after after-fn}]
    (put-in self [:handles handle] true)
    handle))

(defn- after [self delay after-fn]
  "Schedule a fn to run after 'delay' seconds."
  (:during self delay nil after-fn))

(defn- every [self delay after &opt count]
  "Schedule a fn to run every 'delay' seconds."
  (default count math/inf)
  (let [handle @{:time 0
                 :after after
                 :limit delay
                 :count count}]
    (put-in self [:handles handle] true)
    handle))

(defn- cancel [self handle]
  "Prevent a timer from being executed in the future."
  (put-in self [:handles handle] nil))

(defn- clear [self]
  "Remove all timed and periodic functions."
  (set (self :handles) @{}))

(defn- update [self dt]
  "Update timers and execute functions if the deadline is reached."
  (eachk handle (self :handles)
         (update-timer-handle handle dt)
         (when (= (handle :count) 0)
           (:cancel self handle))))

(defn- tween-deep-delta [subject target]
  "Creates a table of the same structure of target,
   with the deltas between subject and target as the values"
  (match (type target)
    :number (- target subject)
    :tuple (map
            |(let [(i v) $]
               (tween-deep-delta (subject i) v))
            (pairs target))
    :struct (table
             ;(mapcat
               |(let [(key val) $]
                  [key (tween-deep-delta (subject key) val)])
               (pairs target)))
    _ nil))

(defn- tween-deep-update [subject delta ds]
  ""
  (match (type delta)
    :number (+ subject (* delta ds))
    :tuple (map
            |(let [(i v) $]
               (tween-deep-update (subject i) v ds))
            (pairs delta))
    :struct (table
             ;(mapcat
               |(let [(key val) $]
                  [key (tween-deep-update (subject key) val ds)])
               (pairs delta)))
    _ nil))

(defn- tween [self len subject target method after]
  "tween the subject to target with the given method over the length"
  (let [tween-fn (symbol "tweens/" method)
        deltas (tween-deep-delta subject target)
        during-fn (fn [handle dt]
                    (let [h-time (get handle :time)
                                 last-s (get handle :last-s 0)
                                 s (tween-fn (min 1 (/ h-time len)))
                                 ds (- s last-s)]
                      (put handle :last-s s)
                      (tween-deep-update subject deltas ds)))]
    (:during self len during-fn after)))

(defn init []
  "Creates a new timer instance."
  {:handles @{}
   :during during
   :after after
   :every every
   :cancel cancel
   :clear clear
   :update update
   :tween tween})
