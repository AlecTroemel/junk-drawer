(use /junk-drawer)

# Register (global) components, these are shared across worlds.
# the types given can by any of the ones listed here https://janet-lang.org/api/index.html#type
# or ":any", for any type!
# components use a table like syntax
(def-component position :x :number :y :number)
(def-component velocity :x :number :y :number)
(def-component lives :count :number)

# create a world to hold your entities + systems
(def world (create-world))

# Add entities to a world
(add-entity world
            (position :x 10 :y 10)
            (velocity :x -1 :y -1)
            (lives :count 2))
(add-entity world
            (position :x 8 :y 8)
            (velocity :x -2 :y -2)
            (lives :count 1))
(add-entity world
            (position :x 3 :y 5)
            (lives :count 1))

# Systems are a list of queries and a body that does work on them.
# "dt" (which is passed into a worlds update method) is implicitly available to
# all systems
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
            (position :x 0 :y 0)
            (velocity :x 1 :y 1)
            (monster))

(add-entity world
            (position :x 0 :y 5)
            (velocity :x 1 :y 0)
            (monster))

(def-system print-monsters
  {monsters [:entity :position :monster]
   entities [:entity :position :lives]
   wld :world}
  (each [ent pos] monsters
    (prin "Monster ")
    (pp pos)
    (when-let [[e] (filter (fn [[e p l]]
                             (and (not= ent e)
                                  (deep= p pos)))
                           entities)
               [i p life] e]

      (printf "monster got %j" e)
      (remove-entity wld ent)

      (if (one? (life :count))
        (do (remove-entity wld e)
            (printf "good bye %i" (e 0)))
        (update life :count dec)))))

(register-system world print-monsters)


# Components can even be added or removed from existing entities.
# Note that the example below would probably be better implimented
# using a FSM.
(def-tag confused)
(def-tag enlightened)

(add-entity world
            (confused))

(def-system remove-n-add
  {entities [:entity :confused]
   wld :world}

  (each [ent cnf] entities
    (printf "%q is confused" ent)
    (printf "%q is being switched from confused to enlightened" ent)
    (remove-component world ent :confused)
    (add-component world ent (enlightened))))

(register-system world remove-n-add)

(def-system print-enlightened
  {the-enlightened [:entity :enlightened]}
  (each [ent enl] the-enlightened
    (printf "%q is enlightened" ent)))

(register-system world print-enlightened)


# then just call update every frame :)
# We assume dt is just 1 here
(for i 0 6
  (print "i: " i)
  (:update world 1)
  (print))
