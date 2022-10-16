(import ./fsm)

(setdyn :doc ```
Gamestates encapsulates specific states... of your game! A typical game could
consist of a menu-state, a level-state and a game-over-state. There is a single
gamestate manager which you initiate with (def *GS* (gamestate/init)), then switch
between states.
```)

(defn- goto
  [self to & args]
  (assert (:contains self to)
          (string/format "%q is not a valid state" to))
  (:current-node-call self :leave)

  (put self :current to)
  (:apply-edges-functions self)

  (when (nil? (get-in self [:initialized-states to]))
    (:current-node-call self :init))
  (put-in self [:initialized-states to] true)

  (:current-node-call self :enter ;args))

(defn- update
  "Update the game state. Called every frame."
  [self dt & args]
  (:current-node-call self :update dt ;args))

(defn- draw
  "Draw on the screen. Called every frame."
  [self & args]
  (:current-node-call self :draw ;args))

(def GamestateManager
  (merge fsm/FSM
         {:goto goto
          :update update
          :draw draw}))

(fsm/def-fsm gamestate-manager)

(defmacro transition [& args] ~(as-macro ,fsm/transition ,;args))
(defmacro def-state [name & args]
  ~(def ,(symbol name)
     (as-macro ,fsm/state ,(keyword name) ,;args)))

(defn init
  ```
  Create a new gamestate manager. Gamestates are switched to using the "switch" method.
  ```
  []
  (table/setproto (merge {:initialized-states @{}}
                         (gamestate-manager))
                  GamestateManager))

# TODO: create way to define "tick" methods like update/draw/tic
