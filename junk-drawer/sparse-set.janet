# Based on --> https://www.geeksforgeeks.org/sparse-set/
# Super minimal sparse set implementation with int values
#
# More https://research.swtch.com/

(defn init [max-val capacity]
  @{:dense (array/new-filled capacity)
    :sparse (array/new-filled (+ max-val 1))
    :max-val max-val
    :capacity capacity
    :n 0})

(defn search [self x]
  "If element is present, returns index of element in :dense, Else returns -1."
  (cond
    # Searched element must be in range
    (> x (self :max-val)) -1

    # The first condition verifies that 'x' is
    # within 'n' in this set and the second
    # condition tells us that it is present in
    # the data structure.
    (and (< (get-in self [:sparse x]) (self :n))
         (= (get-in self [:dense (get-in self [:sparse x])]) x))
    (get-in self [:sparse x])

    # Not found
    -1))

(defn insert [self x]
  "Inserts a new element into set."
  # rule out Corner cases
  # - x must not be out of range
  # - dense[] should not be full
  # - x should not already be present
  (when (and (< x (self :max-value))
             (<= (self :n) (self :capacity))
             (= (search self x) -1))
    (put (self :dense) (self :n) x)
    (put (self :sparse) x (self :n))
    (+= (self :n) 1)))

(defn delete [self x]
  "Deletes an element."
  (when-let [element-exists (> (search self x) 0)
             {:n n :dense dense :sparse sparse} self
             temp (dense (- n 1))]
    (put dense (sparse x) temp)
    (put sparse temp (sparse x))
    (-= (self :n) 1)))

(defn clear [self]
  "Removes all elements from set."
  (put self :n 0))

(defn ss-print [{:dense dense :n n}]
  "pretty Prints contents of set."
  (prin "{ ")
  (for i 0 n (prinf "%q, " (dense i)))
  (prin " }\n"))

(defn intersection [s1 s2]
  "compute new set which is the intersection of this set with s"
  (let [i-cap (min (s1 :n) (s2 :n))
        i-max-val (max (s2 :max-val) (s1 :max-val))
        result (init i-cap i-max-val)]

    (if (< (s1 :n) (s2 :n))
      # Search every element of "s1" in 's2'.
      (for i 0 (s1 :n)
        (when (> (search s2 (get-in s1 [:dense i])) 0)
          (insert result (get-in s1 [:dense i]))))
      # Search every element of "s2" in 's1'.
      (for i 0 (s2 :n)
        (when (> (search s1 (get-in s2 [:dense i])) 0)
          (insert result (get-in s2 [:dense i])))))

    result))

(defn union [s1 s2]
  "A function to find union of two sets, Time Complexity O(n1+n2)"
  (let [u-cap (+ (s1 :n) (s2 :n))
        u-max-val (max (s2 :max-val) (s1 :max-val))
        result (init u-cap u-max-val)]

    (for i 0 (s1 :n)
      (insert result (get-in s1 [:dense i])))

    (for i 0 (s2 :n)
      (insert result (get-in s2 [:dense i])))

    result))

# Example
(var s1 (init 100 5))
(insert s1 5)
(insert s1 3)
(insert s1 9)
(insert s1 10)

(printf "s1")
(ss-print s1)

(if-let [index (search s1 3)
         found (> index 0)]
  (printf "3 is founda t index %q" index))

(printf "deleting 9 from s1")
(delete s1 9)
(ss-print s1)

(var s2 (init 1000 6))
(insert s2 4)
(insert s2 3)
(insert s2 7)
(insert s2 200)

(printf "\ns2")
(ss-print s2)

(printf "\nIntersection of set1 and set2")
(ss-print (intersection s1 s2))

(printf "\nUnion of set1 and set2")
(ss-print (union s1 s2))
