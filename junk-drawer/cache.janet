(defn- insert [self query result]
  "Add a query and its results to the cache."
  (put self query result)
  result)

(defn- _get [self query]
  "Get cache result for the query, nil if DnE."
  (get self query))

(defn- clear [self component]
  "Clear all cache values that container the component in the query."
  (loop [query :keys self
         :when (index-of component query false)]
    (put self query nil)))

(defn init []
  "Instantiate new ECS cache."
  (table/setproto
   @{}
   @{:insert insert
     :get _get
     :clear clear}))
