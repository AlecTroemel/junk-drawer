(import testament :prefix "" :exit true)

(import /junk-drawer/sparse-set)

(deftest sparse-set-insert
  (let [ss (sparse-set/init 10)]
    (:insert ss 0 {:cmp "data"})
    (is (= 1 (ss :n)) "n is 1 after insert.")))

(deftest sparse-set-search
  (let [ss (sparse-set/init 10)]
    (is (= -1 (:search ss 0)) "Does not find EID 0.")
    (:insert ss 0 {:cmp "data"})
    (is (= 0 (:search ss 0)) "Finds EID 0.")))

(deftest sparse-set-delete
  (let [ss (sparse-set/init 10)]
    (:insert ss 7 {:cmp "data"})
    (is (= 0 (:search ss 7)) "Finds EID 7.")

    (:delete ss 7)
    (is (= -1 (:search ss 7)) "Does not find deleted EID 7.")))

(deftest sparse-set-clear
  (let [ss (sparse-set/init 10)]
    (:insert ss 4 {:cmp "data 1"})
    (:insert ss 7 {:cmp "data 2"})
    (is (= 0 (:search ss 4)) "Finds EID 4.")
    (is (= 1 (:search ss 7)) "Finds EID 7.")

    (:clear ss)
    (is (= -1 (:search ss 4)) "Search for 0 returns empty.")
    (is (= -1 (:search ss 7)) "Search returns ID found on empty set.")))

(deftest sparse-set-get-component
  (let [ss (sparse-set/init 10)
        data {:cmp "data 1"}]
    (:insert ss 4 data)
    (is (assert-deep-equal data (:get-component ss 4))
        "Gets component data for EID 4")))

(run-tests!)
