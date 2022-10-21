(use /junk-drawer)


(fsm/define
 colors
 (fsm/state :green)
 (fsm/transition :next :green :yellow)

 (fsm/state :yellow)
 (fsm/transition :next :yellow :red)

 (fsm/state :red)
 (fsm/transition :next :red :green))

(def-tag next-color)

(def-system colored-printer
  {color-fsms [:colors]}
  (each [c] color-fsms
    (printf "current color: %q" (c :current))))

(def-system colored-switcher
  {wld :world
   msgs [:message :next-color]
   color-fsms [:colors]}
  (when (> (length msgs) 0)
    (each [msg] msgs
      (each [c] color-fsms
        ((msg :content) c))
      (messages/consume msg))))

(def GS (gamestate/init))

(def example
  {:name "Example Gamestate"
   :world (create-world)
   :init (fn [self]
           (let [world (get self :world)]
             (add-entity world (colors :green))
             (add-entity world (colors :red))
             (register-system world timers/update-sys)
             (register-system world messages/update-sys)
             (register-system world colored-printer)
             (register-system world colored-switcher)
             (timers/every world 4
                           (fn [wld dt]
                             (messages/send wld :next next-color)))
             (timers/after world 7
                           (fn [wld dt]
                             (messages/send wld :next next-color)))))
   :update (fn [self dt]
             (:update (self :world) dt))})

(:push GS example)

(for i 0 20
  (:update GS 1))
