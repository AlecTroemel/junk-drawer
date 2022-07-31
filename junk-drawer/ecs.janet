(import /junk-drawer/sparse-set :as sparse-set)
(import /junk-drawer/cache :as cache)

(def MAX_ENTITY_COUNT 1000)

(defmacro def-component [name & fields]
  "define a new component with the specified fields."
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
       ,(table ;def-array))))

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
                  (sparse-set/init MAX_ENTITY_COUNT MAX_ENTITY_COUNT)

                  ))
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

(defn smallest-pool [pools]
  "returns length (n) of smallest pool"
  (reduce2 |(if (< (get-in $0 [1 :n])
                   (get-in $1 [1 :n]))
              $0 $1)
           pools))

(defn every-has? [pools eid]
  (every? (map |(not= -1 (:search $ eid)) pools)))

(defn intersection-entities [pools]
  "return list of entities which all pools contain."
  (let [small-pool (smallest-pool pools)]
    (mapcat
     |(let [eid (get-in small-pool [:entities $])]
        (if (every-has? pools eid) [eid] []))
     (range 0 (small-pool :n)))))

(defn view-entry [pools eid]
  "return tuple of all component data for eid from pools (eid cmp-data cmp-data-2 ...)"
  (tuple ;(map |(:get-component $ eid) pools)))

(defn view [database view-cache query]
  "return result of query as list of tuples [(eid cmp-data cmp-data-2 ...)] "

  (if-let [cached-view (:get view-cache query)]
    cached-view
    (if-let [pools (map |(match $
                           :entity {:get-component (fn [self eid] eid)
                                    :search (fn [self eid] 0)
                                    :n (+ 1 MAX_ENTITY_COUNT)
                                    :debug-print (fn [self] (print "entity patch"))}
                           (database $)) query)
             all-empty? (empty? (filter nil? pools))
             view-result (map |(view-entry pools $) (intersection-entities pools))]
      (:insert view-cache query view-result)
      (:insert view-cache query []))))

(defn- query-result [world query]
  "either return a special query, or the results of the ecs query"
  (match query
    :world world
    [_] (view (world :database)
              (world :view-cache)
              query)))

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
    :view-cache (cache/init)
    :systems @[]
    :update update})
