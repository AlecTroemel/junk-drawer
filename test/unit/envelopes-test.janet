(import spork/test)
(import /junk-drawer/envelopes)

# AR
(test/start-suite 0)
# Lets go through all the states
(let [*ar* (envelopes/ar
             :attack-target 10 :attack-duration 10
             :release-duration 10)]
  (test/assert (= (*ar* :current) :idle) "AR starts in idle")

  (:trigger *ar*)
  (test/assert (= (*ar* :current) :attack) "AR attack after triggering from idle")

  (for i 0 11 (:tick *ar*))
  (test/assert (= (*ar* :value) 10) "AR end of attack is 10")
  (test/assert (= (*ar* :current) :release) "AR release after 10 ticks of attack")

  (for i 0 11 (:tick *ar*))
  (test/assert (= (*ar* :value) 0) "AR end of release is 0")
  (test/assert (= (*ar* :current) :idle) "AR idle after 10 ticks of release"))

# Make sure we can re-trigger from both states
(let [*ar* (envelopes/ar
            :attack-target 10 :attack-duration 2
            :release-duration 10)]
  (:trigger *ar*)
  (:trigger *ar*)
  (test/assert (= (*ar* :current) :attack) "AR attack after (re)triggering from trigger")

  (for i 0 3 (:tick *ar*))
  (:trigger *ar*)
  (test/assert (= (*ar* :current) :attack) "AR attack after triggering from release"))

# Make sure we  can release early
(let [*ar* (envelopes/ar
            :attack-target 10 :attack-duration 10
            :release-duration 10)]
  (:trigger *ar*)

  (for i 0 3 (:tick *ar*)) # still in attack after just 3 ticks
  (:release *ar*)
  (test/assert (= (*ar* :current) :release) "AR release after releasing early in :attack"))
(test/end-suite)

# ASR
(test/start-suite 1)

# Test going through all the states
(let [*asr* (envelopes/asr
             :attack-target 10 :attack-duration 10
             :release-duration 10)]
  (test/assert (= (*asr* :current) :idle) "ASR starts in idle")

  (:trigger *asr*)
  (test/assert (= (*asr* :current) :attack) "ASR attack after begin")

  (for i 0 11 (:tick *asr*))
  (test/assert (= (*asr* :value) 10) "ASR end of attack is 10")
  (test/assert (= (*asr* :current) :sustain) "ASR sustain after 10 ticks of attack")

  (for i 0 10 (:tick *asr*))
  (test/assert (= (*asr* :value) 10) "ASR sustain is still 5")
  (test/assert (= (*asr* :current) :sustain) "ASR still in sustain")
  (:release *asr*)
  (test/assert (= (*asr* :current) :release) "ASR release after calling :release")

  (for i 0 11 (:tick *asr*))
  (test/assert (= (*asr* :value) 0) "ASR end of relase is 0")
  (test/assert (= (*asr* :current) :idle) "ASR idle after 10 ticks of release"))

# Test (re)triggering from all the states
(let [*asr* (envelopes/asr
             :attack-target 10 :attack-duration 10
             :release-duration 10)]
  (:goto *asr* :attack)
  (:trigger *asr*)
  (test/assert (= (*asr* :current) :attack) "ASR attack after triggering from attack")

  (:goto *asr* :sustain)
  (:trigger *asr*)
  (test/assert (= (*asr* :current) :attack) "ASR attack after triggering from sustain")

  (:goto *asr* :release)
  (:trigger *asr*)
  (test/assert (= (*asr* :current) :attack) "ASR attack after triggering from release"))

# Test releasing early
(let [*asr* (envelopes/asr
             :attack-target 10 :attack-duration 10
             :release-duration 10)]
  (:goto *asr* :attack)
  (:release *asr*)
  (test/assert (= (*asr* :current) :release) "ASR release after triggering from attack")

  (:goto *asr* :sustain)
  (:release *asr*)
  (test/assert (= (*asr* :current) :release) "ASR release after triggering from sustain"))
(test/end-suite)

# ADSR
(test/start-suite 2)

# Test going through all the states
(let [*adsr* (envelopes/adsr
             :attack-target 10 :attack-duration 10
             :decay-target 5 :decay-duration 10
             :sustain-duration 10
             :release-duration 10)]
  (test/assert (= (*adsr* :current) :idle) "ADSR starts in idle")

  (:trigger *adsr*)
  (test/assert (= (*adsr* :current) :attack) "ADSR attack after begin")

  (for i 0 11 (:tick *adsr*))
  (test/assert (= (*adsr* :value) 10) "ADSR end of attack is 10")
  (test/assert (= (*adsr* :current) :decay) "ADSR decay after 10 ticks of attack")

  (for i 0 11 (:tick *adsr*))
  (test/assert (= (*adsr* :value) 5) "ADSR end of decay is 5")
  (test/assert (= (*adsr* :current) :sustain) "ADSR sustain after 10 ticks of decay")


  (for i 0 11 (:tick *adsr*))
  (test/assert (= (*adsr* :value) 5) "ADSR sustain is still 5")
  (test/assert (= (*adsr* :current) :sustain) "AdSR still in sustain")
  (:release *adsr*)
  (test/assert (= (*adsr* :current) :release) "AdSR release after calling :release")

  (for i 0 11 (:tick *adsr*))
  (test/assert (= (*adsr* :value) 0) "ADSR end of sustain is 0")
  (test/assert (= (*adsr* :current) :idle) "ADSR idle after 10 ticks of release"))

# Test (re)triggering from all the states
(let [*adsr* (envelopes/adsr
              :attack-target 10 :attack-duration 10
              :decay-target 5 :decay-duration 10
              :sustain-duration 10
              :release-duration 10)]
  (:goto *adsr* :attack)
  (:trigger *adsr*)
  (test/assert (= (*adsr* :current) :attack) "ADSR attack after triggering from attack")

  (:goto *adsr* :decay)
  (:trigger *adsr*)
  (test/assert (= (*adsr* :current) :attack) "ADSR attack after triggering from decay")

  (:goto *adsr* :sustain)
  (:trigger *adsr*)
  (test/assert (= (*adsr* :current) :attack) "ADSR attack after triggering from sustain")

  (:goto *adsr* :release)
  (:trigger *adsr*)
  (test/assert (= (*adsr* :current) :attack) "ADSR attack after triggering from release"))

# Test releasing early
(let [*adsr* (envelopes/adsr
              :attack-target 10 :attack-duration 10
              :decay-target 5 :decay-duration 10
              :sustain-duration 10
              :release-duration 10)]
  (:goto *adsr* :attack)
  (:release *adsr*)
  (test/assert (= (*adsr* :current) :release) "ADSR release after triggering from attack")

  (:goto *adsr* :decay)
  (:release *adsr*)
  (test/assert (= (*adsr* :current) :release) "ADSR release after triggering from decay")

  (:goto *adsr* :sustain)
  (:release *adsr*)
  (test/assert (= (*adsr* :current) :release) "ADSR release after triggering from sustain"))
(test/end-suite)
