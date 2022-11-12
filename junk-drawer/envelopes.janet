(setdyn :doc ```
Envolopes are basically multistage tweens. There are 4 possible stages to the envelopes
  - Attack is the time taken for initial run-up of level from nil to peak, beginning when the key is pressed.
  - Decay is the time taken for the subsequent run down from the attack level to the designated sustain level.
  - Sustain is the level during the main sequence of the sound's duration, until the key is released.
  - Release is the time taken for the level to decay from the sustain level to zero after the key is released

This module contains common envelopes usually used in music, however there are many other uses! For example
consider using an ADSR for a characters run speed, or an ASR for their jump arc.

All envelopes have the same api. Create them with their constructor, then use the ":begin" and ":tick" object method.

(:begin *adsr*)
(printf "next value: %q" (:tick *adsr*))
```)

(import ./fsm :as "fsm")
(import ./tweens :as "tweens")

(defn- attack-state [target duration &opt tween]
  (default tween tweens/in-linear)
  (fsm/state :attack
     :value 0
     :target target
     :elapsed 0
     :duration duration
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
     :next-value (fn decay-next-value [self]
                   (tweens/interpolate
                    (self :value)
                    (self :target)
                    (self :elapsed)
                    (self :duration)
                    tween))))

(defn- sustain-state [duration]
  (fsm/state :sustain
     :elapsed 0
     :duration duration
     :next-value (fn sustain-next-value [self] (self :value))))

(defn- release-state [duration &opt tween]
  (default tween tweens/out-linear)
  (fsm/state :release
     :target 0
     :elapsed 0
     :duration duration
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


(defn- tick [self]
  (let [current-node (:get-node self (self :current))
        new-value (:next-value self)]
    (+= (self :elapsed) 1)
    (put self :value new-value)

    (when (>= (self :elapsed) (self :duration))
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


(defn ar
  ```
  Create a new AR finite state machine. It just uses attack -> release.

       /\
      /  \
     /    \
    /      \
    A       R

  Parameters for this function are:
    - attack target, duration, and optional tween
    - decay duration, and optional tween

  (var *asr* (envelopes/asr
               :attack-target 50 :attack-duration 20 :attack-tween tweens/in-cubic
               :release-duration 15 :release-tween tweens/in-out-quad))
  ```
  [&named
   attack-target attack-duration attack-tween
   release-duration release-tween]
  (-> (table/setproto (fsm/create
                       (attack-state attack-target attack-duration attack-tween)
                       (release-state release-duration release-tween)
                       (idle-state)

                       (fsm/transition :begin :idle :attack)
                       (fsm/transition :next :attack :release)
                       (fsm/transition :next :release :idle))
                      Envelope)
      (:apply-edges-functions)
      (:apply-data-to-root)))


(defn asr
  ```
  Create a new ASR finite state machine, attack -> sustain -> release.

       /------\
      /        \
     /          \
    /            \
    A      S     R

  Parameters for this function are:
    - attack target, duration, and optional tween
    - sustain duriation
    - decay duration, and optional tween

  (var *asr* (envelopes/asr
               :attack-target 50 :attack-duration 20 :attack-tween tweens/in-cubic
               :sustain-duration 10
               :release-duration 15 :release-tween tweens/in-out-quad))
  ```
  [&named
   attack-target attack-duration attack-tween
   sustain-duration
   release-duration release-tween]
  (-> (table/setproto (fsm/create
                       (attack-state attack-target attack-duration attack-tween)
                       (sustain-state sustain-duration)
                       (release-state release-duration release-tween)
                       (idle-state)

                       (fsm/transition :begin :idle :attack)
                       (fsm/transition :next :attack :sustain)
                       (fsm/transition :next :sustain :release)
                       (fsm/transition :next :release :idle))
                      Envelope)
      (:apply-edges-functions)
      (:apply-data-to-root)))

(defn adsr
  ```
  Create a new ADSR finite state machine, attack -> decay -> sustain -> release.

       /\
      /  \
     /    ------\
    /            \
    A    D   S   R

  Parameters for this function are:
    - attack target, duration, and optional tween
    - decay target, duration, and optional tween
    - sustain duriation
    - decay duration, and optional tween

  (var *adsr* (envelopes/adsr
               :attack-target 50 :attack-duration 20 :attack-tween tweens/in-cubic
               :decay-target 25 :decay-duration 15
               :sustain-duration 10
               :release-duration 15 :release-tween tweens/in-out-quad))

  (:begin *adsr*)
  (printf "next value: %q" (:tick *adsr*))
  ```
  [&named
   attack-target attack-duration attack-tween
   decay-target decay-duration decay-tween
   sustain-duration
   release-duration release-tween]
  (-> (table/setproto (fsm/create
                       (attack-state attack-target attack-duration attack-tween)
                       (decay-state decay-target decay-duration decay-tween)
                       (sustain-state sustain-duration)
                       (release-state release-duration release-tween)
                       (idle-state)

                       (fsm/transition :begin :idle :attack)
                       (fsm/transition :next :attack :decay)
                       (fsm/transition :next :decay :sustain)
                       (fsm/transition :next :sustain :release)
                       (fsm/transition :next :release :idle))
                      Envelope)
      (:apply-edges-functions)
      (:apply-data-to-root)))
