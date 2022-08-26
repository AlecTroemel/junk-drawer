(use /junk-drawer/ecs)

(def-component message
  :content :any
  :consumed :boolean
  :created :number)

(def-system update-sys
  {messages [:entity :message] wld :world}
  (loop [[ent msg] :in messages :when (msg :consumed)]
    (remove-entity wld ent)))

(defmacro send
  ```
  create a message entity with content & the tag components. Requires
  registering the (register-system world messages/update-sys) system.
  Message body can be any type, and tags must be tag components
  (see def-tag).

  (messages/send wld "hello" my-tick)

  Its very important that you consume every message you create at some
  point, otherwise your message queue will grow indefinitly! Consume a
  message with (message/consume msg).
  ```
  [world content & tags]
  (with-syms [$wld]
    ~(let [,$wld ,world]
       (add-entity ,$wld
                    (message :content ,content
                             :consumed false
                             :created (os/clock))
                    ,;(map |(tuple $) tags)))))

(defn consume
  ```
  Consume a message, deleting its entity from the world. Its very
  important that you consume every message you create at some point,
  otherwise your message queue will grow indefinitly!

  (message/consume msg)
  ```
  [msg]
  (put msg :consumed true))
