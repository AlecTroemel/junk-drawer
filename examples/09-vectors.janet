# Vectors are pretty straighforward, just create em and use their methods
# check out the implimentation for all the functions available.
(use /junk-drawer)

(def vec (vector/new 1 2))
(def vec2 (vector/from-tuple [5 5]))
(printf "vector 1: %q" vec)
(printf "vector 2: %q" vec2)

(printf "distance between them : %n" (:distance vec vec2))

# One useful thing you can do with the vectors module is use them as ECS components
(def-component-alias position vector/from-named)

(printf "position component alias: %q" (position :x 2 :y 3))
(printf "it has the vector proto table: %q" (table/getproto (position :x 2 :y 3)))
