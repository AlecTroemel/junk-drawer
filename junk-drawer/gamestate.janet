(setdyn :doc ```
Gamestates encapsulates specific states... of your game! A typical game could
consist of a menu-state, a level-state and a game-over-state. There is a single
gamestate manager which you initiate with (def *GS* (gamestates/init)), the switch
(or push) between states.

A gamestate here is just table with these (all optional) methods:
    - (init self): Called once, and only once, before entering the state the first time. See Gamestate.switch().
    - (enter self prev & args): Called every time when entering the state. See Gamestate.switch().
    - (leave self): Called when leaving a state. See Gamestate.switch() and Gamestate.pop().
    - (resume self prev & args): Called when re-entering a state by Gamestate.pop()-ing another state.
    - (update self & args): Update the game state. Called every frame.
    - (draw self & args): Draw on the screen. Called every frame.
```)

(defn- exec-if-has [t f & args]
  (default args [])
  (when (get t f) (f t ;args)))

(defn- change-state [self to & args]
  (let [pre (array/peek (self :_stack))]
    (when (nil? (get-in self [:initialized-states to]))
      (exec-if-has to :init))
    (put-in self [:initialized-states to] true)
    (array/push (self :_stack) to)
    (exec-if-has to :enter to pre ;args)))

(defn- switch [self to & args]
  "Switch to a gamestate, with any additional arguments passed to the new state."
  (exec-if-has (:current self) :leave to)
  (array/pop (self :_stack))
  (:change-state self to ;args))

(defn- push [self to & args]
  "Pushes the to on top of the state stack, i.e. makes it the active state. Semantics are the same as switch, except that the leave callback is not called on the previously active state."
  (:change-state self to args))

(defn- pop [self & args]
  "Calls 'leave' on the current state and then removes it from the stack, making the state below the current state and calls 'resume' on the activated state. Does not call 'enter' on the activated state."
  (assert (> (length (self :_stack)) 1) "No more states to pop!")
  (let [pre (array/pop (self :_stack))
        to (array/peek (self :_stack))]
    (exec-if-has self pre :leave pre)
    (exec-if-has self to :resume to pre ;args)))

(defn- current [self]
  "Returns the currently activated gamestate."
  (array/peek (self :_stack)))

(defn- update [self & args]
  "Update the game state. Called every frame."
  (exec-if-has (:current self) :update ;args))

(defn- draw [self & args]
  "Draw on the screen. Called every frame."
  (exec-if-has (:current self) :draw ;args))

(defn init
  ```
  Create a new gamestate manager. Gamestates are switched to using the "switch" method. Gamestates can
  also be pushed and poped like a stack on the the manager.

  (def *GS* (gamestate/init))
  (:switch *GS* menu)
  (:push *GS* settings)
  (:pop *GS*)

  (def menu
    {:init (fn [self] (print "menu init"))
     :enter (fn [self prev & args] (printf "menu enter %q" args))
     :update (fn [self dt] (print "menu game state dt: " dt))})

  (:update *GS* dt)
  (:draw *GS*)
  ```
  []

  {:_stack @[]
   :initialized-states @{}
   :change-state change-state
   :switch switch
   :push push
   :pop pop
   :current current
   :update update
   :draw draw})
