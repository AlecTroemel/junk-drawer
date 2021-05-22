(use jaylib)
(use /junk-drawer)

(def black (map |(/ $ 255) [50 47 41]))
(def white (map |(/ $ 255) [177 174 168]))
(def screen-width 400)
(def screen-height 240)

(def GS (gamestate/init))

# Components
(def-component position :x :number :y :number)
(def-component velocity :x :number :y :number)
(def-component circle :radius :number :color :any)

# System Callbacks
(def-system sys-move
  {moveables [:position :velocity]}
  (each [pos vel] moveables
    (put pos :x (+ (pos :x) (* dt (vel :x))))
    (put pos :y (+ (pos :y) (* dt (vel :y))))))

(def-system sys-draw-circle
  {circles [:position :circle]}
  (each [pos circle] circles
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
                         (position :x 100.0 :y 100.0)
                         (velocity :x 1 :y 2)
                         (circle :radius 40 :color white))
             (add-entity (self :world)
                         (position :x 200.0 :y 50.0)
                         (velocity :x (- 2) :y 4)
                         (circle :radius 40 :color white))

             # Systems
             (register-system (self :world) sys-move)
             (register-system (self :world) sys-draw-circle)))

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
