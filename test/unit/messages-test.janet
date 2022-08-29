(import spork/test)

# NOTE Because of a limitation/bug of the messages send macro, we need to "use" these files.
(use /junk-drawer/ecs)
(use /junk-drawer/messages)

(def-tag msg-tag)



(test/start-suite 0)
(let [world (create-world)]
  (register-system world update-sys)

  (var message-process-count 0)
  (def-system msg-counter
    {wld :world
     msgs [:message :msg-tag]}
    (pp msgs)
    (each [msg] msgs
        (+= message-process-count 1)
        (consume msg)))
  (register-system world msg-counter)

  (:update world 1)
  (test/assert (= message-process-count 0) "tick 1: called 0, no messages created")

  (send world "hello" msg-tag)
  (:update world 1)
  (test/assert (= message-process-count 1) "tick 2: called 1 after 1 message")

  (send world "hello again" msg-tag)
  (send world "hello once more" msg-tag)
  (:update world 1)
  (test/assert (= message-process-count 3) "tick 3: called 3 after creating 2 messages"))
(test/end-suite)
