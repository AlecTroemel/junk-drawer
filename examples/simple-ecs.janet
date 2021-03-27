(import ./../src/ecs :prefix "")

# Register (global) components, these are shared across worlds.
(def-component position [x y])
(def-component velocity [x y])

# create a world to hold your entities + systems
(def world (create-world))

# Add entities to a world
(add-entity world (position 44 33) (velocity 8 9))
(add-entity world (position 100 24))

# Systems have queryset and dt args ...
(def-system move [:position :velocity]
  (each [pos vel] queryset
    (put pos :x (+ (pos :x) (* dt (vel :x))))
    (put pos :y (+ (pos :y) (* dt (vel :y))))))

# ... That you register on a world with a query
(register-system world move)


# Here's another system
(def-system print-position [:position]
  (each [pos] queryset (pp pos)))

(register-system world print-position)


# then just call update every frame :)
(def mock-dt 1)
(:update world mock-dt)
