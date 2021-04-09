(use /junk-drawer)

(def-component height [h])

# First lets just tween a single number
# the most important part is calling the "tweens/interpolate" method
# on the tween with the value you wish to tween.
(print "Example 1")

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
            (tween 0 10 tweens/in-linear 10 0 false))

(for i 0 20
  (:update world 1))

# you can also Tween a table or Array!
(print "Example 2")

(def-component color [r g b])

(def-system color-shifter
  (colors [:color :tween])
  (each [c twn] colors
    # cant set c directly, have to update each value individually
    (each [k v] (pairs (tweens/interpolate c twn))
      (put c k v))
    (pp c)))

(def world (create-world))
(register-system world tweens/update-sys)
(register-system world color-shifter)
(add-entity world
            (color 0 0 0)
            (tween (color 255 255 255) 20 tweens/in-cubic 10 0 false))

(for i 0 20
  (:update world 1))

# in practice, you usually wont create the entity with the tween component.
# Intead you'll want to dynamicaaly add a component to an existing entity
