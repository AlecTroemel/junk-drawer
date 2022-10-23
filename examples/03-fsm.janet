(use /junk-drawer)

# Finite state machines build on the directed graph by adding a "current" field
# and functions in nodes that will be called when current changes.
#
# the main way to interact with this module is to define the state "factory".
# transitions define functions that will be avaible on the root FSM when in that state.
# the Enter, Leave, and Init methods are optional fn in the state and are called when
# the FSM moves between states.
#
# any additional arguments passed into the transition function will be passed in
# to the Enter method.
(fsm/define
 colored-warnings
 (fsm/state :green
    :enter (fn green-enter [self from] (print "entering green"))
    :leave (fn green-leave [self to] (print "leaving green")))
 (fsm/transition :warn :green :yellow)

 (fsm/state :yellow
    :enter (fn yellow-enter [self from name]
             (printf "entering yellow, %s be careful!" name)))
 (fsm/transition :panic :yellow :red)
 (fsm/transition :clear :yellow :green)

 (fsm/state :red
    :leave (fn red-leave [self to] (print "leaving red")))
 (fsm/transition :calm :red :yellow))


# Create the actual fsm object with the initial state
(print "Example 1 output:")
(def *state* (colored-warnings :green))
(print "start: " (*state* :current))
(:warn *state* "Alec")
(:panic *state*)
(:calm *state* "Alec")
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
 (fsm/state :standing
    :boredom 0
    :update (fn standing-update [self dt]
              (printf "boredom %q" (self :boredom))
              (if (= 4 (self :boredom))
                (:jump self)
                (put self :boredom (inc (self :boredom))))))
 (fsm/transition :jump :standing :jumping)

 (fsm/state :jumping
    :airtime 2
    :update (fn jumping-update [self dt]
              (printf "airtime %q" (self :airtime))
              (if (= 0 (self :airtime))
                (:land self)
                (put self :airtime (dec (self :airtime))))))
 (fsm/transition :land :jumping :standing))

(def *froggy* (jumping-frog :standing))

(print "\nExample 2 output:")
(for i 0 10
  (printf "froggy is currenty %q" (*froggy* :current))
  (:update *froggy* 1))
