(defmacro def-component [name fields]
  "Define a new component with the specified fields."
  ~(def ,name
     (fn ,name ,fields
       (zipcoll
        ,(map |(keyword $) fields)
        ,fields))))

(defmacro add-entity [world & components]
  "Add a new entity with the given components to the world."
  ~(array/push
    (get world :entities)
    (zipcoll
     ,(map |(keyword (first $)) components)
     ,(map |(eval $) components))))

(defn register-system [world query func]
  "register a system for the query in the world."
  (array/push (get world :systems) [query func]))

(defn- update [self dt]
  "call all registers systems for entities matching thier queries."
  (each entity (self :entities)
    (each (query func) (self :systems)
      (when (all |(get entity $) query)
        (func ;(map |(get match $) query) dt)))))

# (each match (filter (fn [e] (all |(get e $) query)) (self :entities)))
(defn create-world []
  @{:entities @[]
    :systems @[]
    :update update})
