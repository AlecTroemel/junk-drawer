(defmacro def-component [name fields]
  "Define a new component with the specified fields."
  ~(def ,name
     (fn ,name ,fields
       (zipcoll
        ,(map |(keyword $) fields)
        ,fields))))

(defmacro add-entity [world & components]
  "Add a new entity with the given components to the world."
  (with-syms [$id $db]
    ~(let [,$id (get world :id-counter)
           ,$db (get world :database)]
       (put-in ,$db [:entity ,$id] true)
       ,;(map
          |(quasiquote (put-in ,$db [,(keyword (first $)) ,$id] ,$))
          components)
       (put world :id-counter (inc ,$id)))))

(defn register-system [world query func]
  "register a system for the query in the world."
  (array/push (get world :systems) [query func]))

(defn- query-database [db query]
  (mapcat
   (fn [key]
     (let [result (map |(get-in db [$ key]) query)]
       (if (every? result) [result] [])))
   (keys (get db :entity))))

(defn- update [self dt]
  "call all registers systems for entities matching thier queries."
  (each (query func) (self :systems)
    (func (query-database (self :database) query) dt)))

(defn create-world []
  @{:id-counter 0
    :database @{}
    :systems @[]
    :update update})
