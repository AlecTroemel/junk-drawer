(use spork/schema)

(import /junk-drawer/sparse-set)
(import /junk-drawer/cache)

(setdyn :doc ```
ECS (short for Entity Component System) is a game dev pattern where you

1. Define components with (def-component) that hold data of a specific aspect. Components are
   just objects that have the :__id__ field on them (which names the component in the world).
2. Define systems with (def-system) which process entities with matching components
3. Create a world which will hold your entities and have registered systems.
4. Create entities comprised of many components in your world.

ECS encourage code reuse by breaking down problems into their individual and isolated parts!
This implimentation uses a (relatively naive) sparse set data structure.
```)

(defmacro def-component
  ```
  Define a new component fn of the specified fields, where fields follow the
  ":name spork/schema" pattern. Names must be keywords, and the datatype can be
  valid spork/schema. The component function will then verify that the types of
  the fields are correct when ran.

  (def-component pizza :hotdog :number :frenchfry :string)
  (pizza :hotdog 1)        # throws error missing "frenchfry" field
  (pizza :hotdog "string") # throws error datatype missmatch
  (pizza :hotdog 1 :frenchfry "milkshake") # evaluates to...
  {:hotdog 1 :frenchfry "milkshake}

  dont need anydata? check out (def-tag)
  ```
  [name & fields]
  ~(defn ,name [&named ,;(map symbol (keys (table ;fields)))]
     (-> (table/setproto ,(table ;(mapcat |[$ (symbol $)] (keys (table ;fields))))
                          @{:__id__ ,(keyword name)
                            :__validate__ ,((make-validator ~(props ,;fields)))})
         (:__validate__))))

(defmacro def-tag
  ```
  Define a new tag, a component that holds no data.

  (def-tag monster)
  (add-entity world (monster))
  ```
  [name]
  ~(defn ,name []
     (table/setproto @{}
                     @{:__id__ ,(keyword name)
                       :__validate__ (fn [& args] false)})))

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

(defn- get-or-create-component-set
  "return the sparse set for the component, creating if it it does not already exist."
  [{:database db :capacity cap} cmp-name]
  (match (get db cmp-name)
    nil (let [new-set (sparse-set/init cap)]
          (put db cmp-name new-set)
          new-set)
    cmp-set cmp-set))

(defn add-component
  ```
  Add a new component to an existing entity. Note this has
  some performance implications, as it will invalidate the
  query cache for all related systems.

  (add-component ENTITY_ID_HERE (position :x 1 :y 2))
  ```
  [world eid component]
  (let [cmp-name (component :__id__)
        cmp-set (get-or-create-component-set world cmp-name)]
    (:insert cmp-set eid component)
    (:clear (world :view-cache) cmp-name)))

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

(defn add-entity
  ```
  Add a new entity with the given components to the world.
  Note this has some performance implications, as it will invalidate the query cache
  for all systems using any of the provided components.

  (add-entity world
            (position :x 0 :y 0)
            (velocity :x 1 :y 1)
            (monster))
  ```
  [world & components]

  # Use a free ID (from deleted entity) if available
  (let [eid (or (array/pop (world :reusable-ids))
                (get world :id-counter))]

    # Add individual component data to database
    (each component components
      (add-component world eid component))

    # increment the id counter when there are no more
    # free id's to use
    (when (empty? (world :reusable-ids))
      (put world :id-counter (inc (world :id-counter))))))

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
