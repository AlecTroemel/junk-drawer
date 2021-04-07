(use ./../junk-drawer)

# Register (global) components, these are shared across worlds.
(def-component position [x y])
(def-component velocity [x y])
(def-component lives [cnt])

# create a world to hold your entities + systems
(def world (create-world))

# Add entities to a world
(add-entity world (position 10 10) (velocity -1 -1) (lives 2))
(add-entity world (position 8 8) (velocity -2 -2) (lives 1))
(add-entity world (position 3 5) (lives 1))

# Systems are a list of queries and a body that does work on them.
# "dt" (which is passed into a worlds update method) is implicitly available to all systems
(def-system move
  {moveables [:position :velocity]}
  (each [pos vel] moveables
    (put pos :x (+ (pos :x) (* dt (vel :x))))
    (put pos :y (+ (pos :y) (* dt (vel :y))))))

# you'll need to register a system on a world
(register-system world move)

# Here's a system that has multiple queries
(def-system print-position
  {poss [:position] vels [:velocity] livs [:lives]}
  (print "positions:")
  (each [pos] poss (pp pos))
  (print "velocities:")
  (each [vel] vels (pp vel))
  (print "lives:")
  (each [liv] livs (pp liv)))

(register-system world print-position)

# you can also get the parent world of the system with a special query
# you can use this to delete/create entities within a system!
#
# In this example the entity will be destroyed if its x,y coords both become 0.
# Given the entities defined above this should take 10 iterations
(def-system remove-dead
  {entities [:entity :position] wld :world}
  (each [ent pos] entities
    (when (deep= pos @{:x 0 :y 0})
      (print "time to die entity id " ent)
      (remove-entity wld ent))))

(register-system world remove-dead)

# There is a special type of component called a tag, which just has no data
# you can use this to further seperate entities out

(def-tag monster)

(add-entity world
            (position 0 0)
            (velocity 1 1)
            (monster))

(add-entity world
            (position 0 5)
            (velocity 1 0)
            (monster))

(def-system print-monsters
  {monsters [:entity :position :monster]
   entities [:entity :position :lives]
   wld :world}
  (each [ent pos] monsters
    (prin "Monster ")
    (pp pos)
    (if-let [[e]
             (filter (fn [[e p l]]
                       (and (not= ent e) (deep= p pos))) entities)]
      (when-let [[i _ l] e]
        (printf "monster got %j" e)
        (remove-entity wld ent)
        (if (one? (l :cnt))
          (remove-entity wld e)
          (update l :cnt dec))))))

(register-system world print-monsters)


# then just call update every frame :)
# We assume dt is just 1 here
(for i 0 6
  (print "i: " i)
  (:update world 1)
  (print))
