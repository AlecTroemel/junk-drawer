(use /junk-drawer)

(gamestate/def-state
 menu
 :init (fn menu-init [self] (print "menu init"))
 :enter (fn menu-enter [self prev & args] (printf "menu enter %q" args))
 :update (fn menu-update [self dt] (print "menu game state dt: " dt)))

(gamestate/def-state
 game
 :init (fn game-init [self] (print "game init"))
 :update (fn game-update [self dt] (print "game game state dt: " dt))
 :leave (fn game-leave [self to] (print "game leave")))

(var dt 0)
(def *GS* (gamestate/init))

(:add-state *GS* menu)
(:add-state *GS* game)
(:add-edge *GS* (gamestate/transition :start-game :menu :game))
(:add-edge *GS* (gamestate/transition :back-to-menu :game :menu))

(:goto *GS* :menu)
(:update *GS* dt)
(+= dt 1)

(print "switching to game")
(:start-game *GS*)
(:update *GS* dt)
(+= dt 1)

(print "Lets go back to the menu")
(:back-to-menu *GS*)
(:update *GS* dt)
