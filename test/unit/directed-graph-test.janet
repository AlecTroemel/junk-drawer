(import spork/test)
(import /junk-drawer/directed-graph)

(test/start-suite 0)
(var graph (directed-graph/init))

(test/assert (not (:contains graph :a))
             "new graph contains nothing")
(test/assert (:add-node graph :a {:my "data here"})
             "add node returns true")
(test/assert (:contains graph :a)
             "contains returns true for just added node")
(test/assert (= ((:get-node graph :a) :my) "data here")
             "get-node returns the node and contains the provided data")

(:add-node graph :b )
(:add-edge graph :a :b)
(test/assert (= (first (:neighbors graph :a)) [:b {:name "a->b" :weight 1}])
             "add-edge and neighbors works with defaults")

(:add-node graph :c )
(:add-edge graph :a :c 4 "custom a to c")
(test/assert (= (first (:neighbors graph :a)) [:c {:name "custom a to c" :weight 4}])
             "add-edge override default weight and name")

(test/assert (= (length (:nodes graph)) 3)
             "there are 3 nodes in the graph")

(test/assert (= (length (:edges graph)) 2)
             "there are 2 edges in the graph")
(test/assert (= (:edges graph) [{:from :a :to :c :name "custom a to c" :weight 4}
                                {:from :a :to :b :name "a->b" :weight 1}])
             "edges list uses correct data format")

(test/end-suite)
