(setdyn :doc ```
2D vector which providing most of the things you do with vectors.
Represented as a table {:x number :y number}.
```)

(defn vector?
  "Is the object a vector."
  [self]
  (and (table? self)
       (number? (self :x))
       (number? (self :y))))

(defn clone
  "Deep copy of the vector."
  [self]
  (table/setproto @{:x (self :x) :y (self :y)}
                  (table/getproto self)))

(defn unpack
  "The vector as a tuple."
  [self] (values self))

(defn- apply-operator [op a b]
  (assert (vector? a) "a must be a vector.")
  (assert (or (vector? b) (number? b)) "b must be a vector or number.")
  (let [b (cond (number? b) {:x b :y b} b)]
    (put a :x (op (a :x) (b :x)))
    (put a :y (op (a :y) (b :y)))
    a))

(defn add
  "Add either a number or another vector to this vector. Mutates the first vector."
  [self v] (apply-operator + self v))

(defn subtract
  "Subtract either a number or another vector from the this vector. Mutates the first vector."
  [self v] (apply-operator - self v))

(defn multiply
  "Multiply this vector by either a number or another vector. Mutates the first vector."
  [self v] (apply-operator * self v))

(defn divide
  "Divide this vector by either a number or another vector. Mutates the first vector."
  [self v] (apply-operator / self v))

(defn equal?
  "Is this vector equal to another? Optionaly round coordinates nearest int before comparing."
  [self v &opt round]
  (default round false)
  (let [{:x ax :y ay} self
        {:x bx :y by} v]
    (if round
      (and (= (math/round ax) (math/round bx))
           (= (math/round ay) (math/round by)))
      (and (= ax bx)
           (= ay by)))))

(defn lt?
  "Is vector A less then vector B?"
  [self v]
  (or (< (self :x) (v :x))
      (and (= (self :x) (v :x))
           (< (self :y) (v :y)))))

(defn lte?
  "Is vector A less then or equal vector B?"
  [self v]
  (and (<= (self :x) (v :x))
       (<= (self :y) (v :y))))

(defn vlength2
  "The squared length of vector."
  [self]
  (+ (* (self :x) (self :x))
     (* (self :y) (self :y))))

(defn vlength
  "The length of the vector."
  [self]
  (math/sqrt (vlength2 self)))

(defn to-polar
  "Polar version of the vector"
  [self]
  (table/setproto @{:x (math/atan2 (self :x) (self :y))
                    :y (vlength self)}
                  (table/getproto self)))

(defn distance2
  "The squared distance of this vector to the other."
  [self v]
  (assert (vector? self) "a must be a vector.")
  (assert (vector? v) "v must be a vector.")
  (let [dx (- (self :x) (v :x))
        dy (- (self :y) (v :y))]
    (+ (* dx dx)
       (* dy dy))))

(defn distance
  "The distance between vectors A and B."
  [self v]
  (math/sqrt (:distance2 self v)))

(defn normalize
  "Normalize the vector in place."
  [self]
  (if-let [l (vlength self)
           greater-then-zero? (> l 0)]
    (:divide self l)
    self))

(defn rotate
  "Rotate the vector by angle phi in place."
  [self phi]
  (let [c (math/cos phi)
        s (math/sin phi)]
    (put self :x (- (* c (self :x))
                    (* s (self :y))))
    (put self :y (+ (* s (self :x))
                    (* c (self :y))))))

(defn perpendicular
  "Return a new vector perpendicular to this one."
  [self]
  (table/setproto @{:x (- (self :y)) :y (self :x)}
                  (table/getproto self)))


(defn preject-on
  "Return a new vector which is the projection of this one on vector V."
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
  "Return a new vector which is this one mirrored onto vector V."
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
  "The cross product of this vector with another."
  [self v]
  (assert (vector? v) "v must be a vector.")
  (- (* (self :x) (v :y))
     (* (self :y) (v :x))))

(defn trim
  "Truncate this vector length to max-length."
  [self max-length]
  (let [s (/ (* max-length max-length)
             (vlength2 self))]
    (put self :x (* (self :x) s))
    (put self :y (* (self :y) s))))

(defn angle-to
  "The angle of this vector to another."
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
    :length2 vlength2
    :length vlength
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

(defn new
  "Construct a new vector with given x,y coordinates."
  [&opt x y]
  (default x 0)
  (default y 0)
  (assert (number? x) "x must be a number")
  (assert (number? y) "y must be a number")
  (table/setproto @{:x x :y y} Vector))

(defn from-polar [angle &opt radius]
  "Construct a new vector from the polar coordinates."
  (default radius 1)
  (new (* (math/cos angle) radius)
       (* (math/sin angle) radius)))

(defn from-tuple
  "Construct a new vector from the tuple [x y], look at (:to-tuple vec)."
  [tup]
  (assert (= (length tup) 2) "length of tuple must be 2.")
  (new ;tup))

(defn from-named
  "Construct a new vector from the named args :x :y, useful when using def-component-alias."
  [&named x y]
  (new x y))

(defn random-direction
  "Construct a new vector of random length in random direction."
  [&opt len-min len-max seed]
  (default len-min 1)
  (default len-max len-min)
  (default seed nil)
  (assert (> len-max 0) "len-max must be greater than zero")
  (assert (>= len-max len-min) "len-max must be greater than or equal to len-min")
  (let [rng (math/rng seed) ]
    (from-polar (* (math/rng-uniform rng) 2 math/pi)
                (* (math/rng-uniform rng) (+ (- len-max len-min) len-min)))))
