(import spork/test)
(import /junk-drawer/tweens)

(defmacro test-tween [tween-fn expected]
  (map |['test/assert
         ~(= (,tween-fn ,(/ $ (length expected))) ,(expected $))
         ~(string/format "Expect %q at %q got %q"
                         (,tween-fn ,(/ $ (length expected)))
                        ,(/ $ (length expected))
                        ,(expected $))]
       (range (length expected))))

(defn tween-results [tween-fn count]
  (pp (map |(tween-fn (/ $ count))
           (range count))))

(test/start-suite 0)
(test-tween tweens/in-linear [0 0.25 0.5 0.75])
(test-tween tweens/out-linear [0 0.25 0.5 0.75])
(test-tween tweens/in-out-linear [0 0.25 0.5 0.75])
(test-tween tweens/out-in-linear [0 0.25 0.5 0.75])
(test/end-suite)

(test/start-suite 1)
(test-tween tweens/in-quad [0 0.0625 0.25 0.5625])
(test-tween tweens/out-quad [0 0.4375 0.75 0.9375])
(test-tween tweens/in-out-quad [0 0.125 0.5 0.875])
(test-tween tweens/out-in-quad [0 0.375 0.5 0.625])
(test/end-suite)

(test/start-suite 2)
(test-tween tweens/in-cubic [0 0.015625 0.125 0.421875])
(test-tween tweens/out-cubic [0 0.578125 0.875 0.984375])
(test-tween tweens/in-out-cubic [0 0.0625 0.5 0.9375])
(test-tween tweens/out-in-cubic [0 0.4375 0.5 0.5625])
(test/end-suite)

(test/start-suite 3)
(test-tween tweens/in-quart [0 0.00390625 0.0625 0.316406])
(test-tween tweens/out-quart [0 0.683594 0.9375 0.996094])
(test-tween tweens/in-out-quart [0 0.03125 0.5 0.96875])
(test-tween tweens/out-in-quart [0 0.46875 0.5 0.53125])
(test/end-suite)

(test/start-suite 4)
(test-tween tweens/in-quint [0 0.000976562 0.03125 0.237305])
(test-tween tweens/out-quint [0 0.762695 0.96875 0.999023])
(test-tween tweens/in-out-quint [0 0.015625 0.5 0.984375])
(test-tween tweens/out-in-quint [0 0.484375 0.5 0.515625])
(test/end-suite)

(test/start-suite 5)
(test-tween tweens/in-sine [0 0.0761205 0.292893 0.617317])
(test-tween tweens/out-sine [1.11022e-16 0.382683 0.707107 0.92388])
(test-tween tweens/in-out-sine [0 0.146447 0.5 0.853553])
(test-tween tweens/out-in-sine [5.55112e-17 0.353553 0.5 0.646447])
(test/end-suite)

(test/start-suite 6)
(test-tween tweens/in-expo [0.000976562 0.00552427 0.03125 0.176777])
(test-tween tweens/out-expo [0 0.823223 0.96875 0.994476])
(test-tween tweens/in-out-expo [0.000488281 0.015625 0.5 0.984375])
(test-tween tweens/out-in-expo [0 0.484375 0.500488 0.515625])
(test/end-suite)

(test/start-suite 7)
(test-tween tweens/in-circ [0 0.0317542 0.133975 0.338562])
(test-tween tweens/out-circ [0 0.661438 0.866025 0.968246])
(test-tween tweens/in-out-circ [0 0.0669873 0.5 0.933013])
(test-tween tweens/out-in-circ [0 0.433013 0.5 0.566987])
(test/end-suite)

(test/start-suite 8)
(test-tween tweens/in-back [0 -0.0641366 -0.0876975 0.18259])
(test-tween tweens/out-back [2.22045e-16 0.81741 1.0877 1.06414])
(test-tween tweens/in-out-back [0 -0.0438488 0.5 1.04385])
(test-tween tweens/out-in-back [1.11022e-16 0.543849 0.5 0.456151])
(test/end-suite)

(test/start-suite 9)
(test-tween tweens/in-bounce [0 0.472656 1.89062 4.25391])
(test-tween tweens/out-bounce [-6.5625 -3.25391 -0.890625 0.527344])
(test-tween tweens/in-out-bounce [0 0.945312 -2.78125 0.0546875])
(test-tween tweens/out-in-bounce [-3.28125 -0.445312 0.5 1.44531])
(test/end-suite)

(test/start-suite 10)
(test-tween tweens/in-elastic [-0.000488281 -0.00552427 -0.015625 0.0883883])
(test-tween tweens/out-elastic [0 0.911612 1.01562 1.00552])
(test-tween tweens/in-out-elastic [-0.000244141 -0.0078125 0.5 1.00781])
(test-tween tweens/out-in-elastic [0 0.507812 0.499756 0.492188])
(test/end-suite)
