(import spork/test)
(import /junk-drawer/tweens)

(defmacro test-tween [tween-fn expected]
  (map |['test/assert
         ~(= (,tween-fn ,(/ $ (length expected))) ,(expected $))
         (string/format "Expect (%q %q) -> %q"
                        tween-fn
                        (/ $ (length expected))
                        (expected $))]
       (range (length expected))))

(defn tween-results [tween-fn count]
  (pp (map |(tween-fn (/ $ count))
           (range count))))

(test/start-suite 0)
(test-tween tweens/in-linear [0 0.25 0.5 0.75])
(test-tween tweens/out-linear [0 0.25 0.5 0.75])
(test-tween tweens/in-out-linear [0 0.25 0 0.25])
(test-tween tweens/out-in-linear [0 0.25 0 0.25])
(test/end-suite)

(test/start-suite 1)
(test-tween tweens/in-quad [0 0.0625 0.25 0.5625])
(test-tween tweens/out-quad [0 0.4375 0.75 0.9375])
(test-tween tweens/in-out-quad [0 0.125 0 0.375])
(test-tween tweens/out-in-quad [0 0.375 0 0.125])
(test/end-suite)
