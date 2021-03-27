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
       # add entity id in db
       (put-in ,$db [:entities ,$id] true)

       # Add entity components in db
       ,;(map
          |(quasiquote (put-in ,$db [,(keyword (first $)) ,$id] ,$))
          components)

       # Increment the id counter
       (put world :id-counter (inc ,$id)))))


(defn register-system [world query func]
  "register a system for the query in the world."
  (array/push (get world :systems) [query func]))

(defn create-world []
  @{:id-counter 0
    :database @{}
    :systems @[]
    :update update})


(defn- update [self dt]
  "call all registers systems for entities matching thier queries."
  (each entity (self :entities)
    (each (query func) (self :systems)
      (when (all |(get entity $) query)
        (func ;(map |(get entity $) query) dt)))))
