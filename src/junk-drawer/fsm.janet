(defn- goto [self to]
  (assert (self to) (string/format "%q is not a valid state" to))

  # Call leave method on old state
  (when (self :leave)
    (:leave self))

  # clear out old state methods from top of the table
  (each state-d (get self :state-data [])
    (put self state-d nil))

  # set current to new state
  (put self :current to)

  # put new states state-data on top of table
  (put self :state-data (keys (self (self :current))))
  (each state-d (self :state-data)
    (put self
         state-d
         (get-in self [(self :current) state-d])))

  # call enter on new state
  (when (self :enter)
    (:enter self)))


(defmacro define [name & states]
  "define a FSM creating function with the given states."
  (with-syms [$state-names]
    ~(defn ,name [initial-state]
       ,(let [$state-names (map |(keyword (first $)) states)]
         ~(assert (any? (map |(= $ initial-state) ,$state-names))
                  (string/format "initial state must be in %q" ,$state-names)))
       (let [machine (table
                      :current initial-state
                      :goto ,goto
                      ,;(mapcat
                         |(tuple (keyword (first $)) (struct ;(slice $ 1)))
                         states))]
         (:goto machine initial-state)
         machine))))
