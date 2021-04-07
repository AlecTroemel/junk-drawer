(use ./../src/junk-drawer)

# Since FSM's are just functions that return tables,
# they can be added as components to entities!
# here's a (contrived & useless) example

(fsm/define
 colored-warnings
 (green
  :warn |(:goto $ :yellow))
 (yellow
  :panic |(:goto $ :red)
  :clear |(:goto $ :green))
 (red
  :calm |(:goto $ :yellow)))

(def-component position [x y])

(def world (create-world))

(add-entity world
            (position 5 5)
            (colored-warnings :green))

(def-system x-val-warning
  (entities [:position :colored-warnings])
  (each [e machine] entities
    (printf "%q %q" e (machine :current))))

(register-system world x-val-warning)

(:update world 1)
