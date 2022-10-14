(import ./directed-graph)

(setdyn :doc ```
FSM (short for Finite State Machine) is a model where you define states (or nodes)
and transitions between those states, with a machine only "at" a single state at a time.

The bulk of this module consists of the (fsm/define) function, which is used to create
a state machine "blueprint" function. Check out the docs of that fn for more!
```)

(defn- apply-edges-functions [self]
  "Create functions on self for each edge in the current node"
  (when-let [current-node (:get-node self (self :current))
             edges (current-node :edges)]
    (each (edge-name edge) (pairs edges)
      (put self edge-name
           (fn [self & args] (:goto self (get edge :to) ;args))))))

(defn- goto [self to & args]
  (assert (:contains self to)
          (string/format "%q is not a valid state" to))

  # Call leave on current state
  (when-let [current-node (:get-node self (self :current))
             leave-fn (get-in current-node [:data :leave] nil)
             leave-exists (not (nil? leave-fn))]
    (leave-fn self))

  # set current to new state
  (put self :current to)

  (when-let [current-node (:get-node self (self :current))
             enter-fn (get-in current-node [:data :enter] nil)]

    (:apply-edges-functions self)

    # call enter on new state
    (when (not (nil? enter-fn))
      (enter-fn self ;args))))

(def FSM
  (merge directed-graph/Graph
         @{:apply-edges-functions apply-edges-functions
           :goto goto}))

(defmacro define
  ```
  define a Finite State Machine. This macro creates a factory or blueprint for the
  FSM. Each state is a Struct with transition functions, and optional data. The
  Resulting "factory" is pass the starting state when an actual FSM is instantiated.

  If 'enter' or 'leave' functions are defined in a state, then will be called during the
  transition. You can also provide addition arguments to a transition fn, and they will
  be passed to the 'going to' state's enter fn.

  (fsm/define colors-fsm
    (state green  (edge next yellow))
    (state yellow (edge prev green)))

  (def *colors* (colors-fsm :green))

  The ':current' field on the FSM instance will return the name of the current state.
  (*colors* :current) # -> :green

  Then call the transition methods on the FSM to move between states.
  (:next *colors*)
  (*colors* :current) # -> :yellow

  # TODO
  Additionally, you can put any arbitrary data/method in a state, and it will be available
  on the root machine when in that state. Just remember that any data will be removed when
  you leave the state!
  ```
  [name & states]


  ~(defn ,name [initial-state]
     (let [machine (table/setproto
                    (merge @{:current initial-state}
                           ,(apply directed-graph/init states))
                    ,FSM)]
       (:apply-edges-functions machine)
       machine)))
