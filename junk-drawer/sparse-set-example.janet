(use ./sparse-set)

# (var s1 (init 100 5))
# (:insert s1 5 {:cmp "data 1"})
# (:insert s1 3 {:cmp "data 2"})
# (:insert s1 9 {:cmp "data 3"})
# (:insert s1 10 {:cmp "data 4"})

# (printf "s1")
# (:debug-print s1)

# (if-let [index (search s1 3)
#          found (> index 0)]
#   (printf "\n 3 is found at index %q" index))

# (printf "\ndeleting 9 from s1")
# (:delete s1 9)

# (:debug-print s1)

# (print "\n")


# WIP ECS
# TODO ID counter
# TODO check type of component before inserting into pool
(def database
  {:position (init 100 100)
   :lives (init 100 100)

  })

(:insert (database :position) 0 {:x 1 :y 2})
(:insert (database :lives) 0 5)

(:insert (database :position) 1 {:x 3 :y 4})
(:insert (database :lives) 1 10)

(:insert (database :position) 2 {:x 10 :y 45})




(pp (view database [:position :lives]))


# (var s2 (init 1000 6))
# (insert s2 4 {:cmp "data 5"})
# (insert s2 3 {:cmp "data 6"})
# (insert s2 7 {:cmp "data 7"})
# (insert s2 200 {:cmp "data 8"})

# (printf "\ns2")
# (:print s2)

# (printf "\nIntersection of set1 and set2")
# (:print (intersection s1 s2))

# (printf "\nUnion of set1 and set2")
# (:print (union s1 s2))
