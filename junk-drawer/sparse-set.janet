# Super minimal sparse set implementation with int values
#
# links
# https://www.geeksforgeeks.org/sparse-set/
# https://research.swtch.com/
# https://gist.github.com/dakom/82551fff5d2b843cbe1601bbaff2acbf


(defn debug-print [{:entity-indices entity-indices :entities entities :components components :n n}]
  "pretty Prints contents of set."
  (print "entities:")
  (for i 0 n
    (printf "%q -> %q" (entities i) (components i))))

(defn search [self eid]
  "If element is present, returns index of element in :entities, Else returns -1."
  (cond
    # Searched element must be in range
    (> eid (self :max-val)) -1

    # The first condition verifies that 'x' is
    # within 'n' in this set and the second
    # condition tells us that it is present in
    # the data structure.
    (and (< (get-in self [:entity-indices eid]) (self :n))
         (= (get-in self [:entities (get-in self [:entity-indices eid])]) eid))
    (get-in self [:entity-indices eid])

    # Not found
    -1))

(defn insert [self eid cmp-data]
  "Inserts a new element into set."
  (when-let [{:n n
              :max-val max-val
              :capacity capacity
              :entities entities
              :entity-indices entity-indices
              :components components} self

             eid-in-range? (< eid max-val)
             ents-not-full? (<= n capacity)
             eid-not-present? (= (search self eid) -1)]

    (put entity-indices eid n)
    (put entities n eid)
    (put components n cmp-data)

    (+= (self :n) 1)))

(defn delete [self eid]
  "Deletes an element."
  (when-let [element-exists? (> (search self eid) 0)

             {:n n
              :entities entities
              :entity-indices entity-indices
              :components components} self

             temp-ent (entities (- n 1))
             temp-cmp (components (- n 1))
             dense-i (entity-indices eid)]

    (put entities dense-i temp-ent)
    (put components dense-i temp-cmp)
    (put entity-indices temp-ent dense-i)

    (-= (self :n) 1)))

(defn clear [self]
  "Removes all elements from set."
  (put self :n 0))

(defn init [max-val capacity]
  (table/setproto
   @{:max-val max-val
     :capacity capacity
     :n 0

     # Sparse list, The index (not the value) of this sparse array is itself
     # the entity id.
     :entity-indices (array/new-filled (+ max-val 1))

     # Dense list of integers, The index doesn't have inherent meaning, other
     # than it must be correct from entity-indices.
     :entities (array/new-filled capacity)

     # Dense list of component type, It is aligned with EntityList such that the
     # element at EntityList[N] has component data of ComponentList[N]
     :components (array/new-filled capacity)}
   @{:search search
     :insert insert
     :delete delete
     :clear clear
     :debug-print debug-print}))

(defn smallest-pool-length [pools]
  "returns length (n) of smallest pool"
  (get (reduce2 |(if (< (get-in $0 [1 :n])
                        (get-in $1 [1 :n]))
                   $0 $1)
                pools)
       :n))

(defn every-has? [pools eid]
  "True if every pool has eid"
  (every? (map |(not= (:search $ eid) -1)
               pools)))

(defn intersection-entities [pools]
  "return list of entities which all pools contain."
  (mapcat |(if (every-has? pools $) [$] [])
          (range 0 (smallest-pool-length pools))))

(defn view-entry [pools eid]
  "return tuple of all component data for eid from pools (eid cmp-data cmp-data-2 ...)"
  (tuple eid ;(map |(get-in $ [:components eid]) pools)))

(defn view [database query]
  "return result of query as list of tuples [(eid cmp-data cmp-data-2 ...)] "
  # check that each component in query actually exists in DB
  (each q query
    (when (nil? (database q))
      (errorf "%q not a component in the databse" q)))

  # query DB pools
  (let [pools (map |(database $) query)
        entities (intersection-entities pools)]
    (map |(view-entry pools $) entities)))
