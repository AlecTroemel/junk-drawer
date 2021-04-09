(use ./ecs)

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
         (f2 (- (* 2 s) 1) ;args)))))

(defmacro def-tween [name & body]
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

(def-component tween
  [start end func duration elapsed-time complete])

(def-system update-sys
  (tweens [:entity :tween] wld :world)
  (each [ent twn] tweens
    (put twn :elapsed-time (+ (twn :elapsed-time) dt))
    (cond
      (get twn :complete)
      (remove-entity wld ent)

      (>= (twn :elapsed-time) (twn :duration))
      (put twn :complete true))))

(defn- deep-interpolate [val start end func duration elapsed-time complete]
  (match (type val)
    :number (+ val (* (- end val)
                      (func (/ elapsed-time duration))))
    :table (merge val
                  (table ;(mapcat |(tuple ($ 0)
                                          (deep-interpolate ($ 1)
                                                            (start ($ 0))
                                                            (end ($ 0))
                                                            func
                                                            duration
                                                            elapsed-time
                                                            complete))
                                  (pairs val))))))

# TODO: need to get tween start|end when calling recursively
(defn interpolate [val twn]
  "return the val interpolated by the tween."
  (assert (find |(= $ (type val)) [:number :table]) "val is not a supported type")
  (deep-interpolate val
                    (twn :start)
                    (twn :end)
                    (twn :func)
                    (twn :duration)
                    (twn :elapsed-time)
                    (twn :complete)))
