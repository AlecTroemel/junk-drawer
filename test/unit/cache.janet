(import testament :prefix "" :exit true)

(import /junk-drawer/cache)

(deftest cache-insert-and-get
  (let [cache (cache/init)
        key [:pizza]
        data {:hotdog "frenchfry"}
        result (:insert cache key data)]

    (is (assert-deep-equal result data) "Insert returns data just inserted.")
    (is (assert-deep-equal (:get cache key) data) "Cache contains inserted data.")))

(deftest cache-clear
  (let [cache (cache/init)]
    (:insert cache [:keep] {:i-will "stay"})
    (:insert cache [:remove] {:i-will "go away"})
    (:insert cache [:keep :remove] {:i-will "go away"})

    (:clear cache :remove)

    (is (assert-deep-equal {:i-will "stay"} (:get cache [:keep]))
        "Keep non matching component query.")
    (is (= nil (:get cache [:remove]))
        "Remove matching single component query.")
    (is (= nil (:get cache [:keep :remove]))
        "Remove matching multi component query.")))

(run-tests!)
