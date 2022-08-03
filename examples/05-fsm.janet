(use /junk-drawer)

# Example 1
#
# this macro is used to define the state "factory"
# The goto method is used to transition between states.
# the Enter and Leave methods are optional, and are called during the
# GOTO method.
#
# any additional arguments passed into the goto method will be passed in
# to the Enter method.
(fsm/define
  colored-warnings
  {:green
   {:enter (fn [self] (print "entering green"))
    :leave (fn [self] (print "leaving green"))
    :warn (fn [self name]
            (print "before warn")
            (:goto self :yellow name)
            (print "after warn") :)}
   :yellow
   {:enter (fn [self name] (printf "entering yellow, %s be careful!" name))
    :panic |(:goto $ :red)
    :clear |(:goto $ :green)}
   :red
   {:leave (fn [self] (print "leaving red"))
    :calm |(:goto $ :yellow "from calm")}})


# Create the actual fsm object with the initial state
(print "Example 1 output:")
(def *state* (colored-warnings :green))
(print "start: " (*state* :current))
(:warn *state* "Alec")
(:panic *state*)
(:calm *state*)
(:clear *state*)
(print "final: " (*state* :current))

# Example 2
#
# This is a very "informal" State machine.
# you can put any arbitrary data/method in a state,
# and it will be available on the root machine when in that state.
#
# Just remember that any data will be removed when you leave the state!
(fsm/define
  jumping-frog
  {:standing
   {:boredom 0
    :update (fn [self dt]
              (printf "boredom %q" (self :boredom))
              (if (= 4 (self :boredom))
                (:jump self)
                (put self :boredom (inc (self :boredom)))))
    :jump |(:goto $ :jumping)}
   :jumping
   {:airtime 2
    :update (fn [self dt]
              (printf "airtime %q" (self :airtime))
              (if (= 0 (self :airtime))
                (:land self)
                (put self :airtime (dec (self :airtime)))))
    :land |(:goto $ :standing)}})

(def *froggy* (jumping-frog :standing))

(print "\nExample 2 output:")
(for i 0 10
  (printf "froggy is currenty %q" (*froggy* :current))
  (:update *froggy* 1))
