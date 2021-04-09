(use /junk-drawer)

(def-component height [h])

# First lets just tween a single number
(def-system simple-tween
  (heights [:height :tween])
  (each [ht twn] heights
    (put ht :h (tweens/interpolate (ht :h) twn))
    (pp ht)))

(def world (create-world))
(register-system world tweens/update-sys)
(register-system world simple-tween)
(add-entity world
            (height 0)
            (tween 0 10 tweens/in-cubic 10 0 false))

(for i 0 20
  (:update world 1))

# TODO: Tween a whole component!
