(import spork/test)
(use /junk-drawer/directed-graph)

(test/start-suite 0)
(let [graph (create
             (node :red)
             (node :green
                :key "val"
                :say (fn [self] "hello world"))
             (edge :red :green)
             (edge :panic :green :red 2))]
  (test/assert (and (:contains graph :red)
                    (:contains graph :green))
               "graph init creates provided nodes")

  (:add-node graph (node :blue :another "data"))
  (test/assert (:contains graph :blue)
               "contains returns true for just added node")

  (test/assert (= (get-in (:get-node graph :blue) [:data :another]) "data")
               "get-node returns the node and contains the provided data")

  (:add-edge graph (edge :blue :red 3))
  (test/assert (not (nil? (get-in (:get-node graph :blue) [:edges :red])))
               "add-edge added the edge")

  (test/assert (= (first (:neighbors graph :blue))
                  {:from :blue :name :red :to :red :weight 3})
               "neighbors returns neighbors")

  (test/assert (= (length (:list-nodes graph)) 3)
               "there are 3 nodes in the graph")

  (test/assert (= (length (:list-edges graph)) 3)
               "there are 2 edges in the graph")

  (test/assert (= (:list-edges graph)
                  [{:from :red :name :green :to :green :weight 1}
                   {:from :blue :name :red :to :red :weight 3}
                   {:from :green :name :panic :to :red :weight 2}])
               "edges list uses correct data format"))
(test/end-suite)


(test/start-suite 1)
(let [graph (create (node :a) (node :b) (node :c)
                                    (node :g)
                    (node :d) (node :e) (node :f)

                    (edge :a :b)
                    (edge :b :d)
                    (edge :b2g :b :g 10)
                    (edge :c :f)
                    (edge :d :e)
                    (edge :e2g :e :g)
                    (edge :g :c))]

  (test/assert (= (:find-path graph :a :f)
                  [:b :d :e :e2g :c :f])
               "should find correct path"))
(test/end-suite)

# Test if we can use forms for node data and edges info
(test/start-suite 2)
(let [data @{:a "pizza" :b "hotdog"}
      new-node (node :a ;(kvs data))]
  (test/assert (= (get-in new-node [2 :data :a]) "pizza")
               "should have spliced data correctly"))

(let [name :pizza
      from :a
      to :b
      new-edge (edge name from to)]
  (test/assert (= new-edge [:edge :a {:name :pizza :to :b :weight 1}]))
  )
(test/end-suite)
