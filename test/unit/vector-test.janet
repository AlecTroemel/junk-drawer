(import spork/test)
(import /junk-drawer/vector)

# Operators: add, subtract, multiply, and divide
(test/start-suite 0)
(let [vec-a (vector/new 1 2)
      vec-b (vector/new 3 4)]
  (test/assert (= (table/to-struct (:add vec-a 3)) {:x 4 :y 5})
               "add number to vector")
  (test/assert (= (table/to-struct (:add vec-a vec-b)) {:x 7 :y 9})
               "add vector to vector"))

(let [vec-a (vector/new 10 10)
      vec-b (vector/new 5 5)]
  (test/assert (= (table/to-struct (:subtract vec-a 1)) {:x 9 :y 9})
               "subtract number to vector")
  (test/assert (= (table/to-struct (:subtract vec-a vec-b)) {:x 4 :y 4})
               "subtract vector to vector"))

(let [vec-a (vector/new 2 2)
      vec-b (vector/new 3 4)]
  (test/assert (= (table/to-struct (:multiply vec-a 2)) {:x 4 :y 4})
               "multiple vector by number")
  (test/assert (= (table/to-struct (:multiply vec-a vec-b)) {:x 12 :y 16})
               "multiple vector by vector"))

(let [vec-a (vector/new 12 8)
      vec-b (vector/new 1 2)]
  (test/assert (= (table/to-struct (:divide vec-a 2)) {:x 6 :y 4})
               "divide vector by number")
  (test/assert (= (table/to-struct (:divide vec-a vec-b)) {:x 6 :y 2})
               "divide vector by vector"))
(test/end-suite)

# Comparisons: equal?, lt? and lte?
(test/start-suite 1)
(let [vec-a (vector/new 12 8)
      vec-b (vector/new 1 2)
      vec-c (vector/new 12 8)]
  (test/assert (not (:equal? vec-a vec-b))
               "equal? not equal")
  (test/assert (:equal? vec-a vec-c)
               "equal? are equal")

  (test/assert (not (:lt? vec-a vec-b))
               "lt? not less then")
  (test/assert (:lt? vec-b vec-a)
               "lt? is less then")

  (test/assert (not (:lte? vec-a vec-b))
               "lte? first greater then second")
  (test/assert (:lte? vec-b vec-c)
               "lte? first less then second")
  (test/assert (:lte? vec-a vec-c)
               "lte? are equal"))
(test/end-suite)

# Length
(test/start-suite 3)
(let [vec-a (vector/new 6 8)]
  (test/assert (= (:length2 vec-a) 100)
               "length 2 calculated correctly")
  (test/assert (= (:length vec-a) 10)
               "length calculated correctly"))
(test/end-suite)

# to Polar
(test/start-suite 4)
(let [vec (vector/new 20 34)
      expected (vector/new (math/round 0.5317) (math/round 39.4452))]
  (test/assert (:equal? expected (:to-polar vec) true)
               "to-polar equals expected vec.. rounded at least"))
(test/end-suite)

# distance
(test/start-suite 5)
(let [vec-a (vector/new 0 0)
      vec-b (vector/new 8 8)]
  (test/assert (= (:distance2 vec-a vec-b) 128)
               "distance 2")
  (test/assert (> 0.001 (- (:distance vec-a vec-b) 11.3137))
               "distance"))
(test/end-suite)

# normalize
(test/start-suite 6)
(let [vec-a (vector/new 8.5 8)
      normalized (:normalize vec-a)]
  (test/assert (> 0.001 (- (normalized :x) 0.7282))
               "normalized x")
  (test/assert (> 0.001 (- (normalized :y) 0.6853))
               "normalized y"))
(test/end-suite)

# perpendicular
(test/start-suite 7)
(let [vec-a (vector/new 8.5 8)
      expected (vector/new -8 8.5)]
  (test/assert (:equal? expected (:perpendicular vec-a))
               "perpendicular"))
(test/end-suite)

# preject-on, mirror-on
(test/start-suite 8)
(let [vec-a (vector/new 8.5 8)
      vec-b (vector/new 2 2)]
  (test/assert (:equal? (vector/new 8.25 8.25) (:preject-on vec-a vec-b))
               "preject on")
  (test/assert (:equal? (vector/new 8 8.5) (:mirror-on vec-a vec-b))
               "mirror on"))
(test/end-suite)

# Cross
(test/start-suite 8)
(let [vec-a (vector/new 9 16)
      vec-b (vector/new 2 2)]
  (test/assert (= (:cross vec-a vec-b) -14)
               "cross vec-a and vec-b"))
(test/end-suite)

# trim
(test/start-suite 9)
(let [vec-a (vector/new 9 16)
      trimmed (:trim vec-a 10)]
  (test/assert (> 0.001 (- (trimmed :x) 2.6706)) "trimmed to 10 x")
  (test/assert (> 0.001 (- (trimmed :y) 4.7477)) "trimmed to 10 y"))
(test/end-suite)

# angle-to
(test/start-suite 9)
(let [vec-a (vector/new 0 1)
      vec-b (vector/new 1 0)]
  (test/assert (> 0.001 (- (:angle-to vec-a vec-b) -1.5708))
               "angle to another vector")
  (test/assert (> 0.001 (- (:angle-to vec-a) 0))
               "angle to origin"))
(test/end-suite)

# from-polar
(test/start-suite 10)
(let [vec (vector/from-polar math/pi 10)]
  (test/assert (> 0.001 (- (vec :x) -10)) "from polar x")
  (test/assert (> 0.001 (- (vec :y) 0)) "from polar y"))
(test/end-suite)

# from-tuple
(test/start-suite 10)
(let [vec (vector/from-tuple [1 3])]
  (test/assert (= 1 (vec :x)) "from tuple x")
  (test/assert (= 3 (vec :y)) "from tuple y"))
(test/end-suite)

# random-direction
(test/start-suite 11)
(let [seed 1
      vec (vector/random-direction 1 5 seed)]
  (test/assert (> 0.001 (- (vec :x) 1.30893)) "random-direction x")
  (test/assert (> 0.001 (- (vec :y) 4.54775)) "random-direction y"))
(test/end-suite)
