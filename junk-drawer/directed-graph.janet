# https://medium.com/tebs-lab/implementations-of-graphs-92eb7f121793


(defmacro node [name & properties]
  (if (keyword? name)
    ~[:node ,(keyword name) ,{:edges @{} :data (table ;properties)}]
      (error "name must be a keyword")))

(defmacro edge
  ```
  - (edge :edge-name :from-node :to-node weight)
  - (edge :edge-name :from-node :to-node)
  - (edge :from-node :to-node weight)
  - (edge :from-node :to-node)
  ```
  [& pattern]

  (match pattern
    [(name (keyword? name)) (from (keyword? from)) (to (keyword? to)) (weight (number? weight))]
    ~[:edge ,from {:to ,to :name ,name :weight ,weight}]

    [(name (keyword? name)) (from (keyword? from)) (to (keyword? to))]
    ~[:edge ,from {:to ,to :name ,name :weight 1}]

    [(from (keyword? from)) (to (keyword? to)) (weight (number? weight))]
    ~[:edge ,from {:to ,to :name ,to :weight ,weight}]

    [(from (keyword? from)) (to (keyword? to))]
    ~[:edge ,from {:to ,to :name ,to :weight 1}]))

(defn- contains [self name]
  ```
  Return true if the name already maps to a node, false otherwise
  ```
  (not (nil? (get-in self [:adjacency-table name]))))

(defn add-node
  ```
  Add a node to the graph. Throws error if node already exists in the graph.
  ```
  [self [NODE name content]]

  (if (:contains self name)
    (errorf "graph already contains node %s" name)
    (put-in self [:adjacency-table name] content)))

(defn- add-edge
  ```
  Add a new edge to the graph. You should use the "edge macro to create the new edge.
  Both from and to nodes must exist.
  ```
  [self [EDGE from {:to to :name name :weight weight}]]
  (cond (not (:contains self from))
        (errorf "graph does not contain from node %s" from)

        (not (:contains self to))
        (errorf "graph does not contain to node %s" to)

        (put-in self [:adjacency-table from :edges name]
                {:to to :weight weight})))

(defn- neighbors
  ```
  Return an list of tuples (edge-name to weight) of all the neighboring nodes.
  ```
  [self from-name]
  (if-let [node (get-in self [:adjacency-table from-name])
           edges (get node :edges)]
    (map (fn [(name data)] [name (get data :to) (get data :weight)])
         (pairs edges))
    []))

(defn- get-node [self name]
  (get-in self [:adjacency-table name]))

(defn- list-nodes [self]
  (keys (self :adjacency-table)))

(defn- list-edges [self]
  [;(mapcat (fn [(from-node-name node)]
            (map (fn [(edge-name edge)]
                   (table/to-struct
                    (merge {:from from-node-name :name edge-name}
                           edge)))
                 (pairs (get node :edges))))
          (pairs (self :adjacency-table)))])

(defn- priority-push [priority-queue data weight]
  (array/push priority-queue [data weight]))

(defn- priority-pop [priority-queue]
  "Pop the element with the lowest weight, items should be in form (data weight)."

  # Find lowest weighted element
  (var lowest-i 0)
  (var lowest-weight 0)

  (for i 0 (length priority-queue)
    (when-let [[data weight] (get priority-queue i)
               is-lower (< weight lowest-weight)]
      (set lowest-i i)
      (set lowest-weight weight)))

  # remove it from the queue, then return its data
  (let [(data weight) (get priority-queue lowest-i)]
    (array/remove priority-queue lowest-i)
    data))

(defn- find-path
  ```
  ```
  [self start goal &opt heuristic]

  (default heuristic (fn [& rest] 0))

  (let [frontier @[[start 0]]
        came-from @{}
        cost-so-far @{start 0}]
    (loop [current :iterate (priority-pop frontier)
           :until (= current goal)
           (edge-name next weight) :in (:neighbors self current)
           :let [new-cost (+ (cost-so-far current) weight)]
           :while (or (nil? (get came-from next))
                      (< new-cost (cost-so-far next)))]
      (put cost-so-far next new-cost)
      (priority-push frontier next (+ new-cost (heuristic self goal next)))
      (put came-from next current))

    # follow the came-from backwards from the goal to the start.
    (var current goal)
    (let [path @[]]
      (while (not= current start)
        (array/push path current)
        (set current (get came-from current)))
      (array/push path start)
      (reverse path))))

(def Graph
  @{:contains contains
    :add-node add-node
    :add-edge add-edge
    :get-node get-node
    :neighbors neighbors
    :list-nodes list-nodes
    :list-edges list-edges
    :find-path find-path
    :adjacency-table @{}})

(defn create [& patterns]
  ```
  Instantiate a new directed graph. Can provide starting nodes in convenient syntax.

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
  (let [graph (table/setproto @{:adjacency-table @{}} Graph)
        nodes (filter |(= :node (first $)) patterns)
        edges (filter |(= :edge (first $)) patterns)]

    (each n nodes (:add-node graph n))
    (each e edges (:add-edge graph e))

    graph))
