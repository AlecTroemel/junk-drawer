(use /junk-drawer)

# Tweens (short for in-betweening) allows you to interpolate values using predefined functions,
# the applet here https://hump.readthedocs.io/en/latest/timer.html#tweening-methods
# gives a good visualization of what happens.
#
# In this example we will tween the components color using in-cubic over 10 ticks.

(def-component color
  :r :number
  :g :number
  :b :number)
(def-tag tween-it)

# Note that we dont create the entity with the tween,
# instead we add it in a seperate system. When the
# tween is completed, the "tween" component will be
# automatically removed from the entity.
(def-system add-tween
  {colors [:entity :color :tween-it]
   wld :world}
  (each [ent col twn _] colors
    (remove-component wld ent :tween-it)
    (add-component wld ent (tween col
                                  (color :r 255 :g 0 :b 128)
                                  tweens/in-cubic
                                  10))))

# Then we can update your component with the tweens
# "current" field.
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
            (color :r 0 :g 0 :b 0)
            (tween-it))

(for i 0 20
  (print "tick: " i)
  (:update world 1))
