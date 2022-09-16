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

(def-component map-location
  :gps (props :latitude :number :longitude :number)
  :timezone :string)

(def-system print-colors
  {colors [:color]}
  (map pp (flatten colors)))

(def-system print-map-locations
  {map-locations [:map-location]}
  (map pp (flatten map-locations)))

(def world (create-world))

(register-system world tweens/update-sys)
(register-system world print-colors)
(register-system world print-map-locations)

# Tweens are full fledged entities in the world that will query for then update
# component values. You can have any number of tween entities operating on an entity.
# However, be carefull about tweening the same component in multiple different ways at
# the same time as that could create infinite loops, or tons of tween entities doing
# the same thing!
(var ent1 (add-entity world (color :r 0 :g 0 :b 0)))
(tweens/create world ent1 :color
   :to (color :r 255 :g 0 :b 128)
   :with tweens/in-cubic
   :duration 10)


# Tweens work recursively on nested objects, any other type then a number will be
# ignored.
(var ent2 (add-entity world (map-location :gps @{:latitude 100.0
                                                 :longitude 34.1}
                                          :timezone "utc")))
(tweens/create world ent2 :map-location
   :to {:gps {:latitude 87.4}}
   :with tweens/in-linear
   :duration 14)

(for i 0 20
  (print "\ntick: " i)
  (:update world 1))
