(use ./../src/junk-drawer)

# Register (global) components, these are shared across worlds.
(def-component position [x y])
(def-component velocity [x y])

# create a world to hold your entities + systems
(def world (create-world))

# Add entities to a world
(add-entity world (position 44 33) (velocity 8 9))
(add-entity world (position 100 24))

# Systems are a list of queries and a body that does work on them.
# "dt" (which is passed into a worlds update method) is implicitly available to all systems
(def-system move
  (moveables [:position :velocity])
  (each [pos vel] moveables
    (put pos :x (+ (pos :x) (* dt (vel :x))))
    (put pos :y (+ (pos :y) (* dt (vel :y))))))

# you'll need to register a system on a world
(register-system world move)

# Here's a system that has multiple queries
(def-system print-position
  (poss [:position] vels [:velocity])
  (print "positions:")
  (each [pos] poss (pp pos))
  (print "velocities:")
  (each [vel] vels (pp vel))
  (print "\n"))

(register-system world print-position)

# then just call update every frame :)
(def mock-dt 1)
(:update world mock-dt)
