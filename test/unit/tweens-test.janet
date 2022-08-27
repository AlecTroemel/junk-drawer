(import spork/test)
(import /junk-drawer/tweens)

(defmacro test-tween [tween-fn expected]
  (map |['test/assert
         ~(= (,tween-fn ,(/ $ (length expected))) ,(expected $))
         (string/format "Expect (%q %q) -> %q" tween-fn (/ $ (length expected)) (expected $))]
       (range (length expected))))

(test/start-suite 0)

(test-tween tweens/in-linear [0 0.25 0.5 0.75])
(test-tween tweens/out-linear [0 0.25 0.5 0.75])
(test-tween tweens/in-out-linear [0 0.25 0 0.25])
(test-tween tweens/out-in-linear [0 0.25 0 0.25])

(test/end-suite)
