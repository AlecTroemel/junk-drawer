(def MAX_ENTITY_COUNT 1000)

(defn sparse-set-debug-print [{:entity-indices entity-indices :entities entities :components components :n n}]
  "pretty Prints contents of set."
  (print "entities:")
  (for i 0 n
    (printf "%q -> %q" (entities i) (components i))))

(defn sparse-set-search [self eid]
  "If element is present, returns index of element in :entities, Else returns -1."
  (cond
    # Searched element must be in range
    (> eid (self :max-eid))
    -1

    # the first condition verifies that 'x' is
    # within 'n' in this set and the second
    # condition tells us that it is present in
    # the data structure.
    (and (<= (get-in self [:entity-indices eid]) (self :n))
         (= (get-in self [:entities (get-in self [:entity-indices eid])]) eid))
    (get-in self [:entity-indices eid])

    # not found
    -1))

(defn sparse-set-insert [self eid cmp-data]
  "inserts a new element into set."
  (when-let [{:n n
              :max-eid max-eid
              :capacity capacity
              :entities entities
              :entity-indices entity-indices
              :components components} self

             eid-in-range? (< eid max-eid)
             ents-not-full? (<= n capacity)
             eid-not-present? (= (sparse-set-search self eid) -1)]

    (put entity-indices eid n)
    (put entities n eid)
    (put components n cmp-data)

    (+= (self :n) 1)))

(defn sparse-set-delete [self eid]
  "deletes an element."
  (when-let [element-exists? (> (sparse-set-search self eid) 0)

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

(defn sparse-set-clear [self]
  "removes all elements from set."
  (put self :n 0))

(defn sparse-set-get-component [self eid]
  ((self :components) (get-in self [:entity-indices eid])))

(defn sparse-set-init [max-eid capacity]
  @{:max-eid max-eid
    :capacity capacity
    :n 0

    # sparse list, the index (not the value) of this sparse array is itself
    # the entity id.
    :entity-indices (array/new-filled (+ max-eid 1))

    # dense list of integers, the index doesn't have inherent meaning, other
    # than it must be correct from entity-indices.
    :entities (array/new-filled capacity)

    # dense list of component type, it is aligned with entitylist such that the
    # element at entitylist[n] has component data of componentlist[n]
    :components (array/new-filled capacity)

    :search sparse-set-search
    :insert sparse-set-insert
    :delete sparse-set-delete
    :clear sparse-set-clear
    :debug-print sparse-set-debug-print
    :get-component sparse-set-get-component})


(defmacro def-component [name & fields]
  "define a new component with the specified fields."
  (if (= 1 (length fields))
    ~(defn ,name [value]
       (assert
        (= (type value) ,(first fields))
        (string/format "%q must be of type %q" value ,(first fields)))
       value)
    (let [type-table (table ;fields)
          def-array (mapcat |[$ (symbol $)] (keys type-table))]
      ~(defn ,name [&keys ,(struct ;def-array)]
         # assert types of the component fields
         ,;(map
            (fn [[key field-type]]
              ~(assert
                (= (type ,(symbol key)) ,field-type)
                ,(string/format "%q must be of type %q" key field-type)))
            (filter
             |(not= (last $) :any)
             (pairs type-table)))

         # return the component
         ,(table ;def-array)))))

(defmacro def-tag [name]
  "define a new tag (component with no data)."
  ~(defn ,name [] true))

(defmacro def-system [name queries & body]
  "define a system to do work on a list of queries."
  ~(def ,name
     (tuple
       ,(values queries)
       (fn [,;(keys queries) dt] ,;body))))

(defmacro add-component [world eid component]
  (with-syms [$wld $cmp-name]
    ~(let [,$wld ,world
           ,$cmp-name ,(keyword (first component))]
       (when (nil? (get-in ,$wld [:database ,$cmp-name]))
         (put-in ,$wld
                  [:database ,$cmp-name]
                  (sparse-set-init MAX_ENTITY_COUNT MAX_ENTITY_COUNT)))
       (:insert (get-in ,$wld [:database ,$cmp-name])
                ,eid ,component))))

(defn remove-component [world ent component-name]
  (let [pool (get-in world [:database component-name])]
    (assert (not (nil? pool)) "component does not exist in world")
    (assert (not= -1 (:search pool ent)) "entity with component does not exist in world")
    (:delete pool ent)))

(defmacro add-entity [world & components]
  "add a new entity with the given components to the world."
  (with-syms [$wld $db $eid]
    ~(let [,$wld ,world
           ,$db (get ,$wld :database)
           ,$eid (get ,$wld :id-counter)]
       ,;(map |(quasiquote (add-component ,$wld ,$eid ,$)) components)
          (put ,$wld :id-counter (inc ,$eid))
          ,$eid)))

(defn remove-entity [world ent]
  "remove an entity id from the world."
  (eachp [name pool] (world :database)
         (:delete pool ent)))

(defn register-system [world sys]
  "register a system for the query in the world."
  (array/push (get world :systems) sys))

(defn smallest-pool-length [pools]
  "returns length (n) of smallest pool"
  (get (reduce2 |(if (< (get-in $0 [1 :n])
                        (get-in $1 [1 :n]))
                   $0 $1)
                pools)
       :n))

(defn every-has? [pools eid]
  "true if every pool has eid"
  (every? (map |(not= (:search $ eid) -1)
               pools)))

(defn intersection-entities [pools]
  "return list of entities which all pools contain."
  (mapcat |(if (every-has? pools $) [$] [])
          (range 0 (+ 1 (smallest-pool-length pools)))))

(defn view-entry [pools eid]
  "return tuple of all component data for eid from pools (eid cmp-data cmp-data-2 ...)"
  (tuple ;(map |(:get-component $ eid) pools)))

(defn view [database query]
  "return result of query as list of tuples [(eid cmp-data cmp-data-2 ...)] "
  (let [pools (map |(match $
                      :entity {:get-component (fn [self eid] eid)
                               :search (fn [self eid] true)
                               :n (+ 1 MAX_ENTITY_COUNT)}
                      (database $)) query)]

    # If any part of the query is not a registered component, view must be empty
    (if (empty? (filter nil? pools))
      (map |(view-entry pools $) (intersection-entities pools))
      [])))

(defn- query-result [world query]
  "either return a special query, or the results of the ecs query"
  (match query
    :world world
    [_] (view (world :database) query)))

(defn- update [self dt]
  "call all registers systems for entities matching thier queries."
  (loop [(queries func)
         :in (self :systems)
         :let [queries-results (map |(query-result self $) queries)]]

    (when (some |(not (empty? $)) queries-results)
      (func ;queries-results dt))))

(defn create-world []
  @{:id-counter 0
    :database @{}
    :systems @[]
    :update update})
