(use /junk-drawer/ecs)

(setdyn :doc ```
Tweens (short for in-betweening) allows you to interpolate values using predefined functions,
the applet here https://hump.readthedocs.io/en/latest/timer.html#tweening-methods
gives a good visualization of what happens.

This module defines these tweening functions, each with "in-NAME", "out-NAME", "in-out-NAME", and "out-in-NAME"
varients.

- linear
- quad
- cubic
- quart
- quint
- sine
- expo
- circ
- back
- bounce
- elastic

(tween/in-cubic 0.5) # -> 0.125

Additionally, You can tween component values on an entity using the
(tweens/create) function. Read the docs for that fn, or check out
examples/07-tweens.janet for more!
```)

(defn- flip
  "flip a tween"
  [f]
  (fn [s & args]
    (- 1 (f (- 1 s) ;args))))

(defn- chain
  "chain 2 tweens together"
  [f1 f2]
  (fn [s & args]
    (* 0.5
       (if (< s 0.5)
         (f1 (* 2 s) ;args)
         (+ 1 (f2 (- (* 2 s) 1) ;args))))))

(defmacro- def-tween
  "define the in, out, in-out, and out-in versions of a tween"
  [name & body]
  (with-syms [$in $out $in-out $out-in]
    (let [$in (symbol "in-" name)
          $out (symbol "out-" name)
          $in-out (symbol "in-out-" name)
          $out-in (symbol "out-in-" name)]
      ~(upscope
        (defn ,$in [s] ,;body)
        (def ,$out (flip ,$in))
        (def ,$in-out (chain ,$in ,$out))
        (def ,$out-in (chain ,$out ,$in))))))

(def-tween linear s)
(def-tween quad (* s s))
(def-tween cubic (* s s s))
(def-tween quart (* s s s s))
(def-tween quint (* s s s s s))
(def-tween sine (- 1 (math/cos (* s (/ math/pi 2)))))
(def-tween expo (math/exp2 (* 10 (- s 1))))
(def-tween circ  (- 1 (math/sqrt (- 1 (* s s)))))

# warning: magic numbers ahead
(def-tween back (* s s (- (* s 2.70158) 1.70158)))

(def-tween bounce
  (let [a 7.5625 b (/ 1 2.75)]
    (min (* a (math/pow s 2))
         (+ 0.75 (* a (math/pow (- s (* b (- 1.5))) 2)))
         (+ 0.9375 (* a (math/pow (- s (* b (- 2.25))) 2)))
         (+ 0.984375 (* a (math/pow (- s (* b (- 2.625))) 2))))))

(def-tween elastic
  (let [amp 1 period 0.3]
    (* (- amp)
       (math/sin (- (* 2 (/ math/pi period) (- s 1)) (math/asin (/ 1 amp))))
       (math/exp2 (* 10 (dec s))))))

(def-component tween
  :entity :number
  :component :keyword
  :to :table
  :with :function
  :duration :number
  :elapsed-time :number)

(defn create
  ```
  Create a tween entity which will tween the provided component
  on the entity to the "to" value over "duration" with the "with"
  tweening fn. Requires registering (tweens/update-sys) in your ECS.

  (def-component example
    :a :number            # can only tween numbers
    :b (props :c :number) # nested objects of numbers are tweened recursively
    :d :string)           # anything other then numbers are ignored

  ... later on in a system ...

  (tweens/create wld ent :component :example
       :to {:a 10 :b {:c 34}} # could also use the component fn, but defining unused string seemed wrong.
       :with tweens/in-cubic
       :duration 10)          # take 10 Ticks of the ecs to complete
  ```
  [world ent &named component to with duration]
  (add-entity world (tween :entity ent
                           :component component
                           :to to
                           :with with
                           :duration duration
                           :elapsed-time 0)))

(defn- bucket-by-component
  ```
  fiber that yields [tween-ent tween-data current to elapsed duration func]
  for each tween. Does this by:
  1. bucketting the tweens by component
  2. querying the ECS for entities with that component
  3. 'filtering' the query results for the ecs in tweens
  ```
  [wld tweens]
  (fn []
    (loop [[cmp tweens] :pairs (group-by |(get-in $ [1 :component]) tweens)
           [tweening-ent current] :in (:view wld [:entity cmp])
           :let [tween (find |(= (get-in $ [1 :entity]) tweening-ent) tweens)]
           :when (not (nil? tween))]
      (yield [(tween 0) (tween 1) current]))))

(defn- interpolate
  ```
  Recursively apply tween 'func' to all fields of 'current'.
  ```
  [current to elapsed duration func]
  (match (type current)
    :number (+ current (* (- to current) (func (/ elapsed duration))))
    :table (table ;(mapcat |[$ (interpolate (get current $)
                                            (get to $)
                                            elapsed
                                            duration
                                            func)]
                           (keys to)))))

(def-system update-sys
  {tweens [:entity :tween] wld :world}
  (loop [[tween-ent tween-data current] :in (fiber/new (bucket-by-component wld tweens))
         :let [{:to to
                :elapsed-time elapsed
                :duration duration
                :with func} tween-data]]

    # current in this context is the actual component on the entity being tweened
    # So we need to get the new "interpolated value" and apply each key on the
    # actual component table
    (each [key val] (pairs (interpolate current to elapsed duration func))
      (put current key val))

    # Tick the tweens elapsed time, delete it if we've reached its duration
    (if-let [new-elapsed (+ elapsed 1)
             complete? (> new-elapsed duration)]
      (remove-entity wld tween-ent)
      (put tween-data :elapsed-time new-elapsed))))
