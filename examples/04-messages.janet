(use ./../src/junk-drawer)

(def world (create-world))

(register-system world timer/update-sys)
(register-system world message/update-sys)

# on thier own timers may not seem very useful. But with messages
# you can have timers interact with other systems
#
# Messages are also just entities with some helpful wrappers
# they are composed of content (any type), and any number of tags
(def-tag my-tick)

(timer/every world 5
  (fn [wld dt]
    (add-entity wld (message "done" false) (my-tick))))

# (message/send wld "done" (my-tick))

# then you may query for that specific message.
# dont forget to consume the message after youre done with it, otherwise
# you will get it on the next loop.

# (def-system reciever-sys
#   (world :world
#    msgs [:messages :my-tick]
#    movables [:position :velocity])
#   (when (> (length msgs) 0)
#     (each msg msgs
#       (pp msg)
#       (message/consume msg))))

# (for i 0 15
#   (print "i: " i)
#   (:update world 1)
#   (print ""))
