(setdyn :doc ```
FSM (short for Finite State Machine) is a model where you define states (or nodes)
and transitions between those states, with a machine only "at" a single state at a time.

The bulk of this module consists of the (fsm/define) function, which is used to create
a state machine "blueprint" function. Check out the docs of that fn for more!
```)

(defn- goto [self to & args]
  (assert (self to) (string/format "%q is not a valid state" to))

  # Call leave method on old state
  (when (self :leave)
    (:leave self))

  # clear out old state methods from top of the table
  (each state-d (get self :state-data [])
    (put self state-d nil))

  # set current to new state
  (put self :current to)

  # put new states state-data on top of table
  (put self :state-data (keys (self (self :current))))
  (each state-d (self :state-data)
    (put self
         state-d
         (get-in self [(self :current) state-d])))

  # call enter on new state
  (when (self :enter)
    (:enter self ;args)))


(defmacro define
  ```
  define a Finite State Machine. This macro creates a factory or blueprint for the
  FSM. Each state is a Struct with transition functions, and optional data. The
  Resulting "factory" is pass the starting state when an actual FSM is instantiated.

  (fsm/define
   colors-fsm
   {:green  {:next |(:goto $ self :yellow)}
    :yellow {:prev |(:goto $ self :green)}})

  (def *colors* (colors-fsm :green))

  The ':current' field on the FSM instance will return the name of the current state.
  (*colors* :current) # -> :green

  Then call the transition methods on the FSM to move between states.
  (:next *colors*)
  (*colors* :current) # -> :yellow

  If 'enter' or 'leave' functions are defined in a state, then will be called during the
  transition. You can also provide addition arguments to a transition fn, and they will
  be passed to the 'going to' state's enter fn.

  Additionally, you can put any arbitrary data/method in a state, and it will be available
  on the root machine when in that state. Just remember that any data will be removed when
  you leave the state!
  ```

  [name states]

  (with-syms [$state-names]
    ~(defn ,name [initial-state]
       ,(let [$state-names (keys states)]
          ~(assert (find |(= $ initial-state) ,$state-names)
                   (string/format "initial state must be in %q" ,$state-names)))
       (let [machine (table/setproto (merge
                                      @{:current initial-state
                                        :goto ,goto}
                                      ,states)
                                     @{:__id__ ,(keyword name)
                                       :__validate__ (fn [& args] true)})]
         (:goto machine initial-state)
         machine))))
