(use /junk-drawer/ecs)

(def-component message
  :content :any
  :consumed :boolean
  :created :number)

(def-system update-sys
  {messages [:entity :message] wld :world}
  (loop [[ent msg] :in messages :when (msg :consumed)]
    (remove-entity wld ent)))

(defmacro send [world content & tags]
  "create a message entity with content & the tag components"
  (with-syms [$wld]
    ~(let [,$wld ,world]
       (add-entity ,$wld
                    (message :content ,content
                             :consumed false
                             :created (os/clock))
                    ,;(map |(tuple $) tags)))))

(defn consume [msg]
  (put msg :consumed true))
