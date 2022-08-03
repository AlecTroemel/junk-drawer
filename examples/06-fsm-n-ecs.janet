(use ./../junk-drawer)

# Since FSM's are just functions that return tables,
# they can be added as components to entities!
# here's a (contrived & useless) example

(fsm/define
  colored-warnings
  {:green
   {:warn |(:goto $ :yellow)}
   :yellow
   {:panic |(:goto $ :red)
    :clear |(:goto $ :green)}
   :red
   {:calm |(:goto $ :yellow)}})

(def-component position :x :number :y :number)

(def world (create-world))

(register-system world timers/update-sys)

(add-entity world
            (position :x 5 :y 5)
            (colored-warnings :green))
(add-entity world
            (position :x 3 :y 3)
            (colored-warnings :yellow))

(timers/every world 2
              (fn [world _]
                (each [e c] (:view world [:entity :colored-warnings])
                  (when (= (c :current) :yellow)
                    (print "Clearing " e " from timer")
                    (:clear c))))
              2)

(def-system x-val-warning
  {entities [:position :colored-warnings]}
  (each [e machine] entities
    (def re (> (math/random) 0.5))
    (def mc (machine :current))
    (printf "%q %q" e mc)
    (when re
      (print "Random event!")
      (case mc
        :green (:warn machine)
        :yellow (:panic machine)
        :red (:calm machine))
      (print "Moved to " (machine :current)))))

(register-system world x-val-warning)

(for _ 0 10
  (:update world 1)
  (print))
