;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cognitive Amplification vs Delegation Simulator
;; NetLogo version aligned with the paper
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions []

globals [
  experiment-mode  ;; "full" "mixed" "minimal"
  ;; reproducibility / export
  run-seed
  export-window
  last-eval-tick

  ;; phase control
  current-phase
  ai-available?
  ai-off-now?

  ;; simulation schedule
  baseline-length
  exposure-length
  stress-length
  total-length

  ;; AI-off evaluation schedule
  ai-off-interval
  ai-off-duration
  last-ai-off-qh
  current-hcdr

  ;; task state
  current-task-family
  current-requirements
  current-difficulty
  current-perturbation
  current-effective-difficulty
  current-activated-indices

  ;; novelty / robustness probes
  probe-now?
  probe-type
  novelty-probe-interval
  pert-probe-interval
  shifted-families-active?

  ;; task family definitions
  family-names
  baseline-family-weights
  shifted-family-weights

  ;; population metrics
  mean-skill
  mean-productivity
  mean-qh
  mean-qh-pert
  mean-qh-novel
  ai-usage-rate
  cai-star
  dependency-ratio
  hri
  dependency-use-sensitivity

  ;; temporary accumulators
  pop-hybrid-sum
  pop-human-sum
  pop-ai-sum
  pop-usage-count
  pop-qh-eval-sum
  pop-qh-pert-sum
  pop-qh-novel-sum
  pop-qh-eval-count
  pop-qh-pert-count
  pop-qh-novel-count

  ;; final-window accumulators for export
  export-count
  export-cai-sum
  export-d-sum
  export-hri-sum
  export-hcdr-sum
  export-qh-sum
  export-qh-pert-sum
  export-qh-novel-sum
  export-skill-sum
  export-qha-sum
  export-aiuse-sum

  export-skill-g1-sum
  export-skill-g2-sum
  export-skill-g3-sum

  export-qh-g1-sum
  export-qh-g2-sum
  export-qh-g3-sum

  export-qha-g1-sum
  export-qha-g2-sum
  export-qha-g3-sum

  export-aiuse-g1-sum
  export-aiuse-g2-sum
  export-aiuse-g3-sum

  export-novelty-g1-sum
  export-novelty-g2-sum
  export-novelty-g3-sum
]

turtles-own [
  group-id
  p-ai
  skill-vector

  last-used-ai?
  last-mismatch
  last-effort
  last-performance
  last-autonomous-performance

  novelty-score
  drift-score

  dependency-level
]

to setup
  clear-turtles
  clear-patches
  clear-links
  clear-drawing
  clear-output
  clear-all-plots

  if not member? experiment-mode ["full" "minimal" "mixed"] [
    set experiment-mode "mixed"
  ]

  ;; reproducibility defaults
  if run-seed = 0 [ set run-seed 12345 ]
  if export-window <= 0 [ set export-window 100 ]
  random-seed run-seed

  ;; reproducibility defaults

  if run-seed = 0 [ set run-seed 12345 ]

  if export-window <= 0 [ set export-window 100 ]

  random-seed run-seed

  ;; ---- core parameters ----
  set baseline-length 100
  set exposure-length 800
  set stress-length 800
  set total-length (baseline-length + exposure-length + stress-length)

  set ai-off-interval 25
  set ai-off-duration 5

  set novelty-probe-interval 20
  set pert-probe-interval 15

  set family-names ["analytical" "diagnostic" "sequential" "mixed"]
  set baseline-family-weights [0.30 0.30 0.25 0.15]
  set shifted-family-weights  [0.10 0.20 0.20 0.50]

  set current-hcdr 0
  set last-ai-off-qh nobody
  set last-eval-tick -1
  set shifted-families-active? false
  set probe-now? false
  set probe-type ""
  set ai-off-now? compute-ai-off-now?

  reset-export-accumulators

  create-turtles num-agents [
    setxy random-xcor random-ycor
    set shape "person"
    set size 1.2
    initialize-group
    initialize-skills
    set last-used-ai? false
    set last-mismatch 0
    set last-effort 0
    set last-performance 0
    set last-autonomous-performance 0
    set novelty-score 0
    set drift-score 0
    set dependency-level 0
    recolor-agent
  ]

  reset-ticks
  update-phase
  setup-main-task
  reset-population-accumulators
  update-global-metrics
  update-agent-domain-transfer-colors
end

to reset-export-accumulators
  set export-count 0
  set export-cai-sum 0
  set export-d-sum 0
  set export-hri-sum 0
  set export-hcdr-sum 0
  set export-qh-sum 0
  set export-qh-pert-sum 0
  set export-qh-novel-sum 0
  set export-skill-sum 0
  set export-qha-sum 0
  set export-aiuse-sum 0

  set export-skill-g1-sum 0
  set export-skill-g2-sum 0
  set export-skill-g3-sum 0

  set export-qh-g1-sum 0
  set export-qh-g2-sum 0
  set export-qh-g3-sum 0

  set export-qha-g1-sum 0
  set export-qha-g2-sum 0
  set export-qha-g3-sum 0

  set export-aiuse-g1-sum 0
  set export-aiuse-g2-sum 0
  set export-aiuse-g3-sum 0

  set export-novelty-g1-sum 0
  set export-novelty-g2-sum 0
  set export-novelty-g3-sum 0
end

to accumulate-export-window
  if ticks < (total-length - export-window) [ stop ]

  set export-count (export-count + 1)

  set export-cai-sum (export-cai-sum + cai-star)
  set export-d-sum (export-d-sum + dependency-ratio)
  set export-hri-sum (export-hri-sum + hri)
  set export-hcdr-sum (export-hcdr-sum + current-hcdr)
  set export-qh-sum (export-qh-sum + mean-qh)
  set export-qh-pert-sum (export-qh-pert-sum + mean-qh-pert)
  set export-qh-novel-sum (export-qh-novel-sum + mean-qh-novel)
  set export-skill-sum (export-skill-sum + mean-skill)
  set export-qha-sum (export-qha-sum + mean-productivity)
  set export-aiuse-sum (export-aiuse-sum + ai-usage-rate)

  set export-skill-g1-sum (export-skill-g1-sum + mean-skill-group 1)
  set export-skill-g2-sum (export-skill-g2-sum + mean-skill-group 2)
  set export-skill-g3-sum (export-skill-g3-sum + mean-skill-group 3)

  set export-qh-g1-sum (export-qh-g1-sum + mean-qh-group 1)
  set export-qh-g2-sum (export-qh-g2-sum + mean-qh-group 2)
  set export-qh-g3-sum (export-qh-g3-sum + mean-qh-group 3)

  set export-qha-g1-sum (export-qha-g1-sum + mean-qha-group 1)
  set export-qha-g2-sum (export-qha-g2-sum + mean-qha-group 2)
  set export-qha-g3-sum (export-qha-g3-sum + mean-qha-group 3)

  set export-aiuse-g1-sum (export-aiuse-g1-sum + mean-ai-use-group 1)
  set export-aiuse-g2-sum (export-aiuse-g2-sum + mean-ai-use-group 2)
  set export-aiuse-g3-sum (export-aiuse-g3-sum + mean-ai-use-group 3)

  set export-novelty-g1-sum (export-novelty-g1-sum + mean-novelty-group 1)
  set export-novelty-g2-sum (export-novelty-g2-sum + mean-novelty-group 2)
  set export-novelty-g3-sum (export-novelty-g3-sum + mean-novelty-group 3)
end

to go
  if ticks >= total-length [ stop ]

  update-phase
  set ai-off-now? compute-ai-off-now?
  set probe-now? false
  set probe-type ""

  setup-main-task
  reset-population-accumulators

  ask turtles [
    run-main-interaction
  ]

  maybe-run-perturbation-probe
  maybe-run-novelty-probe
  update-agent-domain-transfer-colors
  update-global-metrics

  tick
end

to initialize-group
  if experiment-mode = "full" [
    set group-id 1
    set p-ai 1.0
  ]
  if experiment-mode = "minimal" [
    set group-id 2
    set p-ai 0.0
  ]
  if experiment-mode = "mixed" [
    set group-id 3
    set p-ai 0.5
  ]
end

to initialize-skills
  let s []
  let i 0
  while [i < k-skills] [
    set s lput (0.35 + random-float 0.35) s
    set i i + 1
  ]
  set skill-vector s
end

to update-phase
  if ticks < baseline-length [
    set current-phase 1
    set ai-available? false
    set shifted-families-active? false
  ]
  if ticks >= baseline-length and ticks < (baseline-length + exposure-length) [
    set current-phase 2
    set ai-available? true
    set shifted-families-active? false
  ]
  if ticks >= (baseline-length + exposure-length) [
    set current-phase 3
    set ai-available? true
    set shifted-families-active? true
  ]
end

to recolor-by-novelty
  if novelty-score >= 0.70 [
    set color green
  ]
  if novelty-score < 0.70 and novelty-score >= 0.40 [
    set color yellow
  ]
  if novelty-score < 0.40 [
    set color red
  ]
end

to recolor-by-dependency
  if dependency-level < 0.33 [
    set color green
  ]
  if dependency-level >= 0.33 and dependency-level < 0.66 [
    set color yellow
  ]
  if dependency-level >= 0.66 [
    set color red
  ]
end

to update-agent-domain-transfer-colors
  let fam choose-family true
  let active-idx activated-indices-for-family fam
  let reqs generate-requirements active-idx
  let diff clamp01 (0.40 + random-float 0.40 + novelty-difficulty-boost)

  ask turtles [
    let mismatch-novel compute-mismatch skill-vector reqs
    let perf-novel compute-autonomous-performance mismatch-novel diff

    set novelty-score perf-novel
    recolor-by-novelty
  ]
end

to recolor-by-transfer
  if novelty-score >= 0.70 [ set color green ]
  if novelty-score < 0.70 and novelty-score >= 0.40 [ set color yellow ]
  if novelty-score < 0.40 [ set color red ]
end

to recolor-agent
  recolor-by-transfer
end


to-report compute-ai-off-now?
  if current-phase != 2 [ report false ]
  let local-tick (ticks - baseline-length)
  if local-tick < 0 [ report false ]
  if remainder local-tick ai-off-interval < ai-off-duration [ report true ]
  report false
end

to setup-main-task
  let fam choose-family shifted-families-active?
  set current-task-family fam
  set current-activated-indices activated-indices-for-family fam
  set current-requirements generate-requirements current-activated-indices
  set current-difficulty (0.2 + random-float 0.6)
  set current-perturbation random-perturbation perturbation-amplitude
  set current-effective-difficulty clamp01 (current-difficulty + current-perturbation)
end

to-report choose-family [shifted?]
  let weights baseline-family-weights
  if shifted? [ set weights shifted-family-weights ]

  let u random-float 1
  let cum 0
  let idx 0
  while [idx < length family-names] [
    set cum (cum + item idx weights)
    if u <= cum [ report item idx family-names ]
    set idx idx + 1
  ]
  report last family-names
end

to-report activated-indices-for-family [fam]
  if fam = "analytical" [ report [0 1] ]
  if fam = "diagnostic" [ report [2 3] ]
  if fam = "sequential" [ report [4 5] ]
  if fam = "mixed" [ report [1 3 5] ]
  report [0 1]
end

to-report generate-requirements [active-idx]
  let req []
  let j 0
  while [j < k-skills] [
    ifelse member? j active-idx
      [ set req lput (0.45 + random-float 0.50) req ]
      [ set req lput (0.05 + random-float 0.20) req ]
    set j j + 1
  ]
  report req
end

to-report random-perturbation [amp]
  report ((random-float (2 * amp)) - amp)
end

to run-main-interaction
  let mismatch compute-mismatch skill-vector current-requirements
  let effort compute-effort mismatch current-effective-difficulty
  let use-ai? decide-ai-use effort

  set last-mismatch mismatch
  set last-effort effort
  set last-used-ai? use-ai?

  if use-ai? [
    let perf ai-reliability
    set last-performance perf
    set last-autonomous-performance compute-autonomous-performance mismatch current-effective-difficulty

    update-skills-ai current-requirements current-activated-indices
    apply-atrophy current-activated-indices
    update-dependency-state true

    set pop-usage-count (pop-usage-count + 1)
    set pop-hybrid-sum (pop-hybrid-sum + perf)
    set pop-ai-sum (pop-ai-sum + ai-reliability)
    set pop-human-sum (pop-human-sum + last-autonomous-performance)
  ]

  if not use-ai? [
    let perf compute-autonomous-performance mismatch current-effective-difficulty
    set last-performance perf
    set last-autonomous-performance perf

    update-skills-self current-requirements current-activated-indices
    update-dependency-state false

    set pop-hybrid-sum (pop-hybrid-sum + perf)
    set pop-ai-sum (pop-ai-sum + ai-reliability)
    set pop-human-sum (pop-human-sum + perf)
  ]
end

to-report decide-ai-use [effort]
  if not ai-available? [ report false ]
  if ai-off-now? [ report false ]

  let adjusted-prob p-ai

  ;; optional effort modulation: harder tasks create more temptation to delegate
  set adjusted-prob clamp01 (
    adjusted-prob
    + effort-ai-sensitivity * (effort - 0.5)
    + dependency-use-sensitivity * dependency-level
  )

  report (random-float 1 < adjusted-prob)
end

to-report compute-mismatch [skills reqs]
  let total 0
  let j 0
  while [j < length skills] [
    let gap (item j reqs - item j skills)
    if gap > 0 [ set total (total + gap) ]
    set j j + 1
  ]
  report total / length skills
end

to-report compute-effort [mismatch eff-diff]
  report ((lambda-m * mismatch) + (lambda-c * eff-diff))
end

to-report compute-autonomous-performance [mismatch eff-diff]
  report clamp01 (1 - autonomous-mismatch-penalty * mismatch - autonomous-difficulty-penalty * eff-diff)
end

to update-skills-ai [reqs active-idx]
  let newskills skill-vector
  let effective-alpha-ai (alpha-ai * (1 - dependency-learning-penalty * dependency-level))
  set effective-alpha-ai max list 0 effective-alpha-ai

  foreach active-idx [ j ->
    let old item j newskills
    let r item j reqs
    let updated (old + effective-alpha-ai * (1 - old) * r)
    set newskills replace-item j newskills (clamp01 updated)
  ]
  set skill-vector newskills
end

to update-skills-self [reqs active-idx]
  let newskills skill-vector
  foreach active-idx [ j ->
    let old item j newskills
    let r item j reqs
    let updated (old + alpha-self * (1 - old) * r)
    set newskills replace-item j newskills (clamp01 updated)
  ]
  set skill-vector newskills
end

to apply-atrophy [active-idx]
  let newskills skill-vector
  let j 0
  while [j < length newskills] [
    let old item j newskills
    let decay atrophy-delta
    if member? j active-idx [
      set decay (atrophy-delta * 0.25)
    ]
    if not member? j active-idx [
      set decay (atrophy-delta * 1.0)
    ]
    set newskills replace-item j newskills (clamp01 (old - decay))
    set j j + 1
  ]
  set skill-vector newskills
end

to maybe-run-perturbation-probe
  if remainder ticks pert-probe-interval = 0 [
    set probe-now? true
    set probe-type "perturbed"

    let probe-diff clamp01 (current-difficulty + perturbation-probe-boost + random-perturbation perturbation-amplitude)

    ask turtles [
      let mismatch compute-mismatch skill-vector current-requirements
      let perf compute-autonomous-performance mismatch probe-diff
      set pop-qh-pert-sum (pop-qh-pert-sum + perf)
      set pop-qh-pert-count (pop-qh-pert-count + 1)
    ]
  ]
end

to maybe-run-novelty-probe
  if remainder ticks novelty-probe-interval = 0 [
    set probe-now? true
    set probe-type "novel"

    let fam choose-family true
    let active-idx activated-indices-for-family fam
    let reqs generate-requirements active-idx
    let diff clamp01 (0.35 + random-float 0.5 + novelty-difficulty-boost)

    ask turtles [
      let mismatch compute-mismatch skill-vector reqs
      let perf compute-autonomous-performance mismatch diff
      set pop-qh-novel-sum (pop-qh-novel-sum + perf)
      set pop-qh-novel-count (pop-qh-novel-count + 1)
    ]
  ]
end

to reset-population-accumulators
  set pop-hybrid-sum 0
  set pop-human-sum 0
  set pop-ai-sum 0
  set pop-usage-count 0

  set pop-qh-eval-sum 0
  set pop-qh-pert-sum 0
  set pop-qh-novel-sum 0

  set pop-qh-eval-count 0
  set pop-qh-pert-count 0
  set pop-qh-novel-count 0
end

to update-global-metrics
  set mean-skill mean [mean skill-vector] of turtles

  if any? turtles [
    set mean-productivity pop-hybrid-sum / count turtles
    set ai-usage-rate pop-usage-count / count turtles
  ]

  ;; Q_H evaluation from AI-off windows or AI-unavailable phases
  if (ai-off-now? or (current-phase = 1) or (current-phase = 3)) [
    ask turtles [
      let mismatch compute-mismatch skill-vector current-requirements
      let perf compute-autonomous-performance mismatch current-effective-difficulty
      set pop-qh-eval-sum (pop-qh-eval-sum + perf)
      set pop-qh-eval-count (pop-qh-eval-count + 1)
    ]
  ]

  if pop-qh-eval-count > 0 [
    set mean-qh pop-qh-eval-sum / pop-qh-eval-count
  ]

  if pop-qh-pert-count > 0 [
    set mean-qh-pert pop-qh-pert-sum / pop-qh-pert-count
  ]

  if pop-qh-novel-count > 0 [
    set mean-qh-novel pop-qh-novel-sum / pop-qh-novel-count
  ]

  ;; approximate HCDR from successive evaluation snapshots
  if pop-qh-eval-count > 0 [
    ifelse last-ai-off-qh = nobody
      [
        set last-ai-off-qh mean-qh
        set last-eval-tick ticks
      ]
      [
        let dt max (list 1 (ticks - last-eval-tick))
        set current-hcdr ((mean-qh - last-ai-off-qh) / dt)
        set last-ai-off-qh mean-qh
        set last-eval-tick ticks
      ]
  ]

  ;; derived collaboration metrics
  let qha mean-productivity
  let qh mean-qh
  let qa ai-reliability

  if qha > 0 [
    set dependency-ratio qa / qha
    set hri 1 - dependency-ratio
  ]

  if max (list qh qa) > 0 [
    set cai-star ((qha - max (list qh qa)) / (max (list qh qa)))
  ]
  accumulate-export-window
end

to update-dependency-state [used-ai?]
  if used-ai? [
    set dependency-level clamp01 (dependency-level + dependency-build-rate)
  ]
  if not used-ai? [
    set dependency-level clamp01 (dependency-level - dependency-recovery-rate)
  ]
end


to-report clamp01 [x]
  if x < 0 [ report 0 ]
  if x > 1 [ report 1 ]
  report x
end

to-report mean-skill-group [g]
  if any? turtles with [group-id = g] [
    report mean [mean skill-vector] of turtles with [group-id = g]
  ]
  report 0
end

to-report mean-qh-group [g]
  if any? turtles with [group-id = g] [
    report mean [last-autonomous-performance] of turtles with [group-id = g]
  ]
  report 0
end

to-report mean-qha-group [g]
  if any? turtles with [group-id = g] [
    report mean [last-performance] of turtles with [group-id = g]
  ]
  report 0
end

to-report mean-ai-use-group [g]
  if any? turtles with [group-id = g] [
    report mean [ifelse-value last-used-ai? [1] [0]] of turtles with [group-id = g]
  ]
  report 0
end

to-report mean-mismatch-group [g]
  if any? turtles with [group-id = g] [
    report mean [last-mismatch] of turtles with [group-id = g]
  ]
  report 0
end

to-report mean-effort-group [g]
  if any? turtles with [group-id = g] [
    report mean [last-effort] of turtles with [group-id = g]
  ]
  report 0
end

to-report mean-novelty
  if any? turtles [
    report mean [novelty-score] of turtles
  ]
  report 0
end

to-report mean-novelty-group [g]
  if any? turtles with [group-id = g] [
    report mean [novelty-score] of turtles with [group-id = g]
  ]
  report 0
end

to-report mean-novelty-group-1
  report mean-novelty-group 1
end

to-report mean-novelty-group-2
  report mean-novelty-group 2
end

to-report mean-novelty-group-3
  report mean-novelty-group 3
end

to-report safe-export-mean [x]
  if export-count > 0 [ report x / export-count ]
  report 0
end

to-report final-cai-star
  report safe-export-mean export-cai-sum
end

to-report final-dependency-ratio
  report safe-export-mean export-d-sum
end

to-report final-hri
  report safe-export-mean export-hri-sum
end

to-report final-hcdr
  report safe-export-mean export-hcdr-sum
end

to-report final-mean-qh
  report safe-export-mean export-qh-sum
end

to-report final-mean-qh-pert
  report safe-export-mean export-qh-pert-sum
end

to-report final-mean-qh-novel
  report safe-export-mean export-qh-novel-sum
end

to-report final-mean-skill
  report safe-export-mean export-skill-sum
end

to-report final-mean-qha
  report safe-export-mean export-qha-sum
end

to-report final-ai-usage-rate
  report safe-export-mean export-aiuse-sum
end

to-report final-mean-skill-group-1
  report safe-export-mean export-skill-g1-sum
end

to-report final-mean-skill-group-2
  report safe-export-mean export-skill-g2-sum
end

to-report final-mean-skill-group-3
  report safe-export-mean export-skill-g3-sum
end

to-report final-mean-qh-group-1
  report safe-export-mean export-qh-g1-sum
end

to-report final-mean-qh-group-2
  report safe-export-mean export-qh-g2-sum
end

to-report final-mean-qh-group-3
  report safe-export-mean export-qh-g3-sum
end

to-report final-mean-qha-group-1
  report safe-export-mean export-qha-g1-sum
end

to-report final-mean-qha-group-2
  report safe-export-mean export-qha-g2-sum
end

to-report final-mean-qha-group-3
  report safe-export-mean export-qha-g3-sum
end

to-report final-mean-ai-use-group-1
  report safe-export-mean export-aiuse-g1-sum
end

to-report final-mean-ai-use-group-2
  report safe-export-mean export-aiuse-g2-sum
end

to-report final-mean-ai-use-group-3
  report safe-export-mean export-aiuse-g3-sum
end

to-report final-mean-novelty-group-1
  report safe-export-mean export-novelty-g1-sum
end

to-report final-mean-novelty-group-2
  report safe-export-mean export-novelty-g2-sum
end

to-report final-mean-novelty-group-3
  report safe-export-mean export-novelty-g3-sum
end

to-report count-group-1
  report count turtles with [group-id = 1]
end

to-report count-group-2
  report count turtles with [group-id = 2]
end

to-report count-group-3
  report count turtles with [group-id = 3]
end

to-report mean-pai
  report mean [p-ai] of turtles
end
@#$#@#$#@
GRAPHICS-WINDOW
9
10
481
483
-1
-1
14.061
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
1161
299
1355
332
num-agents
num-agents
100
1000
1000.0
10
1
individual
HORIZONTAL

SLIDER
1161
345
1356
378
alpha-self
alpha-self
0.01
0.1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
1161
395
1358
428
alpha-ai
alpha-ai
0.00001
0.01
0.00105
0.00001
1
NIL
HORIZONTAL

SLIDER
1161
446
1357
479
atrophy-delta
atrophy-delta
0.00001
0.005
0.00441
0.00001
1
NIL
HORIZONTAL

PLOT
609
14
1122
288
Experiment
Time (ticks)
Performance / Skill
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"global-q-h" 1.0 0 -16777216 true "" "Plot mean-qh"
"global-q-ha" 1.0 0 -5298144 true "" "Plot mean-productivity"
"cat-star" 1.0 0 -4079321 true "" "Plot cai-star"

MONITOR
1161
36
1327
81
Q_H
mean-qh
17
1
11

MONITOR
1160
89
1326
134
C AI*
cai-star
17
1
11

MONITOR
1161
143
1329
188
D (dependency ratio)
dependency-ratio
17
1
11

MONITOR
1161
196
1331
241
HCDR
current-hcdr
17
1
11

BUTTON
52
619
162
654
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
53
664
166
698
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
610
295
1126
512
Mean skill
Time (Ticks)
QH
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Minimal AI" 1.0 0 -14439633 true "" "Plot mean-skill-group 2"
"Mixed reliance" 1.0 2 -11221820 true "" "plot mean-skill-group 3"
"Full delegation" 1.0 0 -2674135 true "" "plot mean-skill-group 1"

PLOT
1372
702
1887
918
Mean QH
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Minimal AI" 1.0 0 -14439633 true "" "plot mean-qh-group 2"
"Mixed reliance" 1.0 0 -12345184 true "" "plot mean-qh-group 3"
"Full delegation" 1.0 0 -2674135 true "" "plot mean-qh-group 1"

PLOT
1372
932
1890
1132
Mean QHA
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"Minimal AI" 1.0 0 -14439633 true "" "plot mean-qha-group 2"
"Mixed reliance" 1.0 0 -12345184 true "" "plot mean-qha-group 3"
"Full delegation" 1.0 0 -2674135 true "" "plot mean-qha-group 1"

PLOT
1375
61
2003
211
AI usage
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"Minimal AI" 1.0 0 -15040220 true "" "plot mean-ai-use-group 2"
"Mixed reliance" 1.0 2 -8990512 true "" "plot mean-ai-use-group 3"
"Full delegation" 1.0 0 -2674135 true "" "plot mean-ai-use-group 1"

SLIDER
1370
301
1579
334
k-skills
k-skills
5
50
6.0
1
1
NIL
HORIZONTAL

SLIDER
1369
344
1579
377
perturbation-amplitude
perturbation-amplitude
0
1
1.0
0.001
1
NIL
HORIZONTAL

SLIDER
1374
384
1575
417
ai-reliability
ai-reliability
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
1372
424
1581
457
effort-ai-sensitivity
effort-ai-sensitivity
0
1
0.75
0.25
1
NIL
HORIZONTAL

SLIDER
1624
304
1834
337
lambda-m
lambda-m
0
2
0.9
0.1
1
NIL
HORIZONTAL

SLIDER
1623
346
1835
379
lambda-c
lambda-c
0
2
0.7
0.1
1
NIL
HORIZONTAL

SLIDER
1855
305
2100
338
autonomous-difficulty-penalty
autonomous-difficulty-penalty
0
2
0.6
0.1
1
NIL
HORIZONTAL

SLIDER
1857
347
2107
380
autonomous-mismatch-penalty
autonomous-mismatch-penalty
0
2
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
1857
390
2106
423
perturbation-probe-boost
perturbation-probe-boost
0
0.5
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
1857
438
2107
471
novelty-difficulty-boost
novelty-difficulty-boost
0
1
0.54
0.01
1
NIL
HORIZONTAL

MONITOR
1160
243
1331
288
HRI
hri
17
1
11

PLOT
229
684
1284
1049
Novelty adaptation plot
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Minimal AI" 1.0 0 -14439633 true "" "Plot mean-novelty-group 2"
"Mixed Reliance" 1.0 2 -11221820 true "" "Plot mean-novelty-group 3"
"Full delegation" 1.0 0 -5298144 true "" "Plot mean-novelty-group 1"

SLIDER
2153
305
2391
338
dependency-learning-penalty
dependency-learning-penalty
0
1
0.34
0.01
1
NIL
HORIZONTAL

SLIDER
2153
348
2350
381
dependency-build-rate
dependency-build-rate
0
1
0.11
0.01
1
NIL
HORIZONTAL

SLIDER
2157
400
2381
433
dependency-recovery-rate
dependency-recovery-rate
0
1
0.05
0.05
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="paper-main-20-seeds" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= total-length</exitCondition>
    <metric>final-cai-star</metric>
    <metric>final-dependency-ratio</metric>
    <metric>final-hri</metric>
    <metric>final-hcdr</metric>
    <metric>final-mean-qh</metric>
    <metric>final-mean-qh-pert</metric>
    <metric>final-mean-qh-novel</metric>
    <metric>final-mean-skill</metric>
    <metric>final-mean-qha</metric>
    <metric>final-ai-usage-rate</metric>
    <metric>final-mean-skill-group-1</metric>
    <metric>final-mean-skill-group-2</metric>
    <metric>final-mean-skill-group-3</metric>
    <metric>final-mean-qh-group-1</metric>
    <metric>final-mean-qh-group-2</metric>
    <metric>final-mean-qh-group-3</metric>
    <metric>final-mean-qha-group-1</metric>
    <metric>final-mean-qha-group-2</metric>
    <metric>final-mean-qha-group-3</metric>
    <metric>final-mean-ai-use-group-1</metric>
    <metric>final-mean-ai-use-group-2</metric>
    <metric>final-mean-ai-use-group-3</metric>
    <metric>final-mean-novelty-group-1</metric>
    <metric>final-mean-novelty-group-2</metric>
    <metric>final-mean-novelty-group-3</metric>
    <metric>count-group-1</metric>
    <metric>count-group-2</metric>
    <metric>count-group-3</metric>
    <metric>mean-pai</metric>
    <metric>final-ai-usage-rate</metric>
    <metric>final-mean-ai-use-group-1</metric>
    <metric>final-mean-ai-use-group-2</metric>
    <metric>final-mean-ai-use-group-3</metric>
    <enumeratedValueSet variable="run-seed">
      <value value="101"/>
      <value value="102"/>
      <value value="103"/>
      <value value="104"/>
      <value value="105"/>
      <value value="106"/>
      <value value="107"/>
      <value value="108"/>
      <value value="109"/>
      <value value="110"/>
      <value value="111"/>
      <value value="112"/>
      <value value="113"/>
      <value value="114"/>
      <value value="115"/>
      <value value="116"/>
      <value value="117"/>
      <value value="118"/>
      <value value="119"/>
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-window">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k-skills">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-self">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-ai">
      <value value="0.00105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perturbation-amplitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ai-reliability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-ai-sensitivity">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lambda-m">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lambda-c">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="autonomous-difficulty-penalty">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="autonomous-mismatch-penalty">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perturbation-probe-boost">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="novelty-difficulty-boost">
      <value value="0.54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dependency-learning-penalty">
      <value value="0.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dependency-build-rate">
      <value value="0.11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dependency-recovery-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="atrophy-delta">
      <value value="0.004"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dependency-use-sensitivity">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-mode">
      <value value="&quot;full&quot;"/>
      <value value="&quot;minimal&quot;"/>
      <value value="&quot;mixed&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="optimization_atrophy_mixed_reduction" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>final-cai-star</metric>
    <metric>final-dependency-ratio</metric>
    <metric>final-hri</metric>
    <metric>final-hcdr</metric>
    <metric>final-mean-qh</metric>
    <metric>final-mean-skill</metric>
    <metric>final-mean-qha</metric>
    <metric>final-ai-usage-rate</metric>
    <metric>count-group-1</metric>
    <metric>count-group-2</metric>
    <metric>count-group-3</metric>
    <metric>mean-pai</metric>
    <enumeratedValueSet variable="run-seed">
      <value value="101"/>
      <value value="102"/>
      <value value="103"/>
      <value value="104"/>
      <value value="105"/>
      <value value="106"/>
      <value value="107"/>
      <value value="108"/>
      <value value="109"/>
      <value value="110"/>
      <value value="111"/>
      <value value="112"/>
      <value value="113"/>
      <value value="114"/>
      <value value="115"/>
      <value value="116"/>
      <value value="117"/>
      <value value="118"/>
      <value value="119"/>
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-window">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k-skills">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-self">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-ai">
      <value value="0.00105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perturbation-amplitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ai-reliability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-ai-sensitivity">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lambda-m">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lambda-c">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="autonomous-difficulty-penalty">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="autonomous-mismatch-penalty">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perturbation-probe-boost">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="novelty-difficulty-boost">
      <value value="0.54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dependency-learning-penalty">
      <value value="0.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dependency-build-rate">
      <value value="0.11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dependency-recovery-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dependency-use-sensitivity">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-mode">
      <value value="&quot;mixed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="atrophy-delta">
      <value value="0.004"/>
      <value value="0.0035"/>
      <value value="0.003"/>
      <value value="0.0025"/>
      <value value="0.002"/>
      <value value="0.0015"/>
      <value value="0.001"/>
      <value value="5.0E-4"/>
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
