(defn- insert
  "Add a query and its results to the cache."
  [self query result]
  (put self query result)
  result)

(defn- _get
  "Get cache result for the query, nil if DnE."
  [self query]
  (get self query))

(defn- clear
  "Clear all cache values that container the component in the query."
  [self component]
  (loop [query :keys self
         :when (index-of component query false)]
    (put self query nil)))

(defn init
  "Instantiate new ECS cache."
  []
  (table/setproto
   @{}
   @{:insert insert
     :get _get
     :clear clear}))
