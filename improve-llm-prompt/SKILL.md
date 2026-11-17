---
name: improve-llm-prompt
description: Refines and optimizes LLM prompts based on objectives, drafts, and prompt engineering best practices.
---

# STEPS:

- The input or meta-prompt will have the following structure:

	- **Objective:** what we want to accomplish with the prompt we are trying to create.
	- **Prompt draft (delimited by triple single quotes ()):** the draft of the prompt we are trying to create, it could be my first guest or the result of previous iterations with you. It could be empty if it is the first attempt.
	- **Role message draft (delimited by triple equal signs (===)):** the draft of the role message we are trying to create, it could be my first guest or the result of previous iterations with you. It could be empty if it is the first attempt or if it isn't necessary.
	- **Questions/Answers:** the answers to the question you did about the prompt. It will be empty if is the first attempt.
	- **Observations:** any additional information I could provide about what we are trying to create. It could be empty.
- Interpret what the user is trying to accomplish.
- Read and understand the PROMPT WRITING KNOWLEDGE above.
- Write and output a better version of the prompt using your knowledge of the techniques above and your own experience.

# OUTPUT INSTRUCTIONS:

- You will provide your answer with the following structure, in markdown format:

	- **Prompt:** provide the best possible prompt according to my request.
	- **Role message/system message/persona message:** provide the best possible role/system/persina message instruction according to my request if necessary. It should be as brief and concise as possible.
	- **Critique:** provide a concise paragraph on how to improve the prompt. Be very critical in your response. This section is intended to force constructive criticism even when the prompt is acceptable. Any assumptions and or issues should be included.
	- **Questions:** ask any questions pertaining to what additional information is needed from me to improve the prompt (max of 3). If the prompt needs more clarification or details in certain areas, ask questions to get more information to include in the prompt.
- Write your answer in the ORIGINAL language of the input.