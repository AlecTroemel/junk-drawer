(import spork/test)
(import /build/junk-drawer/cache)

(test/start-suite 0)

(let [cache (cache/init)
      key [:pizza]
      data {:hotdog "frenchfry"}]

  (test/assert (= cache (put cache key data))
               "Core put inserts into the cache.")
  (test/assert (= data (get cache key))
               "Core get retrieves from the cache.")

  (put cache [:remove] {:i-will "go away"})
  (put cache [:keep :remove] {:i-will "go away"})

  (cache/clear cache :remove)
  (test/assert (= data (get cache key))
               "Keep non matching component query.")
  (test/assert (= nil (get cache [:remove]))
               "Remove matching single component query.")
  (test/assert (= nil (get cache [:keep :remove]))
               "Remove matching multi component query.")
  (test/assert (= [:pizza] (next cache nil))
               "You can use core next method for enumeration")
  (test/assert (= nil (next cache [:pizza]))
               "You can use core next method for enumeration"))

(test/end-suite)
