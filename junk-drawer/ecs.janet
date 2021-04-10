(defmacro def-component [name fields]
  "Define a new component with the specified fields."
  ~(defn ,name ,fields
     ,(zipcoll
        (map |(keyword $) fields)
        fields)))

(defmacro def-tag [name]
  "Define a new tag (component with no data)."
  ~(defn ,name [] true))

(defmacro def-system [name queries & body]
  "Define a system to do work on a list of queries."
  ~(def ,name
     (tuple
       ,(values queries)
       (fn [,;(keys queries) dt] ,;body))))

(defmacro add-entity [world & components]
  "Add a new entity with the given components to the world."
  (with-syms [$id $db]
    ~(let [,$id (get world :id-counter)
           ,$db (get world :database)]
       (put-in ,$db [:entity ,$id] ,$id)
       ,;(map
           |(quasiquote (put-in ,$db [,(keyword (first $)) ,$id] ,$))
           components)
       (put world :id-counter (inc ,$id)))))

(defn remove-entity [world ent]
  "remove an entity ID from the world."
  (eachp [name components] (world :database)
    (put components ent nil)))

(defmacro add-component [world ent component]
  ~(do
     (assert (get-in ,world [:database :entity ,ent]) "entity does not exist in world")
     (put-in ,world [:database ,(keyword (first component)) ,ent] ,component)))

(defn remove-component [world ent component-name]
  (assert (get-in world [:database :entity ent]) "entity does not exist in world")
  (put-in world [:database component-name ent] nil))

(defn register-system [world sys]
  "register a system for the query in the world."
  (array/push (get world :systems) sys))

(defn- query-database [db query]
  (mapcat
    (fn [key]
      (let [result (map |(get-in db [$ key]) query)]
        (if (every? result) [result] [])))
    (keys (get db :entity))))

(defn- query-result [world query]
  "either return a special query, or the results of the ecs query"
  (match query
    :world world
    [_] (query-database (world :database) query)))

(defn- update [self dt]
  "call all registers systems for entities matching thier queries."
  (loop [(queries func)
         :in (self :systems)
         :let [queries-results (map |(query-result self $) queries)]]
    (func ;queries-results dt)))

(defn create-world []
  @{:id-counter 0
    :database @{}
    :systems @[]
    :update update})
