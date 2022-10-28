(defn vector?
  "Whether or not object is a vector."
  [self]
  (and (table? self)
       (number? (self :x))
       (number? (self :y))))

(defn clone
  "deep copy of the vector."
  [self]
  (table/setproto @{:x (self :x) :y (self :y)}
                  (table/getproto self)))

(defn unpack
  "the vector as a tuple."
  [self] (values self))

(defn- apply-operator [op a b]
  (assert (vector? a) "a must be a vector.")
  (assert (or (vector? b) (number? b)) "b must be a vector or number.")
  (let [b (cond (number? b) {:x b :y b} b)]
    (put a :x (op (a :x) (b :x)))
    (put a :y (op (a :y) (b :y)))
    a))

(defn add
  "add either a number or another vector to the first vector. Mutates vector A."
  [a b] (apply-operator + a b))

(defn subtract
  "subtract either a number or another vector to the first vector. Mutates vector A."
  [a b] (apply-operator - a b))

(defn multiply
  "multiply vector A by either a number or another vector. Mutates vector A."
  [a b] (apply-operator * a b))

(defn divide
  "divide vector A by either a number or another vector. Mutates vector A."
  [a b] (apply-operator / a b))

(defn equal?
  "are the two vectors equal. Optionaly round coordinates nearest int before comparing."
  [a b &opt round]
  (default round false)
  (let [{:x ax :y ay} a
        {:x bx :y by} b]
    (if round
      (and (= (math/round ax) (math/round bx))
           (= (math/round ay) (math/round by)))
      (and (= ax bx)
           (= ay by)))))

(defn lt?
  "is vector a less then vector b?"
  [a b]
  (or (< (a :x) (b :x))
      (and (= (a :x) (b :x))
           (< (a :y) (b :y)))))

(defn lte?
  "is vector a less then or equal vector b?"
  [a b]
  (and (<= (a :x) (b :x))
       (<= (a :y) (b :y))))

(defn length2
  [self]
  (+ (* (self :x) (self :x))
     (* (self :y) (self :y))))

(defn length
  [self]
  (math/sqrt (:length2 self)))

(defn to-polar
  "polar version of the vector"
  [self]
  (table/setproto {:x (math/atan2 (self :x) (self :y))
                   :y (:length self)}
                  (table/getproto self)))

(defn distance2
  "the squared distance between vectors A and B"
  [a b]
  (assert (vector? a) "a must be a vector.")
  (assert (vector? b) "b must be a vector.")
  (let [dx (- (a :x) (b :x))
        dy (- (a :y) (b :y))]
    (+ (* dx dx)
       (* dy dy))))

(defn distance
  "the distance between vectors A and B."
  [a b]
  (math/sqrt (:distance2 a b)))

(defn normalize
  "Normalize the vector in place."
  [self]
  (if-let [l (:length self)
           greater-then-zero? (> l 0)]
    (:divide self l)
    self))

(defn rotate
  "rotate the vector by angle phi."
  [self phi]
  (let [c (math/cos phi)
        s (math/sin phi)]
    (put self :x (- (* c (self :x))
                    (* s (self :y))))
    (put self :y (+ (* s (self :x))
                    (* c (self :y))))))

(defn perpendicular
  "return a new vector perpendicular to this one."
  [self]
  (table/setproto @{:x (- (self :y)) :y (self :x)}
                  (table/getproto self)))


(defn preject-on
  [self v]
  (assert (vector? v) "v must be a vector.")
  (let [{:x vx :y vy} v
        s (/ (+ (* (self :x) vx)
                (* (self :y) vy))
             (+ (* vx vx)
                (* vy vy)))]
    (table/setproto @{:x (* s vx) :y (* s vy)}
                    (table/getproto self))))


(defn mirror-on
  [self v]
  (assert (vector? v) "v must be a vector.")
  (let [{:x sx :y sy} self
        {:x vx :y vy} v
        s (* 2
             (/ (+ (* sx vx)
                   (* sy vy))
                (+ (* vx vx)
                   (* vy vy))))]
    (table/setproto @{:x (- (* s vx) sx)
                      :y (- (* s vy) sy)}
                    (table/getproto self))))

(defn cross
  ""
  [self v]
  (assert (vector? v) "v must be a vector.")
  (- (* (self :x) (v :y))
     (* (self :y) (v :x))))

(defn trim
  "truncate vector length to max-length."
  [self max-length]
  (let [s (/ (* max-length max-length)
             (:length2 self))]
    (put self :x (* (self :x) s))
    (put self :y (* (self :y) s))))

(defn angle-to
  ""
  [self &opt other]
  (if other
    (- (math/atan2 (self :x) (self :y))
       (math/atan2 (other :x) (other :y)))
    (math/atan2 (self :x) (self :y))))

(def Vector
  @{:clone clone
    :unpack unpack
    :add add
    :subtract subtract
    :multiply multiply
    :divide divide
    :equal? equal?
    :lt? lt?
    :lte? lte?
    :length2 length2
    :length length
    :to-polar to-polar
    :distance2 distance2
    :distance distance
    :normalize normalize
    :rotate rotate
    :perpendicular perpendicular
    :preject-on preject-on
    :mirror-on mirror-on
    :cross cross
    :trim trim
    :angle-to angle-to
    :__validate__ vector?
    :__id__ :vector})

(defn new [&opt x y]
  (default x 0)
  (default y 0)
  (assert (number? x) "x must be a number")
  (assert (number? y) "y must be a number")
  (table/setproto @{:x x :y y} Vector))

(defn from-polar [angle &opt radius]
  (default radius 1)
  (new (* (math/cos angle) radius)
       (* (math/sin angle) radius)))

(defn random-direction [&opt len-min len-max seed]
  (default len-min 1)
  (default len-max len-min)
  (default seed nil)
  (assert (> len-max 0) "len-max must be greater than zero")
  (assert (>= len-max len-min) "len-max must be greater than or equal to len-min")
  (let [rng (math/rng seed) ]
    (from-polar (* (math/rng-uniform rng) 2 math/pi)
                (* (math/rng-uniform rng) (+ (- len-max len-min) len-min)))))
