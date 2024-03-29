(use /junk-drawer)

(def world (create-world))

(register-system world timers/update-sys)
(register-system world messages/update-sys)

# # on thier own timers may not seem very useful. But with messages
# # you can have timers interact with other systems
# #
# # Messages are also just entities with some helpful wrappers
# # they are composed of content (any type), and any number of tags
(def-tag my-tick)

(timers/every world 2
              (fn [wld dt]
                (messages/send wld "hello" my-tick)))

# then you may query for that specific message.
# dont forget to consume the message after youre done with it, otherwise
# you will get it on the next loop. This example also sorts messages by
# when they were created.
(def-system reciever-sys
  {wld :world
   msgs [:message :my-tick]
   movables [:position :velocity]}
  (if (> (length msgs) 0)
    (each [msg] (sorted-by |(get-in $ [0 :created]) msgs)
      (prin "consume ")
      (pp (msg :content))
      (messages/consume msg))
    (print "nothing to consume")))

(register-system world reciever-sys)

(for i 0 3
  (print "i: " i)
  (:update world 1)
  (print ""))
