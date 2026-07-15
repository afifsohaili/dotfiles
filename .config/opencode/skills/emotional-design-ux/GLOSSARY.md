# Glossary — Emotional Design for UX

The domain model for designing experiences that use emotion to drive behavior. This is the disclosed reference for [`emotional-design-ux`](SKILL.md).

**Bold terms** in any definition are themselves defined in this glossary; find them by their heading.

## Leading Words

### Emotional Arc

The journey of feeling you take a user through, from first impression to committed action. Every screen is a beat in this arc. A strong arc has three acts: **Introduction** (the hook), **Climax** (the peak), and **Conclusion** (the close). The arc is not a feature map; it is a feeling map. If you can read the arc aloud and the emotional build is unmistakable, the arc is sound.

### Aha Moment

A personal stat or realization that reframes the user's own behavior in a surprising way. It is the emotional detonation of the **Introduction**. The best aha moments are derived from the user's own inputs (e.g., hours per day → years over a lifetime). It must land within 60 seconds of the flow starting.

### Mirroring

Repeating the user's own words back to them in a later screen. The mechanism is not flattery; it is the illusion of personalization. When a user sees their own answer reflected, they feel heard, and the experience feels bespoke rather than templated. Mirroring should happen after every significant user input.

### Loss Aversion

The psychological principle that people prefer avoiding losses to acquiring equivalent gains. In onboarding, it means that a user who has invested 10 minutes of emotional and temporal capital is more likely to convert than a user who hit the paywall in 30 seconds. Longer onboardings convert better because of loss aversion, not despite it. **Ethical guardrail**: only invoke loss aversion when the threat is genuine.

### Dopamine

A neurotransmitter triggered by anticipation of reward. In UX, it is the engine of curiosity and the "what's new" response. A **dopamine tease** arouses the user with a mystery or promise, but the promise must be fulfilled or the tease becomes **clickbait**.

## The Neuroscience Model

### Trigger

An external event in your design (a screen, a message, an animation) that impacts the user's senses and starts the emotional chain.

### Schemas

The network structures the brain uses to remember and encode information. When a user sees something familiar, their schema fires instantly and triggers the associated emotion. When they see something unfamiliar, they must build a new schema, which costs conscious effort and glucose. Design for existing schemas when possible; when you must introduce novelty, do it deliberately to trigger emotion, not accidentally to trigger confusion.

### Emotion (Pre-Conscious)

What happens when the mind prepares the body to deal with a threat or an opportunity before the person is consciously aware. The body reacts first — facial expressions change, heart rate shifts, muscles tense. This is why emotion is so powerful in decision-making: it hijacks the rational system before the user can intervene.

## Emotional Quadrants

A two-dimensional framework for classifying emotional states by energy (arousal) and valence (positive/negative). Every screen should map to one quadrant.

### Optimistic Quadrant

High energy, positive valence. The user feels excited, in control, empowered. **Mechanism**: give something good. This is where value propositions, dopamine teases, and rewards live. The default state for conversion design.

### Stressed Quadrant

High energy, negative valence. The user feels alarmed, pressured, urgent. **Mechanism**: remove something bad. This is where honest urgency and genuine loss aversion live. Ethical only when the threat is real and the solution genuinely removes it. Pressure without a real solution is manipulation.

### Pessimistic Quadrant

Low energy, negative valence. The user feels helpless, despairing, disempowered. **Mechanism**: give something bad. **Avoid this quadrant.** A straight-up pessimistic message celebrates despair and does not motivate. If you must use a negative state, pair it with an **efficacy message**.

### Content Quadrant

Low energy, positive valence. The user feels calm, loyal, satisfied. **Mechanism**: remove something good. **Avoid this quadrant for conversion.** This is where loyal customers live — they are happy and do not want to move. If you need to upsell, you must first move them out of contentment into a different quadrant.

### Efficacy Message

A statement that tells the user what they can do about a problem. It is the required partner to any pessimistic or negative state. Without efficacy, a negative message is just helplessness. Example: "Your stats are down" (pessimistic) → "Here's the report that shows why" (efficacy).

## Pillars

### Introduction

The first act of the **emotional arc**. Its job is to make the user feel understood and to build the case for why they should pay. Built from four principles: frame the problem/solution fast, deliver an **aha moment**, ask reflective questions, and **mirror** the answers back.

### Climax

The second act of the **emotional arc**. It is the most exhilarating part of the flow. The user must experience the core feature, not be told about it. The climax is also where you capture the **emotional peak** — the review ask, the commitment ask, or the gamified win.

### Conclusion

The third act of the **emotional arc**. Its job is to close the deal. It summarizes the journey, anchors the price against a familiar expense, extracts a final commitment, and closes with **social proof**.

## Psychological Levers

### Dopamine Trigger / Curiosity

The lever that arouses anticipation of reward and energizes the user. It is the "what's new" response, the mystery, the tease. The core of value proposition design. **Rule**: every dopamine trigger must deliver on its promise or it becomes clickbait.

### Social Proof

The principle that people look to the behavior of others to determine their own. In UX, it manifests as testimonials, review counts, user numbers, and ratings. It is most powerful at the point of decision (paywall, download) because it reduces perceived risk.

### Commitment / Consistency

The principle that people want their actions to align with their stated identity and past commitments. In UX, it is extracted by asking users to state their commitment level explicitly (e.g., "How committed are you?"). Once a user says "very committed," they are more likely to behave consistently with that label.

### Comparison Anchoring

The cognitive bias where people judge a value by comparing it to a nearby reference point. In pricing, it means comparing your subscription cost to a trivial daily expense ("one coffee a month"). The user's brain anchors on the familiar expense and evaluates your price as trivial by association.

### Gamification / Streak

The use of game mechanics (points, badges, streaks, progress bars) to create dopamine hits and visual momentum. In emotional design, the streak is not the goal; the emotional peak it creates is. The streak screen should immediately precede the ask (review, commitment, paywall).

### Gratitude / Appreciation

The lever that makes the user feel important and special before a request is made. It is a genuine positive emotion that primes the next action. Distinct from flattery (a fake compliment), gratitude is real and specific. Example: "Thank you for your review — it means a lot to us."

### Scarcity / Urgency

The principle that limited availability increases perceived value. In UX, it manifests as countdown timers, limited-time offers, or "spots remaining" counters. **Ethical guardrail**: only use when the scarcity is genuine. Fake urgency destroys trust.

### Belonging

The emotion of being part of a tribe or community. In UX, it is triggered by language like "join 10,000 others" or testimonials that feature people like the user. Belonging reduces the friction of adoption by making the choice feel like joining rather than buying.

## Personality Dimensions

A simplified neurobiological model for matching emotional tone to audience. Three dimensions, each with two poles. Most people lean toward one pole on each dimension.

### Anchor vs Seeker

- **Anchor** (serotonin-dominant): traditional, risk-avoiding, routine-liking, task-focused. Responds to safety, step-by-step processes, familiar patterns.
- **Seeker** (dopamine-dominant): novelty-seeking, high-energy, risk-taking, dislikes routine. Responds to curiosity, "what's new," excitement, adventure.

### Feeler vs Thinker

- **Feeler** (oxytocin/estrogen-dominant): emotional, creative, compassionate, empathetic, polite. Responds to stories, images of people, emotional language, gratitude.
- **Thinker** (testosterone-dominant): analytical, decisive, disciplined, blunt. Responds to data, flowcharts, diagrams, logical arguments, evidence.

### Reactive vs Low Reactive

- **Low Reactive** (low norepinephrine/cortisol): calm, relaxed, slow to react, less intense emotions. Needs stronger stimuli or more explicit value to move.
- **Highly Reactive** (high norepinephrine/cortisol): stressed, anxious, strong emotional responses. Responds to pressure and urgency, but can be easily overwhelmed.

## Patterns

### Socratic Onboarding

An onboarding structure that asks the user questions they already know the answer to, then uses those answers to build the case for conversion. The user convinces themselves; the app merely listens and reflects.

### Echo Screen

A screen that repeats the user's input verbatim with a validating framing. Example: "You said you struggle with focus. We hear you." The echo screen is the atomic unit of **mirroring**.

### Commitment Ladder

A sequence of asks that escalate from micro-commitments ("Do you have 5 minutes?") to macro-commitments ("How committed are you?"). Each affirmative answer increases the probability of the next. The ladder is a structural application of **commitment / consistency**.

### Dopamine Tease

A design element that arouses curiosity with a mystery or "what's new" promise. The user must believe something good is inside. **Rule**: every tease must deliver on its promise. Undelivered teases become **clickbait** and train users to ignore future messages.

### Pessimistic-Optimistic Pair

A design pattern that shows a negative state and a positive state simultaneously. Example: a before/after image. The negative creates the problem; the positive provides the solution. Requires an **efficacy message** — the user must know what they can do about it. This is not a pressure tactic; it is a problem-solution frame.

### Gratitude Prime

A moment of genuine appreciation before making a request. It makes the user feel important and special, which primes them to say yes. Distinct from flattery; it is a real emotional state, not a fake compliment. Example: "Thank you for your review — you're the best."

### Status Quo Cost

A design pattern that makes the future cost of inaction feel worse than the cost of changing. It asks the user to imagine the future if nothing changes, then immediately offers a real path forward. It is an application of **loss aversion** and requires an **efficacy message** to avoid slipping into the pessimistic quadrant.

### Confident Closer

A tone pattern that keeps the experience calm, generous, and non-desperate. Users read the designer's energy before the copy; neediness raises guards, while confidence lowers them. It is the emotional counterpart to every ask in the conclusion.

## Ethical Terms

### Clickbait

A dopamine tease that does not deliver on its promise. Big curiosity triggers with no payoff. Clickbait trains users to distrust your messages and damages long-term engagement. The cure is simple: only tease what you can deliver.

### Degrading Opt-Out

Language that makes the user feel stupid or inferior for declining an offer. Example: "No thanks, I don't like saving money." This triggers extreme hostility in many users and is explicitly excluded from ethical emotional design. The alternative is a respectful decline: "No thanks, not right now."

## Emotional States

### Visceral

The immediate, pre-cognitive emotional reaction to a design (color, typography, imagery). It is the first 50 milliseconds. Visceral design is about first impressions and gut feelings.

### Behavioral

The emotion experienced during the actual use of a product (flow, frustration, delight). It is about the felt quality of interaction — is it smooth, responsive, rewarding?

### Reflective

The emotion experienced after use, when the user thinks back on the experience (pride, regret, satisfaction). It is about the story the user tells themselves about the product. Reflective design is where **loss aversion** and **commitment** live.
