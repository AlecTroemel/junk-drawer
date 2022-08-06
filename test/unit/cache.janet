(import spork/test)
(import /junk-drawer/cache)

(test/start-suite 0)

(let [cache (cache/init)
      key [:pizza]
      data {:hotdog "frenchfry"}]

  (test/assert (= data (:insert cache key data)) "Insert returns data just inserted.")
  (test/assert (= data (:get cache key)) "Cache contains inserted data.")

  (:insert cache [:remove] {:i-will "go away"})
  (:insert cache [:keep :remove] {:i-will "go away"})

  (:clear cache :remove)
  (test/assert (= data (:get cache key)) "Keep non matching component query.")
  (test/assert (= nil (:get cache [:remove])) "Remove matching single component query.")
  (test/assert (= nil (:get cache [:keep :remove])) "Remove matching multi component query."))

(test/end-suite)
