(import ./../src/ecs :prefix "")

# Register (global) components, these are shared across worlds
(def-component position [x y])
(def-component velocity [x y])


# create a world to hold your entities + systems
(def world (create-world))

# Add entities to a world
(add-entity world (position 44 33) (velocity 8 9))
(add-entity world (position 100 24))

# Register systems to a world

# you can pass in an existing function
(def move (fn move [pos vel dt]
            (put pos :x (+ (pos :x) (* dt (vel :x))))
            (put pos :y (+ (pos :y) (* dt (vel :y))))))

(register-system world [:position :velocity] move)

# or create one right in the definition
(register-system world [:position]
                 (fn position-printer [pos dt]
                   (printf "POSITION: %q" pos)))

# then just call this every frame :)
(def mock-dt 1)
(:update world mock-dt)
