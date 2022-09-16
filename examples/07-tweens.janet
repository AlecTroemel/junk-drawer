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

# Tweens are full fledged entities in the world that will query for then update
# component values. You can have any number of tween entities operating on an entity.
# However, be carefull about tweening the same component in multiple different ways at
# the same time as that could create infinite loops!
(def-system add-tween
  {colors [:entity :color :tween-it]
   wld :world}
  (each [ent col twn _] colors
    (remove-component wld ent :tween-it)
    (tweens/create wld ent :component :color
       :to (color :r 255 :g 0 :b 128)
       :with tweens/in-cubic
       :duration 10)))

(def-system print-colors
  {colors [:color]}
  (map pp (flatten colors)))

(def world (create-world))

(register-system world tweens/update-sys)
(register-system world add-tween)
(register-system world print-colors)

(add-entity world
            (color :r 0 :g 0 :b 0)
            (tween-it))

(for i 0 20
  (print "tick: " i)
  (:update world 1))
