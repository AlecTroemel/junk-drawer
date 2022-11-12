(setdyn :doc ```
Envolopes are basically multistage tweens. There are 5 possible stages to the envelopes
  - Idle: envelope is not running
  - Attack: time taken for initial run-up of level from nil to peak, beginning when the envelope is begun.
  - Decay: time taken for the subsequent run down from the attack level to the designated sustain level.
  - Sustain: level during the main sequence of the sound's duration, until the envelope is released.
  - Release: time taken for the level to decay from the sustain level to zero after the envelope is released

This module contains common envelopes usually used in music, however there are many other uses! For example
consider using an ADSR for a characters run speed, or an ASR for their jump arc.

All envelopes have the same api. Create them with their constructor, then use the ":begin" and ":tick" object method.

(:begin *adsr*)
(printf "next value: %q" (:tick *adsr*))
```)

(import ./fsm :as "fsm")
(import ./tweens :as "tweens")

# Different possible states for envelopes
(defn- attack-state [target duration &opt tween]
  (default tween tweens/in-linear)
  (fsm/state :attack
     :value 0
     :target target
     :elapsed 0
     :duration duration
     :complete? (fn attack-complete [self]
                  (>= (self :elapsed)
                      (self :duration)))
     :next-value (fn attack-next-value [self]
                   (tweens/interpolate
                    (self :value)
                    (self :target)
                    (self :elapsed)
                    (self :duration)
                    tween))))

(defn- decay-state [target duration &opt tween]
  (default tween tweens/out-linear)
  (fsm/state :decay
     :target target
     :elapsed 0
     :duration duration
     :complete? (fn decay-complete [self]
                  (>= (self :elapsed)
                      (self :duration)))
     :next-value (fn decay-next-value [self]
                   (tweens/interpolate
                    (self :value)
                    (self :target)
                    (self :elapsed)
                    (self :duration)
                    tween))))

(defn- sustain-state []
  (fsm/state :sustain
     :elapsed 0
     :complete? (fn sustain-complete? [self] false)
     :next-value (fn sustain-next-value [self] (self :value))))

(defn- release-state [duration &opt tween]
  (default tween tweens/out-linear)
  (fsm/state :release
     :target 0
     :elapsed 0
     :duration duration
     :complete? (fn release-complete [self]
                  (>= (self :elapsed)
                      (self :duration)))
     :next-value (fn release-next-value [self]
                   (tweens/interpolate
                    (self :value)
                    (self :target)
                    (self :elapsed)
                    (self :duration)
                    tween))))

(defn- idle-state []
  (fsm/state :idle
     :value 0
     :next-value (fn idle-next-value [self] 0)))

# Envelope "Class" functions and definition
(defn- tick [self]
  (let [current-node (:get-node self (self :current))
        new-value (:next-value self)]
    (+= (self :elapsed) 1)
    (put self :value new-value)

    (when (:complete? self)
      (let [target (self :target)]
        (:next self)
        (when (not (nil? target))
          (put self :value target))))

    (self :value)))

(def Envelope
  (merge
   fsm/FSM
   @{:tick tick
     :current :idle
     :__id__ :envelope
     :__validate__ (fn [& args] true)}))

# Macro to create envelopes
(defn- state-fn [name]
  (match name
    :attack attack-state
    :decay decay-state
    :sustain sustain-state
    :release release-state))

(defn- state-args [name]
  (match name
    :attack ~(attack-target attack-duration attack-tween)
    :decay ~(decay-target decay-duration decay-tween)
    :sustain []
    :release ~(release-duration release-tween)))

(defn- inter-state-transitions [a b]
  (match [a b]
    [:sustain b] [~fsm/transition :release :sustain b]
    [~fsm/transition :next a b]))

(defmacro- defn-envelope [name docs & states]
  ~(defn ,name
     ,docs
     [&named ,;(mapcat state-args states)]
     (-> (table/setproto
          (,fsm/create
            # States
            (idle-state)
            ,;(map |[(state-fn $) ;(state-args $)] states)

            # "inter-state" transitions
            (fsm/transition :begin :idle ,(first states))
            ,;(seq [i :range [0 (- (length states) 1)]
                    :let [a (states i)
                          b (states (+ i 1))]]
                   (inter-state-transitions a b))
            (fsm/transition :next ,(last states) :idle)

            # "reset" transitions
            ,;(map |[fsm/transition :reset $ :idle] states))
          ,Envelope)
         (:apply-edges-functions)
         (:apply-data-to-root))))

(defn-envelope ar
  ```
  Create a new AR finite state machine. It just uses attack -> release.

       /\
      /  \
     /    \
    /      \
   A        R
  ```
  :attack :release)

(defn-envelope asr
  ```
  Create a new ASR finite state machine, attack -> sustain -> release.

       /------\
      /        \
     /          \
    /            \
    A      S     R
  ```
  :attack :sustain :release)

(defn-envelope adsr
  ```
  Create a new ADSR finite state machine, attack -> decay -> sustain -> release.

       /\
      /  \
     /    ------\
    /            \
    A    D   S   R
  ```
  :attack :decay :sustain :release)
