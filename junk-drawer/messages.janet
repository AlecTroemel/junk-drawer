(use ./ecs)

(def-component message
  :content :any
  :consumed :boolean)

(def-system update-sys
  {messages [:entity :message] wld :world}
  (loop [[ent msg] :in messages :when (msg :consumed)]
    (remove-entity wld ent)))

(defmacro send [world content & tags]
  "create a message entity with content & the tag components"
  ~(add-entity ,world
                (message :content ,content :consumed false)
                ,;(map |(tuple $) tags)))

(defn consume [msg]
  (put msg :consumed true))
