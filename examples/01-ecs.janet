(use ./../src/junk-drawer)

# Register (global) components, these are shared across worlds.
(def-component position [x y])
(def-component velocity [x y])

# create a world to hold your entities + systems
(def world (create-world))

# Add entities to a world
(add-entity world (position 10 10) (velocity (- 1) (- 1)))
(add-entity world (position 3 5))

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
  (each [vel] vels (pp vel)))

(register-system world print-position)

# there are a couple special queries
# the most commen one is to get the parent world of the system
# you can use this to delete entities.
#
# In this example the entity will be destroyed if its x,y coords both become 0.
# Given the entities defined above this should take 10 iterations
(def-system remove-dead
  (entities [:entity :position] wld :world)
  (each [ent pos] entities
    (when (deep= pos @{:x 0 :y 0})
      (print "time to die entity id " ent)
      (remove-entity wld ent))))

(register-system world remove-dead)

# then just call update every frame :)
# We assume dt is just 1 here
(for i 0 15
  (print "i: " i)
  (:update world 1)
  (print ""))
