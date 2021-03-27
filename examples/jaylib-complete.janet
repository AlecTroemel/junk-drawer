(use jaylib)
(import /../src/ecs :prefix "")
(import /../src/gamestate)

(def GS (gamestate/init))

# Components
(def-component position [x y])
(def-component velocity [x y])
(def-component circle [radius color])

# System Callbacks
(defn sys-move [q dt]
  (each [pos vel] q
    (put pos :x (+ (pos :x) (* dt (vel :x))))
    (put pos :y (+ (pos :y) (* dt (vel :y))))))

(defn sys-draw-circle [q dt]
  (each [pos circle] q
    (draw-circle
     (pos :x) (pos :y)
     (circle :radius) (circle :color))))

(def pause
  {:update (fn pause-update [self dt]
             (draw-poly [500 200] 5 40 0 :magenta)

             (when (key-pressed? :space)
               (:pop GS)))})

(def game
  {:name "Game"
   :world (create-world)
   :init (fn game-init [self]
           (let [world (get self :world)]
             # Entities
             (add-entity world
                         (position 100.0 100.0)
                         (velocity 1 2)
                         (circle 40 :red))
             (add-entity (self :world)
                         (position 500.0 500.0)
                         (velocity (- 2) 4)
                         (circle 40 :blue))

             # Systems
             (register-system (self :world)
                              [:position :velocity]
                              sys-move)
             (register-system (self :world)
                              [:position :circle]
                              sys-draw-circle)))

   :update (fn game-update [self dt]
             (:update (self :world) dt)

             (when (key-pressed? :space)
               (:push GS pause)))})

(:push GS game)

# Jayley Code
(init-window 1000 1000 "Test Game")
(set-target-fps 60)
(hide-cursor)

(while (not (window-should-close))
  (begin-drawing)
  (clear-background [0 0 0])
  (:update GS 1)
  (end-drawing))

(close-window)
