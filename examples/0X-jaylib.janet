(use jaylib)
(import /../src/ecs :prefix "")
(import /../src/gamestate)

(def black (map |(/ $ 255) [50 47 41]))
(def white (map |(/ $ 255) [177 174 168]))
(def screen-width 400)
(def screen-height 240)

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
             (draw-poly [100 100] 5 40 0 :magenta)

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
                         (circle 40 white))
             (add-entity (self :world)
                         (position 200.0 50.0)
                         (velocity (- 2) 4)
                         (circle 40 white))

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
# https://github.com/raysan5/raylib/blob/master/examples/shaders/shaders_custom_uniform.c

(init-window 800 480 "Test Game")
(set-target-fps 30)
(hide-cursor)

(def target (load-render-texture screen-width screen-height))

(while (not (window-should-close))
  (begin-drawing)
  (clear-background black)
  (:update GS 1)
  (draw-fps 10 10)
  (end-drawing)

  # (begin-texture-mode target)
  # (draw-circle 300 400 40 white)
  # (end-texture-mode)
  # (draw-texture (get-texture-default) 0 0 :white)
  # (draw-texture-rec target.texture 0 0 screen-width screen-height [0 0] :white)
  )

(unload-render-texture target)
(close-window)
