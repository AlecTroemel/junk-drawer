(import ./../src/ecs :prefix "")

# Register (global) components, these are shared across worlds.
(def-component position [x y])
(def-component velocity [x y])

# create a world to hold your entities + systems
(def world (create-world))

# Add entities to a world
(add-entity world (position 44 33) (velocity 8 9))
(add-entity world (position 100 24))

# Systems are functions that work on an entity queryset ...
(defn sys-move [queryset dt]
  (each [pos vel] queryset
    (put pos :x (+ (pos :x) (* dt (vel :x))))
    (put pos :y (+ (pos :y) (* dt (vel :y))))))

# ... That you register on a world with a query
(register-system world [:position :velocity] sys-move)

# you can inline the function if you want
(register-system world [:position]
 (fn sys-print-pos [q dt]
   (print "dt " dt)
   (each (pos) q (printf "pos %q" pos))))

# then just call update every frame :)
(def mock-dt 1)
(:update world mock-dt)
