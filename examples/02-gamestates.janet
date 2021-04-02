(import ./../src/junk-drawer)

(def menu
  {:init (fn [self] (print "menu init"))
   :enter (fn [self prev & args] (printf "menu enter %q" args))
   :update (fn [self dt] (print "menu game state dt: " dt))})

(def game
  {:init (fn [self] (print "game init"))
   :update (fn [self dt] (print "game game state dt: " dt))
   :leave (fn [self] (print "game leave"))})

(var dt 0)
(def GS (gamestate/init))

(:push GS menu)
(:update GS dt)

(print "pushing game")
(set dt (inc dt))
(:push GS game)
(:update GS dt)

(print "poppting game")
(set dt (inc dt))
(:pop GS)
(:update GS dt)
