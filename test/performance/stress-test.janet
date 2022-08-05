# run with 'time janet stress-test.janet'
(use profiling/profile)

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
    (map |['def-system (symbol "sys-" $)
           ~{first [,(keyword (ALPHABET $)) ,(keyword (ALPHABET (% (inc $) 25)))]
             second [,(keyword (ALPHABET (% (+ 2 $) 25))) ,(keyword (ALPHABET (% (+ 3 $) 25)))]}
           nil]
         (range 0 25))

    # Register it
    (map |['register-system 'world (symbol "sys-" $)]
         (range 0 25))))

(defmacro create-entities-alphabet []
  "Define a entity for every letter and letter+1 components."
  (map |['add-entity 'world
         [(symbol (ALPHABET $)) :val $]
         [(symbol (ALPHABET (% (inc $) 25))) :val $]]
       (range 0 25)))

(defmacro def-create-entities []
  "Create A LOT of entities by calling create-entities-alphabet lots of times"
  ~(defnp create-entities []
     ,;(array/new-filled 100 ['create-entities-alphabet])))

(print "lets create all the things")
(def world (create-world))

(def-component-alphabet)
(def-systems-alphabet)

(def-create-entities)
(create-entities)


(def rng (math/rng))

(defnp remove-random-entity []
  (remove-entity world (math/rng-int rng 2559)))

(defnp create-random-entity []
  (add-entity world
              (a :val 1)
              (b :val 1)))

(defnp update-world []
  (:update world 1))

(print "everything created, lets run update")
(for i 0 1000
  (when (= 0 (% i 100))
    (printf "i=%q" i))

  (update-world)

  (when (= 0 (% i 10))
    (remove-random-entity))

  (when (= 0 (% i 20))
    (create-random-entity)))


(print "everything done")

(print-results)
