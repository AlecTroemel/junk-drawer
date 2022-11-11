```
ADSR is the most common kind of envelope generator. It has four stages: attack, decay, sustain, and release (ADSR).
  - Attack is the time taken for initial run-up of level from nil to peak, beginning when the key is pressed.
  - Decay is the time taken for the subsequent run down from the attack level to the designated sustain level.
  - Sustain is the level during the main sequence of the sound's duration, until the key is released.
  - Release is the time taken for the level to decay from the sustain level to zero after the key is released

   /\
  /  \
 /    ------\
/            \
A   D    S   R

Although the most common use case for this is music, it has many other uses! For example you could use an ADSR for a characters run speed, or jump height.

```
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
    (when (>= (self :elapsed) (self :duration))
      (:next self))
    (put self :value new-value)
    new-value))

(def ADSR
  (merge
   fsm/FSM
   @{:tick tick
     :current :idle
     :__id__ :adsr
     :__validate__ (fn [& args] true)}))

(defn create [&named
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
                      ADSR)
      (:apply-edges-functions)
      (:apply-data-to-root)))
