---
title: "First Impressions of Exercism"
date: 2018-10-18T07:28:21-04:00
draft: false
---

Over the past two months, [Exercism](https://exercism.io) has proven to be a great tool for sharpening my Erlang skills.
It provides an accessible, low-overhead way to learn the standard build tools and best practices of a language, which is lacking from other online programming practice platforms focused solely on interview preparation.
Exercism has some limits, since the exercises are the same for every language, but feedback from mentors with deep knowledge of specific languages is invaluable.
The granularity of the feedback provides value to intermediate and expert programmers and truly sets Exercism apart from other platforms.
I would recommend Exercism to anyone with programming experience, but I wouldn't recommend it to a complete beginner as a first exposure to programming.

I went into Exercism with a solid understanding of Erlang and experience building some small solo side projects with it.
My ultimate goal is to contribute code to an open source Erlang project, so I wanted to see if Exercism could evaluate whether I'm following best practices and writing high-quality Erlang.

Exercism requires installation of its command line tool for downloading exercises and submitting solutions as well as the specific language's standard build tools.
The ability to develop solutions and run tests locally is a huge win for Exercism in my books, as I'm quite particular about my development environment.
I love that Exercism gives users this freedom, but I can see how a complete beginner may prefer jumping directly into an online editor, rather than trying to wrestle with setting up a development environment.
However, writing production code doesn't happen in an online editor and requires a solid understanding of build tools, so I see this as a big advantage.

Thus far, I have only worked on easy and medium difficulty problems.
The exercises are easy to grasp, and crafting algorithms for them hasn't yet gotten in the way of utilizing the language to write clear, concise code.
I initially found the first few exercises to be a bit too trivial to make for a beneficial learning experience, but I was proven wrong by the feedback I received.
It went into a perfect amount of depth while staying concise in addressing the common Erlang traps I initially fell into.
I had some great discussions about the differences between the `orelse`, `or`, and `;` operators, efficient ways to build and concatenate strings (in Erlang, strings are essentially syntactic sugar over lists of integers), and using function clauses for control flow.
These are things you can get by without knowing for a while but will surely come back to bite when working at production scale.

The first four or five exercises I completed went through a second iteration after feedback, and I learned way more than expected despite their simplicity.
Building good habits with a language and writing idiomatic code early on is challenging without someone more experienced looking over your code.
It's difficult to appreciate the importance of best practices until after you have a decent understanding of the language.
Exercism allows users to develop the right habits while learning a language, another way it distinguishes itself from other platforms.

Ultimately, Exercism's future will be defined by its mentors and maintainers.
Since it is a completely open platform, unlike its counterparts, contributing to language tracks and applying to become a mentor is easy.
This should continue to attract helpful, knowledgeable people to the community and keep the quality of interactions high.
Needless to say, Exercism is a great platform I intend to continue utilizing and contributing to.
