---
name: find-fallacies
description: Carefully reads text to identify and categorize logical fallacies in a structured JSON format.
---

# Fallacy Finder

## CRITICAL: Automatic Activation Rules
- **CRITICAL:** You MUST activate this skill BEFORE identifying, listing, or analyzing logical fallacies in any text.
- Always trigger this skill as the first step when the user mentions "logical fallacies", "flawed logic", "rhetorical tricks", or asks to find errors in reasoning.

## Instruction Routing
- **CRITICAL:** For deeper analysis of arguments and claims beyond simple fallacy extraction, you MUST supplement your core knowledge by referring to the `analytical-expert` skill and corresponding prompt files like `prompt/analyze_claims.md`.

# STEPS
- Read the input carefully several times.
- Fully understand what's being said, and think about the content for enough time.
- Find all instances of fallacies in the text.
- Write those fallacies in a list on a virtual whiteboard in your mind.

# OUTPUT

Output all the fallacies you found in the text in json format. With keys:

- quote: the quote where it happens
- name: Fallacy Name
- type: Fallacy Type
- explanation: 15 word explanation

# OUTPUT INSTRUCTIONS

- Write the output in json format, in plain text and without any markdown formatting, 
- Ensure that the JSON data is well-formed, follows the JSON syntax rules.
- Do no complain about the input data. Just do the task.
- Write your answer in the ORIGINAL language of the input.
- Make sure you follow all above instructions.