(use ./../src/junk-drawer)

(def world (create-world))
(register-system world timer/update-sys)

(timer/after world 10
 (fn [] (print "after: 10 ticks have passed")))

(timer/during world 5
 (fn [dt] (print "during"))
 (fn [] (print "during is complete")))

(timer/every world 2
 (fn [] (print "every 2, but only 3 times"))
 3)

(for i 0 15
  (print "i: " i)
  (:update world 1)
  (print ""))
