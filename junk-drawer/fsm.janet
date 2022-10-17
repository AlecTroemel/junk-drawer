(import ./directed-graph :as "digraph" :export true)

(setdyn :doc ```
FSM (short for Finite State Machine) is a model where you define states (or nodes)
and transitions between those states, with a machine only "at" a single state at a time.

This module extends the directed-graph. The main way you'll use it is with
 the (fsm/define) function, which is used to create a state machine "blueprint" function.
Check out the docs of that fn for more!
```)

(defn- current-node-call [self fn-name & args]
  (when-let [current-node (:get-node self (self :current))
             leave-fn (get-in current-node [:data fn-name] nil)
             leave-exists (not (nil? leave-fn))]
    (leave-fn self ;args)))

(defn- apply-edges-functions [self]
  "Create functions on self for each edge in the current node"
  (when-let [current-node (:get-node self (self :current))
             edges (current-node :edges)]
    (each (edge-name edge) (pairs edges)
      (put self edge-name
           (fn [self & args] (:goto self (get edge :to) ;args)))))
  self)

(defn- apply-data-to-root [self]
  # clear out old fields
  (each key (self :current-data-keys)
    (put self key nil))
  (put self :current-data-keys @[])

  # apply data to root of fsm
  (let [current-node (:get-node self (self :current))
        {:data data} current-node]
    (each (key val) (pairs data)
      (array/push (self :current-data-keys) key)
      (put self key val))))

(defn- goto [self to & args]
  (assert (:contains self to) (string/format "%q is not a valid state" to))
  (:current-node-call self :leave)

  (put self :current to)
  (:apply-edges-functions self)
  (:apply-data-to-root self)

  (when (nil? (get-in self [:visited to]))
    (:current-node-call self :init)
    (put-in self [:visited to] true))

  (:current-node-call self :enter ;args))

(def FSM
  (merge digraph/Graph
         @{:current @{}
           :current-data-keys @[]
           :visited @{}
           :current-node-call current-node-call
           :apply-edges-functions apply-edges-functions
           :apply-data-to-root apply-data-to-root
           :goto goto
           :add-state (get digraph/Graph :add-node)}))

(defn create [& states]
  (table/setproto (digraph/create ;states)
                  FSM))

(defmacro transition [& args] ~(as-macro ,digraph/edge ,;args))
(defmacro state [& args] ~(as-macro ,digraph/node ,;args))
(defmacro def-state [name & args]
  ~(def ,(symbol name)
     (as-macro ,state ,(keyword name) ,;args)))

(defmacro define
  ```
  define a Finite State Machine. This macro creates a factory or blueprint for the
  FSM. Each state is a Struct with transition functions, and optional data. The
  Resulting "factory" is pass the starting state when an actual FSM is instantiated.

  If 'enter' or 'leave' functions are defined in a state, then will be called during the
  transition. You can also provide addition arguments to a transition fn, and they will
  be passed to the 'going to' state's enter fn.

  If the 'init' function is defined on the state, it will be called only once the first
  time the state is visited.

  (fsm/define colors-fsm
            (state green
                   :enter (fn [self] (print "entering green"))
                   :leave (fn [self] (print "entering leaving")))
            (edge next yellow)

            (state yellow
                   :init (fn [self] (print "visiting yellow for the first time"))
                   :enter (fn [self] (print "entering yellow")))
            (edge prev green))

  (def *colors* (colors-fsm :green))

  The ':current' field on the FSM instance will return the name of the current state.
  (*colors* :current) # -> :green

  Then call the transition methods on the FSM to move between states.
  (:next *colors*)
  (*colors* :current) # -> :yellow

  # TODO
  Additionally, you can put any arbitrary data/methods in a state, and it will be available
  on the root machine when in that state. Just remember that any data will be removed when
  you leave the state!
  ```
  [name & states]

  ~(defn ,name [&opt initial-state]
     (-> (,create ,;states)
         (put :current initial-state)
         (:apply-edges-functions))))
