(use ./../src/junk-drawer)

# Timers are just entities, with a system registered in the world
# callbacks for timers get both the world and dt args
(def world (create-world))
(register-system world timers/update-sys)

# There are some helper macros in creating timers
(timers/after world 10
              (fn [wld dt] (print "after: 10 ticks have passed")))

(timers/during world 5
               (fn [wld dt] (print "during"))
               (fn [wld dt] (print "during is complete")))

(timers/every world 2
              (fn [wld dt] (print "every 2, but only 3 times"))
              3) # default is loop for infinity

(for i 0 11
  (print "i: " i)
  (:update world 1)
  (print ""))
