(use /junk-drawer)

# Tweens (short for in-betweening) allows you to interpolate values using predefined functions,
# the applet here https://hump.readthedocs.io/en/latest/timer.html#tweening-methods
# gives a good visualization of what happens.
#
# To tween components on an entity, add a tween component to it. Then in a system
# update your component with the tweens "current" field. When the tween is completed,
# the interpolate component will be removed from the entity.
#
# In this example we will tween the components color using in-cubic over 10 ticks. Note
# that we dont create the entity with the tween, instead we add it in a seperate system.

(def-component color [r g b])
(def-tag tween-it)

(def-system add-tween
  {colors [:entity :color :tween-it]
   wld :world}
  (each [ent col twn _] colors
    (remove-component wld ent :tween-it)
    (add-component wld ent (tween col (color 255 0 128) tweens/in-cubic 10))))

(def-system tween-colors
  {tweening-colors [:color :tween]}
  (each [col twn] tweening-colors
    (merge-into col (twn :current))))

(def-system print-colors
  {colors [:color]}
  (map pp (flatten colors)))

(def world (create-world))

(register-system world tweens/update-sys)
(register-system world add-tween)
(register-system world tween-colors)
(register-system world print-colors)

(add-entity world
            (color 0 0 0)
            (tween-it))

(for i 0 20
  (:update world 1))
