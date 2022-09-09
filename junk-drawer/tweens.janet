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

Additionally, by adding the tween component to an entity, you can tween other components values

(add-component world ent col
               (color :r 255 :g 0 :b 128)
               tweens/in-cubic
               10)

check out examples/07-tweens.janet for something more complete
```)

(defn- flip [f]
  "flip a tween"
  (fn [s & args]
    (- 1 (f (- 1 s) ;args))))

(defn- chain [f1 f2]
  "chain 2 tweens together"
  (fn [s & args]
    (* 0.5
       (if (< s 0.5)
         (f1 (* 2 s) ;args)
         (+ 1 (f2 (- (* 2 s) 1) ;args))))))

(defmacro- def-tween [name & body]
  "define the in, out, in-out, and out-in versions of a tween"
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

(defn- interpolate [&keys {:start start
                           :current current
                           :end end
                           :func func
                           :duration duration
                           :elapsed-time elapsed-time}]
  (match (type current)
    :number
     (+ current (* (- end current)
                   (func (/ elapsed-time duration))))
    :table
     (table
      ;(mapcat
        (fn [[key end-val]]
          [key (interpolate :start (get start key)
                            :current (get current key)
                            :end end-val
                            :func func
                            :duration duration
                            :elapsed-time elapsed-time)])
        (pairs end)))))

(defn tween [start end func duration]
  (assert (find |(= $ (type start)) [:number :table])
          "currently only supports tweening numbers or tables")
  (table/setproto @{:start start
                    :current start
                    :end end
                    :func func
                    :duration duration
                    :elapsed-time 0
                    :complete false}
                  @{:__id__ :tween
                    :__validate__ (fn [& args] true)}))

(def-system update-sys
  {active-tweens [:entity :tween] wld :world}
  (each [ent twn] active-tweens
    (put twn :elapsed-time (+ (twn :elapsed-time) dt))
    (put twn :current (interpolate ;(kvs twn)))

    (cond
      (get twn :complete)
      (remove-component wld ent :tween)

      (>= (twn :elapsed-time) (twn :duration))
      (put twn :complete true))))
