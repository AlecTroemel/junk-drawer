(use ./../src/junk-drawer)

(def-component position [x y])
(def-component desired-position [x y])

# First lets just tween a single number
(def-system simple-tween
  (positions [:position])
  (each [pos] positions

    ))

(def world (create-world))

(register-system world simple-tween)

(add-entity world
            (position 10 10)
            (desired-position 20 20))

(for i 0 20
  (:update world 1))

# TODO: tween a whole component!
