(import ./sparse-set :as ss)

(defmacro def-component [name & fields]
  "Define a new component with the specified fields."
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
  "Define a new tag (component with no data)."
  ~(defn ,name [] true))

(defmacro def-system [name queries & body]
  "Define a system to do work on a list of queries."
  ~(def ,name
     (tuple
       ,(values queries)
       (fn [,;(keys queries) dt] ,;body))))

(defmacro add-component [world ent component]
  (with-syms [$wld $db $comp-id]
    ~(let [,$wld ,world
           ,$db (get ,$wld :database)
           ,$comp-id ,(keyword (first component))]
       (when (nil? (,$db ,$comp-id))
         (put ,$db ,$comp-id ,(ss/init 1000 1000)))

       (:insert (,$db ,$comp-id) ,ent ,component))))

(defn remove-component [world ent component-name]
  (let [pool (get-in world [:database component-name])]
    (assert (not (nil? pool)) "component does not exist in world")
    (assert (not= -1 (:search pool ent)) "entity with component does not exist in world")
    (:delete pool ent)))

(defmacro add-entity [world & components]
  "Add a new entity with the given components to the world."
  (with-syms [$id $db $wld]
    ~(let [,$wld ,world
           ,$id (get ,$wld :id-counter)
           ,$db (get ,$wld :database)]

       ,;(map |(quasiquote (add-component ,$wld ,$id ,$)) components)

       (put ,$wld :id-counter (inc ,$id))

       ,$id)))

(defn remove-entity [world ent]
  "remove an entity ID from the world."
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
  "True if every pool has eid"
  (every? (map |(not= (:search $ eid) -1)
               pools)))

(defn intersection-entities [pools]
  "return list of entities which all pools contain."
  (mapcat |(if (every-has? pools $) [$] [])
          (range 0 (smallest-pool-length pools))))

(defn view-entry [pools eid]
  "return tuple of all component data for eid from pools (eid cmp-data cmp-data-2 ...)"
  (tuple ;(map |(($ :components) eid) pools)))

(defn view [database query]
  "return result of query as list of tuples [(eid cmp-data cmp-data-2 ...)] "
  (let [pools (map |(match $
                      :entity {:components identity
                               :search (fn [self eid] true)
                               :n math/inf}
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
