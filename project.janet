(declare-project
  :name "junk-drawer"
  :description "A collection of random tools for gamedev."
  :author "Alec Troemel"
  :license "MIT"
  :url "https://github.com/AlecTroemel/junk-drawer"
  :repo "git+https://github.com/AlecTroemel/junk-drawer"
  :dependencies ["spork"])


(add-loader)
(import /src/cache)

(task "cache.c" []
      (cache/render "src/cache.c"))

(declare-native
  :name "junk-drawer/cache"
  :source @["src/cache.c"])

(declare-source
  :source @["junk-drawer" "junk-drawer.janet"])
