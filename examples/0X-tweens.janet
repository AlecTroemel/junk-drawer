(use ./../src/junk-drawer)

(def world (create-world))

# TODO: tween a number
# TODO: tween a whole component!

(for i 0 15
  (print "i: " i)
  (:update world 1)
  (print ""))
