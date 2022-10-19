(import ./fsm :as "fsm" :export true)

(setdyn :doc ```
Gamestates encapsulates specific states... of your game! A typical game could
consist of a menu-state, a level-state and a game-over-state. There is a single
gamestate manager which you initiate with (def *GS* (gamestate/init)), then switch
between states.

this module is a thin extension to the Finite state machine.
```)

(defmacro transition [& args] ~(as-macro ,fsm/transition ,;args))
(defmacro state [& args] ~(as-macro ,fsm/state ,;args))
(defmacro def-state [& args] ~(as-macro ,fsm/def-state ,;args))

(defn- update
  "Update the game state. Called every frame with dt arg."
  [self dt & args]
  (:current-node-call self :update dt ;args))

(defn- draw
  "Draw on the screen. Called every frame."
  [self & args]
  (:current-node-call self :draw ;args))

(def GamestateManager
  (merge fsm/FSM
         {:update update
          :draw draw}))

(defn init
  ```
  Create a new gamestate manager. Gamestates are switched to using the "switch" method.
  ```
  [] (table/setproto (fsm/create) GamestateManager))
