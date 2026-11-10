# Ethan Coskay · Professional Website

My professional portfolio website for Cornell's ENGRC 3025: Creating & Communicating Your Digital Professionalism. It's built to answer one question for recruiters and engineers: *what kind of engineer is Ethan, and what proves it?*

**Live:** https://3025.mingly.ai

## What's on the site

| Page | What it shows |
| --- | --- |
| [Home](https://3025.mingly.ai/) | Identity, headline facts, three paths into the evidence (Technical, Leadership, Professional), featured case study, contact |
| [About](https://3025.mingly.ai/about/) | Career direction, how I engineer, the teams I work best on, Cornell CS + AI coursework, tools |
| [Certificates](https://3025.mingly.ai/certificates/) | Cornell degree and Selander Center leadership certification and badges, Palantir, Columbia, IBM and Wharton certificates, each with a verification link |
| [Cornell XR](https://3025.mingly.ai/cornell-xr/) | Software Lead role, smart-glasses OCR to LaTeX pipeline, and face-match threshold validation with measured error rates |
| [Hackathons/Awards](https://3025.mingly.ai/hackathons-awards/) | OneCompute, 3rd place of 1,200+ at the Microsoft Global Intern Week Hackathon |
| [Leadership](https://3025.mingly.ai/leadership/) | CS 1110 teaching assistant, Selander Center program, Cornell XR, Alpha Sigma Phi |
| [Projects](https://3025.mingly.ai/projects/) | Filterable case studies |
| [Work Experience](https://3025.mingly.ai/work-experience/) | Microsoft, Davidson Kempner, the LinkedIn – Cornell Bowers CIS and Helmes: problem, what I owned, result |

### Case studies

- **[Engineering AI-Assisted Tagging at Scale](https://3025.mingly.ai/projects/tagging-at-scale/)** (Multimodal Content 1): an interactive case study of my Microsoft internship work on duplicate-aware tagging across review sets of up to 5 million documents. It includes a tag-propagation demo, a clickable system map, and a reliability toggle showing the fallback path when data is missing.
- **[CareerRadar](https://3025.mingly.ai/projects/careerradar/)**: a live job-monitoring platform ([app](https://careerradar.mingly.ai/login), [code](https://github.com/EcSky19/CareerRadar)) that scans 150+ career pages daily and scores new postings 0–100 against a candidate's profile.
- **[Investment Intelligence System](https://3025.mingly.ai/projects/investment-intelligence/)**: six analysis engines whose evidence is reconciled, not averaged, into explainable research.
- **[OneCompute](https://3025.mingly.ai/projects/onecompute/)**: an opt-in compute network built from idle devices, with a step-through of a job's lifecycle.

## Design

- **Two reading speeds.** Recruiters get the key facts in under a minute. Engineers can open diagrams, steps and decisions for deeper detail.
- **Multiple modes.** Original diagrams and charts (visual), concise writing (linguistic), and navigation, filters and interactive elements (spatial).
- **Accessible.** Semantic HTML, keyboard support, visible focus, alt text, light and dark themes, reduced-motion support, and layouts that work at phone width.
- **Confidential details protected.** Work is shown through generalized, original diagrams. No employer code, screenshots or internal documents.

## Structure

```
site/              The website (plain HTML, CSS and JavaScript, no build step)
  assets/          Stylesheet, script, headshot, resume PDF, certificate images
  projects/        Case studies
install.sh         Publishes the site on the server
```
