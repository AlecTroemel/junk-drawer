# https://medium.com/tebs-lab/implementations-of-graphs-92eb7f121793

(defn- add-node
  """
  Create a new node and add it to the graph. Name must be a hashable type.
  """
  [self name &opt data]
  (default data {})
  (if (:contains self name)
    false
    (do (put-in self [:adjacency-table name] (merge data {:edges @{}}))
        true)))

(defn- add-edge
  """
  Create an edge between a and b with an optional weight and edge name.

  If either of the node-names is not already a member of the graph, throw error.

  if edge already exists, do not overwrite it and throw error
  """
  [self node-a node-b &opt weight edge-name]
  (default weight 1)
  (default edge-name (string/format "%s->%s" node-a node-b))
  (cond (not (:contains self node-a))
        (errorf "node %s does not exist" node-a)

        (not (:contains self node-b))
        (errorf "node %s does not exist" node-b)

        (not (nil? (get-in self [:adjacency-table node-a :edges node-b])))
        (errorf "edge between %s->%s already exists" node-a node-b)

        (put-in self [:adjacency-table node-a :edges node-b]
                {:weight weight :name edge-name})))

(defn- neighbors
  """
  Return an list of (node-name, {:weight :name}) of all the neighboring nodes.
  """
  [self from-name]
  (pairs (get-in self [:adjacency-table from-name :edges])))

(defn- contains [self name]
  """
  Return true if the name already maps to a node, false otherwise
  """
  (not (nil? (get-in self [:adjacency-table name]))))

(defn- get-node [self name]
  (get-in self [:adjacency-table name]))

(defn- nodes [self]
  (keys (self :adjacency-table)))

(defn- edges [self]
  (mapcat (fn [(from-node-name node)]
            (map (fn [(to-node-name edge)]
                   (table/to-struct
                    (merge {:from from-node-name :to to-node-name}
                           edge)))
                 (pairs (node :edges))))
          (pairs (self :adjacency-table))))

(def Graph
  @{:add-node add-node
    :add-edge add-edge
    :neighbors neighbors
    :contains contains
    :get-node get-node
    :nodes nodes
    :edges edges
    :adjacency-table @{}})


(defmacro init [& nodes]
  ```
  Instantiate a new directed graph. Can provide starting nodes in convenient syntax.

  (node NAME & patterns)

  Patterns can be
  - (data :key "value")
  - (fn name [args] & body)
  - (edge to-node)
  - (edge to-node weight)
  - (edge edge-name to-node)
  - (edge edge-name to-node weight)

  Heres a complete example

  (init
   (node green
         (data :key "val")
         (edge yellow)) # default weight 1
   (node yellow
         (edge green 3) # override weight
         (edge panic red)) # override name
   (node red
         (edge calm yellow 2))) # override name and weight
  ```
  (table/setproto
   @{:adjacency-table
       (table
        ;(mapcat (fn [[_ name & patterns]]
                   (let [name (keyword name)
                         data @{} edges @{}]
                     (each pattern patterns
                       (match pattern
                         ['data key val]
                         (put data key val)

                         ['fn fname args & body]
                         (put data (keyword fname) ~(fn ,fname ,args ,;body))

                         ['edge name to weight]
                         (put edges (keyword name) {:to (keyword to) :weight weight})

                         ['edge to (weight (number? weight))]
                         (put edges (keyword to) {:to (keyword to) :weight weight})

                         ['edge name (to (symbol? to))]
                         (put edges (keyword name) {:to (keyword to) :weight 1})

                         ['edge to]
                         (put edges (keyword to) {:to (keyword to) :weight 1})))
                     [name {:data data :edges edges}]))
                 nodes))}
   Graph))
