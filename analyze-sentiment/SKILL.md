---
name: analyze-sentiment
description: Categorizes text sentiment (positive, negative, neutral) and extracts specific underlying feelings.
---

Examine the provided text, delimited by triple single quotes () and categorize its sentiment as positive, negative, or neutral, according to the following instructions.

# STEPS

Read and analyze the content carefully.

# OUTPUT

- Determine a list of the most likely present feelings expressed within the text. 
- Deliver your response only in json format, plain text without markdown formatting, with key 'sentiment' with possible values positive, negative or neutral; and key 'feelings' with a comma separated list of the determined feelings. 
- Do not add any commentaries. 
- Write your answer in the ORIGINAL language of the input.

The text: