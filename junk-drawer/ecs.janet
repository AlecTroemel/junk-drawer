(import /junk-drawer/sparse-set)
(import /junk-drawer/cache)

(setdyn :doc ```
ECS (short for Entity Component System) is a game dev pattern where you

1. Define components with (def-component) that hold data of a specific aspect.
2. Define systems with (def-system) which process entities with matching components
3. Create a world which will hold your entities and have registered systems.
4. Create entities comprised of many components in your world.

ECS encourage code reuse by breaking down problems into their individual and isolated parts!
This implimentation uses a (relatively naive) sparse set data structure.
```)

(defmacro def-component
  ```
  Define a new component fn of the specified fields, where fields follow the
  ":name :datatype" pattern. Names must be keywords, and the datatype can be
  any datatype the (type) fn returns. The component function will then verify
  that the types of the fields are correct when ran.

  (def-component pizza :hotdog :number :frenchfry :string)
  (pizza :hotdog 1)        # throws error missing "frenchfry" field
  (pizza :hotdog "string") # throws error datatype missmatch
  (pizza :hotdog 1 :frenchfry "milkshake") # evaluates to...
  {:hotdog 1 :frenchfry "milkshake}

  dont need anydata? check out (def-tag)
  ```
  [name & fields]

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

(defmacro def-tag
  ```
  Define a new tag, a component that holds no data.

  (def-tag monster)
  (add-entity world (monster))
  ```
  [name]
  ~(defn ,name [] true))

(defmacro def-system
  ```
  Define a system fn that operates over queries. Queries are lists
  of component names, an are assigned to a variable. Note that "dt"
  is implicitly available in all systems context.

  (def-system move-sys
    {moveables [:position :velocity]}
    (each [pos vel] moveables
      (put pos :x (+ (pos :x) (* dt (vel :x))))
      (put pos :y (+ (pos :y) (* dt (vel :y))))))

  Additionaly, if you need the parent world invoking the system, there's
  a special query for that. This is useful when creating or deleting
  Entites within a system.

  (def-system give-me-the-world
    {wld :world}
    (pp wld))
  ```
  [name queries & body]

  ~(def ,name
     (tuple
       ,(values queries)
       (fn [,;(keys queries) dt] ,;body))))

(defmacro add-component
  ```
  Add a new component to an existing entity. Note this has
  some performance implications, as it will invalidate the
  query cache for all related systems.

  (add-component ENTITY_ID_HERE (position :x 1 :y 2))
  ```
  [world eid component]

  (with-syms [$wld $cmp-name]
    ~(let [,$wld ,world
           ,$cmp-name ,(keyword (first component))]
       (when (nil? (get-in ,$wld [:database ,$cmp-name]))
         (put-in ,$wld
                  [:database ,$cmp-name]
                  (,sparse-set/init (,$wld :capacity))))
       (:insert (get-in ,$wld [:database ,$cmp-name])
                ,eid ,component)
       (:clear (get ,$wld :view-cache) ,$cmp-name))))

(defn remove-component
  ```
  Remove a component by its name from an entity. Note this has
  some performance implications, as it will invalidate the
  query cache for all related systems.

  (remove-component ENTITY_ID_HERE :position)
  ```
  [world ent component-name]

  (let [pool (get-in world [:database component-name])]
    (assert (not (nil? pool)) "component does not exist in world")
    (assert (not= -1 (:search pool ent)) "entity with component does not exist in world")
    (:delete pool ent)
    (:clear (get world :view-cache) component-name)))

(defmacro add-entity
  ```
  Add a new entity with the given components to the world. Note that this macro
  uses the name of the component fn being called as the component ID. So be sure
  to call it within this macro.

  Note this has some performance implications, as it will invalidate the query cache
  for all systems using any of the provided components.

  (add-entity world
            (position :x 0 :y 0)
            (velocity :x 1 :y 1)
            (monster))
  ```
  [world & components]

  (with-syms [$wld $db $eid]
    ~(let [,$wld ,world
           ,$db (get ,$wld :database)
           ,$eid (if (empty? (get ,$wld :reusable-ids))
                   (get ,$wld :id-counter)
                   (array/pop (,$wld :reusable-ids)))]
       ,;(map |(quasiquote (add-component ,$wld ,$eid ,$)) components)
       (put ,$wld :id-counter (inc ,$eid))
       ,$eid)))

(defn remove-entity
  ```
  Remove an entity from the world by its ID.

  Note this has some performance implications, as it will invalidate the query cache
  for all systems using any of the components on the entity.

  (remove-entity world ENTITY_ID)
  ```
  [world ent]

  (eachp [name pool] (world :database)
         (:delete pool ent)
         (:clear (get world :view-cache) name))
  (array/push (world :reusable-ids) ent))

(defn register-system
  ```
  Register a system to be run on world update.

  (register-system world move-sys)
  ```
  [world sys]
  (array/push (get world :systems) sys))

(defn- smallest-pool [pools]
  "Length (n) of smallest pool."
  (reduce2 |(if (< (get-in $0 [1 :n])
                   (get-in $1 [1 :n]))
              $0 $1)
           pools))

(defn- every-has? [pools eid]
  "True if every pool has the entity id, false otherwise."
  (every? (map |(not= -1 (:search $ eid)) pools)))

(defn- intersection-entities [pools]
  "List of entities which all pools contain."
  (let [small-pool (smallest-pool pools)]
    (mapcat
     |(let [eid (get-in small-pool [:entities $])]
        (if (every-has? pools eid) [eid] []))
     (range 0 (small-pool :n)))))

(defn- view-entry [pools eid]
  "Tuple of all component data for eid from pools (eid cmp-data cmp-data-2 ...)."
  (tuple ;(map |(:get-component $ eid) pools)))

(defn- view [{:database database :view-cache view-cache :capacity capacity} query]
  "Result of query as list of tuples [(eid cmp-data cmp-data-2 ...)]."
  (if-let [cached-view (:get view-cache query)]
    cached-view
    (if-let [pools (map |(match $
                           :entity {:get-component (fn [self eid] eid)
                                    :search (fn [self eid] 0)
                                    :n (+ 1 capacity)
                                    :debug-print (fn [self] (print "entity patch"))}
                           (database $)) query)
             all-empty? (empty? (filter nil? pools))
             view-result (map |(view-entry pools $) (intersection-entities pools))]
      (:insert view-cache query view-result)
      (:insert view-cache query []))))

(defn- query-result [world query]
  "Either return a special query, or the results of ECS query."
  (match query
    :world world
    [_] (view world query)))

(defn- update [self dt]
  "Call all registers systems for entities matching thier queries."
  (loop [(queries func)
         :in (self :systems)
         :let [queries-results (map |(query-result self $) queries)]]

    (when (some |(not (empty? $)) queries-results)
      (func ;queries-results dt))))

(defn create-world
  ```
  Instantiate a new world. Worlds contain entities and systems that
  operate on them.

  (var world (create-world))

  Call the :update method on the world and be sure to pass in dt, the time
  between last call to update

  (:update world dt)
  ```
  [&named capacity]

  (default capacity 1000)
  @{:capacity capacity
    :id-counter 0
    :reusable-ids @[]
    :database @{}
    :view-cache (cache/init)
    :systems @[]
    :update update
    :view view})
