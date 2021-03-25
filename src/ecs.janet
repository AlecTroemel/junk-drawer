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

# TODO: look into flipping the iterations (iterate through each entity first, then filter systems)
(defn- update [self dt]
  "call all registers systems for entities matching thier queries."
  (each (query func) (get self :systems)
    (each match (filter (fn [e] (all |(get e $) query)) (self :entities))
      (func ;(map |(get match $) query) dt))))

(defn create-world []
  @{:entities @[]
    :systems @[]
    :update update})
