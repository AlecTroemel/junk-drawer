# run with 'time janet stress-test.janet'
# NOTE: the macros here and incredibly unhygenic with probably a lot of accidental binding bapture!

(use /junk-drawer)

(def ALPHABET ["a" "b" "c" "d" "e" "f" "g" "h" "i"
               "j" "k" "l" "m" "n" "o" "p" "q" "r"
               "s" "t" "u" "v" "w" "x" "y" "z"])

(defmacro def-component-alphabet []
  "Define a component for every letter of the alphabet."
  (map |['def-component (symbol $) :val :number]
       ALPHABET))

(defmacro def-systems-alphabet []
  "Define and register a system with 2 queries, each with 2 alphabet components."
  (array/concat
    # define system
    (map (fn [i]
           ['def-system (symbol "sys-" i)
            ~{first [,(keyword (ALPHABET i)) ,(keyword (ALPHABET (% (+ 1 i) 25)))]
              second [,(keyword (ALPHABET (% (+ 2 i) 25))) ,(keyword (ALPHABET (% (+ 3 i) 25)))]}
            nil])
         (range 0 25))

    # Register it
    (map (fn [i] ['register-system 'world (symbol "sys-" i)])
         (range 0 25))))

(defmacro create-entities-alphabet []
  "Define a entity for every letter and letter+1 components."
  (map (fn [i]
         ['add-entity 'world
          [(symbol (ALPHABET i)) :val i]
          [(symbol (ALPHABET (% (+ 1 i) 25))) :val i]])
       (range 0 25)))

(defmacro create-a-lot-of-entites []
  "Create A LOT of entities by calling create-entities-alphabet lots of times"
  (map (fn [i] ['create-entities-alphabet]) # each one of these creates 26 entities
       (range 0 100))) # so lets call it 100 times for 2600 entites

(print "lets create all the things")
(def world (create-world))

(def-component-alphabet)
(def-systems-alphabet)
(create-a-lot-of-entites)

(def rng (math/rng))

(defn remove-random-entity []
  (remove-entity world (math/rng-int rng 2559)))

(defn create-random-entity []
  (add-entity world
              (a :val 1)
              (b :val 1)))

(print "everything created, lets run update")
(for i 0 1000
  (when (= 0 (% i 100))
    (printf "i=%q" i))

  (:update world 1)

  # TODO Removing and Adding seems to be a bottleneck
  (when (= 0 (% i 10))
    (remove-random-entity))

  (when (= 0 (% i 20))
    (create-random-entity)))

(print "everything done")
