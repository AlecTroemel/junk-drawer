(import spork/test)

(import /junk-drawer/ecs)
(import /junk-drawer/messages)

(ecs/def-tag msg-tag)

(test/start-suite 0)
(let [world (ecs/create-world)]
  (var message-process-count 0)
  (ecs/def-system msg-counter
    {wld :world
     msgs [:message :msg-tag]}
    (each [msg] msgs
        (+= message-process-count 1)
        (messages/consume msg)))
  (ecs/register-system world msg-counter)
  (ecs/register-system world messages/update-sys)

  (:update world 1)
  (test/assert (= message-process-count 0) "tick 1: called 0, no messages created")

  (messages/send world "hello" msg-tag)
  (:update world 1)
  (test/assert (= message-process-count 1) "tick 2: called 1 after 1 message")

  (messages/send world "hello again" msg-tag)
  (messages/send world "hello once more" msg-tag)
  (:update world 1)
  (test/assert (= message-process-count 3) "tick 3: called 3 after creating 2 messages"))
(test/end-suite)
