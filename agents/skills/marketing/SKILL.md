---
name: marketing
description: Router for marketing, growth, and GTM work. Use for SEO, AI search (AEO/GEO) and LLM citations, ASO, paid ads and ad creative, landing-page CRO, signup and onboarding, paywalls, copywriting or copy editing, lifecycle and cold email, SMS, launch, pricing and offers, positioning, referrals, churn, community, PR, partnerships, analytics, attribution, conversion tracking, competitor and customer research, and marketing plans. Fires on vague asks too ("my SEO is bad", "improve conversions", "how do I market this"). Loads one matching playbook from the local library on demand.
---

# Marketing

A router, not a playbook. It names every playbook in the local marketing library and tells you which one to open. Read the matching playbook in full before doing the work.

`$LIB` = `~/.agents/marketing-skills/skills`. Every bare name below means `$LIB/<name>/SKILL.md`.

## Route

1. Read `.agents/product-marketing.md` in the repo if it exists. Playbooks assume it for ICP, positioning, and voice.
2. Missing, and the task needs positioning → run `product-marketing` first; it writes that file.
3. Open the playbook that matches the task. Two areas in play (ad copy for a landing page) → open both.
4. A playbook's `references/` files load only where that playbook names them. Never read the library wholesale, and never infer a playbook from its name.

## Playbooks

### Foundation

| Playbook | Fires on |
| --- | --- |
| product-marketing | ICP, positioning, brand voice; writes `.agents/product-marketing.md` |

### SEO, AI search, content

| Playbook | Fires on |
| --- | --- |
| seo-audit | rankings, indexation, technical and on-page audit, local SEO |
| ai-seo | AI Overviews, LLM citations, llms.txt, AEO/GEO, agent-readable site |
| site-architecture | page hierarchy, navigation, URL structure, internal links |
| programmatic-seo | pages at scale, template/location/comparison pages |
| schema | JSON-LD, structured data, rich results |
| content-strategy | topic clusters, editorial calendar, what to write |
| aso | App Store and Play listing audit, keywords, screenshots |
| link-building | backlinks, link gap, unlinked mentions, outreach |
| directory-submissions | Product Hunt, SaaS/AI/MCP directories, backlink lists |
| free-tools | calculators, graders, lead-gen tools, engineering as marketing |

### Conversion

| Playbook | Fires on |
| --- | --- |
| cro | landing, pricing, and feature pages; forms; "this page isn't converting" |
| signup | registration and trial activation friction, dropoff |
| onboarding | activation, aha moment, empty states, time-to-value |
| emotional-design-ux | emotional arc of onboarding, paywall, or conversion flow (`~/.agents/skills/emotional-design-ux/SKILL.md`) |
| popups | exit intent, modals, banners, sticky bars |
| paywalls | in-app upgrade screens, feature gates, trial expiry |
| ab-testing | experiment design, ICE, significance, experiment program |

### Copy and channels

| Playbook | Fires on |
| --- | --- |
| copywriting | new page, hero, CTA, ad, or product copy |
| copy-editing | editing existing copy, point edits, de-slopping |
| emails | welcome, nurture, lifecycle, drip sequences |
| cold-email | outbound, follow-ups, deliverability, LinkedIn cadences |
| social | LinkedIn/X/TikTok/IG posts, calendars, social listening |
| sms | SMS/MMS/WhatsApp flows, TCPA, A2P 10DLC |
| video | AI video, programmatic video, demo and ad video |
| image | AI images, hero and social graphics, WebP, OG images |

### Paid and measurement

| Playbook | Fires on |
| --- | --- |
| ads | Google/Meta/LinkedIn campaigns, targeting, bidding, ROAS |
| ad-creative | bulked headlines, RSA, static/UGC/motion ad variants |
| analytics | GA4, GTM, event tracking, tracking plan |
| conversion-tracking | pixels, CAPI, Enhanced Conversions, server-side |
| attribution | first vs last touch, MMM, incrementality, CAC truth |

### Growth and retention

| Playbook | Fires on |
| --- | --- |
| referrals | referral and affiliate programs, reviews, advocacy |
| churn-prevention | cancel flows, save offers, dunning, win-back |
| community-marketing | Discord/Slack/forum/subreddit growth, advocates |
| lead-magnets | ebooks, checklists, templates, gated content |
| co-marketing | partner campaigns, integration marketing |
| influencer-marketing | creator deals, sponsorships, disclosure, ROI |
| events | webinars, conferences, booths, event follow-up |
| marketing-loops | recurring agent-run marketing workflows |
| prospecting | lead lists, ICP fit, enrichment, verification |

### Sales and GTM

| Playbook | Fires on |
| --- | --- |
| revops | MQL/SQL, lead scoring and routing, CRM hygiene |
| sales-enablement | decks, one-pagers, battle cards, demo scripts |
| launch | Product Hunt, waitlists, launch checklist, release notes |
| pricing | tiers, packaging, freemium, willingness to pay |
| competitors | vs/alternative pages, comparison asset audit |
| competitor-profiling | competitor dossier from their URLs |
| public-relations | press, journalist pitches, podcast prep, crisis comms |
| offers | bonus stacks, guarantees, urgency, high-ticket offers |

### Strategy

| Playbook | Fires on |
| --- | --- |
| marketing-ideas | stuck, needs tactics or growth ideas |
| marketing-psychology | biases, framing, social proof, nudges |
| customer-research | interviews, surveys, VOC, JTBD, review mining |
| reverse-engineer-marketing | how a company grew, dated log, plays to copy |
| marketing-plan | full AARRR plan, TAM/SAM/SOM, fCMO deliverable |
| marketing-council | multiple advisor perspectives on one question |

## Rules

- Playbook wins on method. This router wins on which playbook.
- Claims need evidence. No invented benchmarks, traffic, or revenue numbers.
- Playbooks that name partner tools disclose them; keep that disclosure in the output.
- Library is read-only here. Update it from its own git checkout; the dotfiles commit pins the version.
