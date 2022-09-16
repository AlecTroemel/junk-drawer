<img src="/junk-drawer-logo.gif" width="100%" alt="Junk Drawer hand drawn logo"/>

Everyones got one (usually somewhere in the kitchen). __Junk Drawer__ is a small collection of tools & utils for developing games in the wonderful [Janet Lang](https://janet-lang.org).

```bash
sudo jpm install https://github.com/AlecTroemel/junk-drawer
```

### Contents:

- `ecs`: A simple Entity Component System
- `fsm`: Finite(ish) State Machine
- `gamestate`: Easy gamestate management.
- `timers`: Delayed & Schedule functions (requires using ECS)
- `messages`: Communication between systems (requires using ECS)
- `tweens`: Some common tweening functions and a way to interpolate with them (mostly requires ECS)

Here's an obligitory example that uses most the stuff here.

```janet
(use junk-drawer)

(fsm/define
  colors
  {:green
   {:next |(:goto $ :yellow)}
   :yellow
   {:next |(:goto $ :red)}
   :red
   {:next |(:goto $ :green)}})

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
```

Each module, and most of the public functions, have detailed doc strings for your reading.

```janet
(doc junk-drawer)
(doc junk-drawer/ecs)
(doc junk-drawer/ecs/def-component)
```

If you're looking for more complete examples...check out the `examples/` folder!
