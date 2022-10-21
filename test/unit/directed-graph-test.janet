(import spork/test)
(use /junk-drawer/directed-graph)

(test/start-suite 0)

(var graph (create
            (node :red)
            (node :green
               :key "val"
               :say (fn [self] "hello world"))
            (edge :red :green)
            (edge :panic :green :red 2)))
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

(test/assert (= (first (:neighbors graph :blue)) [:red {:to :red :weight 3}])
             "neighbors returns neighbors")

(test/assert (= (length (:list-nodes graph)) 3)
             "there are 3 nodes in the graph")

(test/assert (= (length (:list-edges graph)) 3)
             "there are 2 edges in the graph")

(test/assert (= (:list-edges graph)
                [{:from :red :name :green :to :green :weight 1}
                 {:from :blue :name :red :to :red :weight 3}
                 {:from :green :name :panic :to :red :weight 2}])
             "edges list uses correct data format")

(test/end-suite)
