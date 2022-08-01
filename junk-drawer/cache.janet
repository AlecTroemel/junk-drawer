(defn- insert [self query result]
  (put self query result)
  result)

(defn- _get [self query]
  (get self query))

(defn- clear [self component]
  (loop [query :keys self
         :when (index-of component query false)]
    (put self query nil)))

(defn init []
  (table/setproto
   @{}
   @{:insert insert
     :get _get
     :clear clear}))
