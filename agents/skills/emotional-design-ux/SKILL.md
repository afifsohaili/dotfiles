---
name: emotional-design-ux
description: Use when your UX needs to convert by making users feel understood, hopeful, or seen before they decide. Use for emotional design, onboarding, paywalls, conversion flows, and user journey emotional arcs. Use when the features are clear but the experience still feels flat.
license: MIT
compatibility: opencode
metadata:
  category: ux-design
---

# Emotional Design for UX

Most UX explains the product. Great UX explains the user.

People don't wake up looking for the perfect feature. They wake up tired of a problem. They choose with emotion first, then use logic to feel better about it. If your screens only list features, you've already lost them.

This skill helps you design the emotional arc of a flow so every screen makes the user feel understood, not just informed. Every screen is a beat in a story. The goal is not to convince them — it's to help them see clearly, then let them convince themselves.

Used well, it builds trust. Used poorly, it becomes manipulation. The guardrails here are intentional: resonant, never coercive.

**Leading word**: *emotional arc* — the journey of feeling you take a user through, from first impression to committed action.

## When to use this skill

- The user wants "better onboarding" or "higher conversion"
- The user mentions making users feel something (trust, urgency, belonging, hope)
- The user is designing a paywall, signup flow, or first-run experience
- The user wants to apply psychology or behavioral economics to UX
- The user wants to match copy or design to an audience's personality type

## How emotion works in UX

Emotion is pre-conscious. The brain classifies a stimulus before the user is aware, and the body reacts. The chain is:

**Trigger → Senses → Schemas → Emotion → Behavior**

- **Schemas** are the brain's learned categories. Positive schemas trigger positive emotion; threat schemas trigger negative emotion.
- **Cognitive effort drains glucose.** The more conscious thinking a screen requires, the more energy it drains, and the more likely the user drops.

Design implication: match your UI to schemas the user already knows (conventions, familiar patterns). Novelty triggers emotion; confusion triggers abandonment.

## The buyer's rules

A good emotional arc works because it respects how people actually decide. The same rules show up in sales, onboarding, and product copy. Read them as a quick sanity check for any flow you're designing:

| Rule | What the user feels | Where it lives in this skill |
|------|--------------------|-----------------------------|
| **People buy with emotion first, logic later** | "I need to feel this before I justify it" | Introduction, climax, then conclusion |
| **People move away from pain more than toward pleasure** | "I want out of this problem now" | Stressed quadrant, loss aversion |
| **Sales is about helping them see clearly** | "I reached this conclusion myself" | Socratic onboarding, mirroring, echo screens |
| **Objections are usually fear** | "I'm scared it won't work for me" | Social proof, safety signals, gratitude prime |
| **People act when staying the same feels worse than changing** | "If I do nothing, this gets worse" | Status quo cost pattern |
| **Detachment sells** | "You're not desperate for my money" | Calm confident tone, no guilt trips |
| **Price objections are value objections** | "I'm not sure this is worth it" | Comparison anchoring, aha moment |

Use this table as a second opinion. If your flow feels flat, check which rule it is ignoring.

## The emotional quadrants

Map every screen to one quadrant. Each quadrant has a different motivational mechanism:

| Quadrant | Energy | Valence | Mechanism | When to use |
|----------|--------|---------|-----------|-------------|
| **Optimistic** | High | Positive | Give something good | Value props, core features, rewards, dopamine teases |
| **Stressed** | High | Negative | Remove something bad | Honest urgency, genuine scarcity, real threats |
| **Pessimistic** | Low | Negative | Give something bad | **AVOID** — despair, helplessness without action |
| **Content** | Low | Positive | Remove something good | **AVOID for conversion** — this is loyalty, not action |

**Key rule**: pessimistic messages alone do not motivate. If you use a negative state, always pair it with an efficacy message (what the user can do about it). A straight-up pessimistic message is a celebration of despair.

## The Three Pillars

Every emotional design flow follows a story structure. Three pillars:

1. **Introduction** — Frame the problem, give an *aha moment*, ask reflective questions, mirror the user's answers back
2. **Climax** — Let the user try the core feature, hit the emotional peak, capture a review or commitment at the peak
3. **Conclusion** — Summarize the journey, anchor price against something familiar, extract a commitment, close with social proof

Each pillar is built from principles, not screens. The number of screens is a function of how much emotional legwork each principle needs.

## Step 1: Diagnose the emotional gap

Before designing anything, identify what the user currently feels versus what you need them to feel.

**Completion criterion**: A single sentence describing the emotional transformation (e.g., "From anxious and distracted to calm and in control")

Questions to ask the user or yourself:
- What is the user's emotional state before they open this flow?
- What emotion unlocks the behavior you want?
- What emotion kills conversion?
- Is the gap visceral (instant reaction), behavioral (during use), or reflective (after use)?

## Step 2: Map the emotional arc

Design the flow as a story with three acts. Do not design features; design feelings.

**Completion criterion**: A 3-act outline where each act has a target emotion, one principle from the pillars, and a quadrant.

### Act 1 — Introduction (the hook)

The user arrives confused. Your job is to make them feel understood.

**Principles:**

- **Frame the problem and solution in the first 3 screens.** Confusion kills conversions. The user must know exactly what they're getting into. Example: "Do you ever feel like your phone gets more attention than God?" → "PrayerLock helps you put God first."
- **Deliver an *aha moment* in under 60 seconds.** Hit them with a personal stat or realization that reframes their own behavior. Example: "On average, you'll use your phone for 16 years over your lifetime."
- **Ask reflective questions.** The questions are not for you to learn about the user. They are for the user to convince themselves they need this. Example: "What does a thriving faith look like to you?"
- **Mirror their answers back.** In the next screen, repeat exactly what they told you. This makes them feel heard and makes the experience feel personalized. Example: "You said you want to put God first before your phone. Let's build that plan."
- **Use dopamine teases.** Arousing curiosity is a core motivator. "What's new in 2.0?" or a mystery element can drive action. But every tease must deliver on its promise. Undelivered teases become clickbait and train users to ignore you.

> **Tactic — longer onboardings convert better.** A 15-minute onboarding can 5x conversion vs. a 3-minute one. The mechanism is **loss aversion**: by the time they hit the paywall, they've invested emotionally and temporally. They'd rather not lose that investment than win a new app.

### Act 2 — Climax (the peak)

This is the most exhilarating part of the experience. The user must feel delight, surprise, or power.

**Principles:**

- **Let the user try the core feature during the flow.** Do not explain; let them experience. Example: ask two questions, then generate a personalized prayer.
- **Capture the emotional peak.** If you want a review, ask at the peak — right after a gamified win (streak, fire animation, first success). Not too early (they're still confused) and not too late (the peak has faded). Reviews are social proof for future users and ASO fuel.
- **Show gratitude before the ask.** A moment of appreciation ("Thank you for your review — you're the best") makes the user feel important and special before you make a request. This is not flattery; it is a genuine positive emotion that primes the next action.

### Act 3 — Conclusion (the close)

The user is warm. Now close the deal.

**Principles:**

- **Summarize the journey.** Repeat where they are, where they want to go, and how you get them there. Repetition is not a bug; young users have short attention spans and need to be told the same thing multiple times.
- **Anchor the price against something familiar.** If you have a free trial, tell them the app is paid upfront, then compare the cost to a daily ritual. Example: "One coffee a month for spiritual peace." This makes the price feel trivial.
- **Extract a commitment.** Ask them directly how committed they are. Example: "How committed are you to making this future happen?" 95% will answer "extremely" or "very." If they answer low, have custom copy for that branch.
- **Close with social proof.** A final screen of testimonials, ratings, or user counts before the paywall.

> **Tactic — the paywall is less important than the journey.** Do not over-optimize the paywall itself. The only must-have is a notification reminder one day before the trial ends.

## Step 3: Pick the psychological lever

Each screen should run one lever. Do not mix levers on the same screen; it dilutes the emotional punch.

| Lever | What it does | When to use |
|-------|-------------|-------------|
| **Dopamine trigger / curiosity** | Arouses anticipation of reward; energizes the user | Early in flow, "what's new," mystery, teases |
| **Loss aversion** | Motivates by removing a genuine threat or bad outcome | Mid-flow, before paywall; only when the threat is real |
| **Social proof** | Makes users feel safe because others have done it | End of flow, paywall screen, app store page |
| **Commitment / consistency** | Makes users align their actions with their stated identity | After they answer a reflective question |
| **Aha moment** | Reframes the user's own behavior in a surprising way | Early, within 60 seconds |
| **Mirroring** | Makes the user feel heard and seen | After any user input |
| **Comparison anchoring** | Makes a price feel small by comparing to a daily expense | Price reveal, paywall |
| **Gamification / streak** | Creates a dopamine hit and visual progress | Climax, before review ask |
| **Gratitude / appreciation** | Makes the user feel important before a request | Before any ask (review, share, commitment) |
| **Scarcity / urgency** | Creates honest fear of missing out | Only when the scarcity is genuine |
| **Belonging** | Makes the user feel part of a tribe | Community testimonials, "join X others" |

## Step 4: Design the screens as emotional beats

For each screen, specify:
- **Emotion target**: What should the user feel on this screen?
- **Quadrant**: Which emotional quadrant is this?
- **Lever**: Which psychological lever is running?
- **User action**: What do they do? (tap, answer, scroll, wait)
- **Mirroring**: Does this screen reflect something the user said earlier?
- **Completion signal**: What tells you this screen worked? (answer chosen, time spent, scroll depth)

**Completion criterion**: A screen-by-screen emotional arc where every screen has an emotion target, quadrant, and lever, with no two adjacent screens using the same lever.

## Step 5: Verify emotional coherence

Read the arc from start to finish. Does the emotion build? Is there a clear peak? Does the conclusion feel earned?

**Completion criterion**: The arc passes the "feel test" — reading it aloud, the emotional journey makes sense and the peak is unmistakable.

## Step 6: Match your emotional tone to the audience

Your own personality biases leak into your copy. If you are a Feeler-Anchor (emotional, conservative) writing for a Thinker-Seeker (analytical, adventurous) audience, you will miss them.

**Three dimensions to match:**

- **Anchor vs Seeker**: Anchors want safety, tradition, step-by-step. Seekers want novelty, excitement, "what's new."
- **Feeler vs Thinker**: Feelers respond to stories, people, emotional language. Thinkers respond to data, diagrams, logical flow.
- **Reactive vs Low Reactive**: Reactive people respond to pressure and urgency. Low reactive people need stronger stimuli or more explicit value.

**Completion criterion**: A one-sentence profile of the target audience personality and a check that the copy is written for them, not for you.

## Ethical Guardrails

This skill is for designing experiences that resonate, not for manipulating vulnerable people. The following are **excluded** and must not be used:

- **Degrading opt-out language.** ("No thanks, I'm an idiot.") This triggers extreme hostility and damages trust.
- **Guilt trips after the user has decided to leave.** If someone unsubscribes, let them go with a respectful outro.
- **Fake urgency or false scarcity.** Countdowns and "only X left" are only ethical when they are true.
- **Celebrating despair.** Pessimistic-only messaging (helplessness without an efficacy message) does not motivate and harms the user.
- **Undelivered dopamine teases.** Clickbait trains users to distrust you.

**Rule of thumb**: if the tactic would make you feel insulted, trapped, or helpless, do not use it.

## Failure modes to watch for

| Smell | Fix |
|-------|-----|
| Onboarding explains features instead of building a case | Reframe every screen as "why should I pay you?" |
| All screens feel the same | Distribute levers and quadrants; never use the same lever twice in a row |
| The user is not asked anything | Add reflective questions; silence is a conversion killer |
| The paywall is over-optimized but the journey is weak | Move effort upstream; the paywall is a formality |
| The flow is short (<5 minutes) for a paid product | Lengthen it; loss aversion needs investment |
| Review ask is at the end or at the start | Move it to the emotional peak — right after a win |
| Pessimistic message without efficacy | Every negative state must be paired with "what you can do about it" |
| Copy written for the designer's personality | Profile the audience's personality dimensions and match the tone |
| Dopamine tease that doesn't deliver | Ensure the promise is fulfilled or it becomes clickbait |

## Reference: Emotional design patterns

### Pattern — The Socratic Onboarding
Ask questions the user already knows the answer to, then use their answers to build the case. The user convinces themselves. The app merely listens.

### Pattern — The Lifetime Stat
Calculate a cumulative stat from a single behavioral input. Example: hours per day → years over a lifetime. The shock creates the aha moment.

### Pattern — The Echo Screen
After any user input, show a screen that repeats their input verbatim with a validating framing. Example: "You said you struggle with focus. We hear you."

### Pattern — The Coffee Anchor
When revealing price, compare it to a trivial daily expense. The user's brain anchors on the familiar expense and judges your price as trivial by association.

### Pattern — The Streak Peak
Show a gamified win (streak, badge, animation) immediately before asking for a review or commitment. The dopamine from the win transfers to the ask.

### Pattern — The Commitment Ladder
Ask for micro-commitments early ("Do you have 5 minutes?") and escalate to macro-commitments late ("How committed are you?"). Each yes makes the next yes more likely.

### Pattern — The Dopamine Tease
Arouse curiosity with a "what's new" or mystery element. The user must believe something good is inside. But you must deliver on the promise — undelivered teases become clickbait and train users to ignore you.

### Pattern — The Pessimistic-Optimistic Pair
Show a negative state and the positive state simultaneously. Example: a before/after image. The negative creates the problem; the optimistic provides the solution. This is not the same as a pressure tactic — it is a problem-solution frame that requires an efficacy message.

### Pattern — The Gratitude Prime
Before making any ask (review, share, commitment), express genuine appreciation. Gratitude makes the user feel important and special, which primes them to say yes. This is distinct from flattery; it is a real emotional state, not a fake compliment.

### Pattern — The Status Quo Cost
Make the future cost of doing nothing feel worse than the cost of changing. Ask the user to imagine a future where nothing changes: "If we're in the same place six months from now, will that be okay?" This is not pessimism; it is a mirror that pairs the current pain with an efficacious solution. It only works when the flow immediately offers a real path forward.

### Pattern — The Confident Closer
The more you need the sale, the more users feel it. A calm, confident tone sells better than urgency, pressure, or desperation. This does not mean being cold; it means you are sure the product is worth it. The user reads your energy before they read your copy. If your screen feels needy, their guard goes up. If your screen feels generous, their guard drops.

## Credits

This skill is synthesized from:
- The onboarding psychology breakdown by Mao Baron (PrayerLock) on Starter Story Build
- The emotional design strategies webinar by Brian Cugelman (AlterSpark / ConversionXL)
- The social-selling psychology breakdown by Dawn Flaherty on TikTok
- Principles from affective design, behavioral economics, and neuroscience
