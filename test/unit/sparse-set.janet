(import spork/test)
(import /junk-drawer/sparse-set)

(test/start-suite 0)

(let [ss (sparse-set/init 10)
      data {:cmp "data"}]
  (test/assert (= -1 (:search ss 0)) "Does not find EID 0, set empty.")

  (:insert ss 0 data)

  (test/assert (= 1 (ss :n)) "n is 1 after insert.")
  (test/assert (= 0 (:search ss 0)) "Finds EID 0 after insert.")

  (:delete ss 0)
  (test/assert (= -1 (:search ss 0)) "Search for 0 returns empty after delete.")

  (:insert ss 1 data)
  (:insert ss 2 data)
  (:clear ss)
  (test/assert (= -1 (:search ss 1)) "Search for 1 returns empty after clear.")
  (test/assert (= -1 (:search ss 2)) "Search for 2 returns empty after clear.")

  (:insert ss 3 data)
  (test/assert (= data (:get-component ss 3)) "Gets component data for EID 3"))

(test/end-suite)
