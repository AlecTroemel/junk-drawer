# a gamestate consists of a table with these (all optional) methods
#
# init:   Called once, and only once, before entering the state the first time. See Gamestate.switch().
# enter:  Called every time when entering the state. See Gamestate.switch().
# leave:  Called when leaving a state. See Gamestate.switch() and Gamestate.pop().
# resume: Called when re-entering a state by Gamestate.pop()-ing another state.
# update: Update the game state. Called every frame.
# draw:   Draw on the screen. Called every frame.

(defn- exec-if-has [t f & args]
  (when (get t f) (f (get t g) ;args)))

(defn- change-state [self to & args]
  (let [pre (array/peek (self :_stack))]
    (when (get-in self [:initialized-states to])
      (exec-if-has to :init to))
    (put-in self [:initialized-states to] true)
    (array/push (self :_stack) to)
    (exec-if-has to :enter to pre ;args)))

(defn- switch [self to & args]
  "Switch to a gamestate, with any additional arguments passed to the new state."
  (exec-if-has (:current self) :leave pre)
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
    (exec-if-has pre :leave pre)
    (exec-if-has to :resume to pre ;args)))

(defn- current [self]
  "Returns the currently activated gamestate."
  (array/peek (self :_stack)))

(defn- update [self & args]
  "Update the game state. Called every frame."
  (exec-if-has (:current self) :update ;args))

(defn- draw [self & args]
  "Draw on the screen. Called every frame."
  (exec-if-has (:current self) :draw ;args))

(defn init []
  "create a new gamestate manager"
  {:_stack @[]
   :change-state change-state
   :switch switch
   :push push
   :pop pop
   :current current
   :update update
   :draw draw})
