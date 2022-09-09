(use /junk-drawer/ecs)

(setdyn :doc ```
It is often useful to pass event messages between systems. This extension
to the ECS gives a simple way to do that. Simply register the update system

YOU MUST REGISTER THIS FUNCTION AFTER ALL SYSTEMS THAT USE MESSAGES
(register-system world messages/update-sys)

then send and consume messages.Its very important that you consume every
message you create at some point, otherwise your message queue will grow
indefinitly!
```)

(def-component message
  :content (any)
  :consumed :boolean
  :created :number)

(def-system update-sys
  {messages [:entity :message] wld :world}
  (loop [[ent msg] :in messages :when (msg :consumed)]
    (remove-entity wld ent)))

(defn send
  ```
  create a message entity with content & the tag components.
  Message body can be any type, and tags must be tag components
  (see def-tag).

  (messages/send wld "hello" my-tick)

  Its very important that you consume every message you create at some
  point, otherwise your message queue will grow indefinitly! Consume a
  message with (message/consume msg).
  ```
  [world content & tag-fns]
  (add-entity world
              (message :content content
                       :consumed false
                       :created (os/clock))
              ;(map |($) tag-fns)))

(defn consume
  ```
  Consume a message, deleting its entity from the world. Its very
  important that you consume every message you create at some point,
  otherwise your message queue will grow indefinitly!

  (message/consume msg)
  ```
  [msg]
  (put msg :consumed true))
