(use ./ecs)

(def-component message [content consumed])

(def-system update-sys
  (messages [:entity :messages] wld :world)
  (loop [[ent msg] :in messages :when (= 0 (msg :life))]
    (remove-entity wld ent)))

# (defn send [world content tag]
#   (add-entity world (message content false) tags))

# (def consume [message]
#   (put message :consumed true))
