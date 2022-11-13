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
     :elapsed 0
     :complete? (fn idle-complete? [self] false)
     :next-value (fn idle-next-value [self] 0)))

(defn- tick [self]
  (let [current-node (:get-node self (self :current))
        new-value (:next-value self)]
    (+= (self :elapsed) 1)
    (put self :value new-value)

    (when-let [state-complete? (:complete? self)
               auto-fn (get self :auto false)
               target (get self :target new-value)]
      (:auto self)
      (put self :value target))

    (self :value)))

(def Envelope
  (merge
   fsm/FSM
   @{:tick tick
     :current :idle
       :__id__ :envelope
       :__validate__ (fn [& args] true)}))

(defmacro- defn-envelope [name docs args & body]
  ~(defn ,name
     ,docs
     [&named ,;args]
     (-> (table/setproto
          (,fsm/create ,;body)
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
  [attack-target attack-duration attack-tween
   release-duration release-tween]

  (idle-state)
  (fsm/transition :trigger :idle :attack)

  (attack-state attack-target attack-duration attack-tween)
  (fsm/transition :auto :attack :release)
  (fsm/transition :trigger :attack :attack)
  (fsm/transition :release :attack :release)

  (release-state release-duration release-tween)
  (fsm/transition :trigger :release :attack)
  (fsm/transition :auto :release :idle))

(defn-envelope asr
  ```
  Create a new ASR finite state machine, attack -> sustain -> release.

       /------\
      /        \
     /          \
    /            \
    A      S     R
  ```
  [attack-target attack-duration attack-tween
   release-duration release-tween]

  (idle-state)
  (fsm/transition :trigger :idle :attack)

  (attack-state attack-target attack-duration attack-tween)
  (fsm/transition :auto :attack :sustain)
  (fsm/transition :trigger :attack :attack)
  (fsm/transition :release :attack :release)

  (sustain-state)
  (fsm/transition :trigger :sustain :attack)
  (fsm/transition :release :sustain :release)

  (release-state release-duration release-tween)
  (fsm/transition :trigger :release :attack)
  (fsm/transition :auto :release :idle))


(defn-envelope adsr
  ```
  Create a new ADSR finite state machine, attack -> decay -> sustain -> release.

       /\
      /  \
     /    ------\
    /            \
    A    D   S   R
  ```
  [attack-target attack-duration attack-tween
   decay-target decay-duration decay-tween
   release-duration release-tween]
  (idle-state)
  (fsm/transition :trigger :idle :attack)

  (attack-state attack-target attack-duration attack-tween)
  (fsm/transition :auto :attack :decay)
  (fsm/transition :trigger :attack :attack)
  (fsm/transition :release :attack :release)

  (decay-state decay-target decay-duration decay-tween)
  (fsm/transition :auto :decay :sustain)
  (fsm/transition :trigger :decay :attack)
  (fsm/transition :release :decay :release)

  (sustain-state)
  (fsm/transition :trigger :sustain :attack)
  (fsm/transition :release :sustain :release)

  (release-state release-duration release-tween)
  (fsm/transition :trigger :release :attack)
  (fsm/transition :auto :release :idle))
