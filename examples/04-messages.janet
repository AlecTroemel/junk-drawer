(use ./../src/junk-drawer)

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
# you will get it on the next loop.
(def-system reciever-sys
  (wld :world
   msgs [:message :my-tick]
   movables [:position :velocity])
  (if (> (length msgs) 0)
    (each [msg] msgs
      (pp "consume it")
      (messages/consume msg))
    (print "nothing to consume")))

(register-system world reciever-sys)

(for i 0 3
  (print "i: " i)
  (:update world 1)
  (print ""))
