(defn- debug-print [{:entity-indices entity-indices :entities entities :components components :n n}]
  "Pretty Prints contents of set."
  (print "entities-indices:")
  (pp entity-indices)

  (print "entities:")
  (for i 0 n
    (printf "%q -> %q" (entities i) (components i))))

(defn- search [self eid]
  "If element is present, returns index of element in :entities, Else returns -1."
  (if
    # the first condition verifies that 'x' is
    # within 'n' in this set and the second
    # condition tells us that it is present in
    # the data structure.
    (and (<= (get-in self [:entity-indices eid]) (self :n))
         (= (get-in self [:entities (get-in self [:entity-indices eid])]) eid))
    (get-in self [:entity-indices eid])

    # not found
    -1))

(defn- insert [self eid cmp-data]
  "Inserts a new element into set."
  (when-let [{:n n
              :capacity capacity
              :entities entities
              :entity-indices entity-indices
              :components components} self
             ents-not-full? (<= n capacity)
             eid-not-present? (= (search self eid) -1)]

    (put entity-indices eid n)
    (put entities n eid)
    (put components n cmp-data)

    (+= (self :n) 1)))

(defn- delete [self eid]
  "Deletes an element from set."

  (when-let [element-exists? (>= (search self eid) 0)

             {:n n
              :entities entities
              :entity-indices entity-indices
              :components components} self

             dense-i (entity-indices eid)]

    (put entities dense-i nil)
    (put entity-indices eid nil)
    (put components dense-i nil)

    (-= (self :n) 1)))

(defn- clear [self]
  "Removes all elements from set."
  (array/clear (self :entity-indices)))

(defn- get-component [self eid]
  "Get component data for entity id, nil if entity DnE."
  ((self :components) (get-in self [:entity-indices eid])))

(defn init [capacity]
  "Instantiate new sparse set."
  (table/setproto
   @{:capacity capacity
     :n 0

     # sparse list, the index (not the value) of this sparse array is itself
     # the entity id.
     :entity-indices (array)

     # dense list of integers, the index doesn't have inherent meaning, other
     # than it must be correct from entity-indices.
     :entities (array/new-filled capacity)

     # dense list of component type, it is aligned with entitylist such that
     # the element at entitylist[n] has component data of componentlist[n]
     :components (array/new-filled capacity)}
   @{:search search
     :insert insert
     :delete delete
     :clear clear
     :debug-print debug-print
     :get-component get-component}))
