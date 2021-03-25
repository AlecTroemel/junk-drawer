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
    (put-in self [:_functions handle] true)
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
    (put-in self [:_functions handle] true)
    handle))

(defn- cancel [self handle]
  "Prevent a timer from being executed in the future."
  (put-in self [:_functions handle] nil))

(defn- clear [self]
  "Remove all timed and periodic functions."
  (set (self :_functions) @{}))

(defn- update [self dt]
  "Update timers and execute functions if the deadline is reached."
  (eachk handle (self :_functions)
         (update-timer-handle handle dt)
         (when (= (handle :count) 0)
           (:cancel self handle))))

(defn init []
  "Creates a new timer instance."
  {:_functions @{}
   :during during
   :after after
   :every every
   :cancel cancel
   :clear clear
   :update update})
