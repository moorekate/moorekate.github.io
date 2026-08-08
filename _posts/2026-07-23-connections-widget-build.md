---
layout: post
title: Building a Custom Jekyll Widget for al-folio
date: 2026-07-23
description: "How I built a widget for posting daily NYT Connections results on my al-folio website."
tags: tag
categories: category
featured: false # pins post as feature to top of blog page
---

## Overview ##

When spinning up my first personal website this summer, I made the decision to host it on gitpages with a remote Jekyll theme. I've actually really enjoyed working with Jekyll, and I think it's YAML-based formatting is simple enough for most people to pick up easily. 

One thing I really wanted to try was adding my own custom functions. I play the New York Times Connections game every day (not to brag, but my solve rate is 88%). My family even hosts a massive group chat where we send our results every day, so we can roast one another and commiserate over particularly difficult puzzles. 

## Repo ##

## Tutorial ##

The styling for the al-folio remote theme doesn't actually sit in your repository, but instead Jekyll is pulling HTMl/CSS from the theme gem/repository during the jekyll build step. Remote themes like al-folio are defined in your website's root config.yml file, and when cloning the al-folio theme repo as a template, you'll end up with a _modules/ file that contains the al-folio-core framework inherited from the remote theme. 

There's a few things in here that might be helpful to orient yourself to:
- _modules/al-folio-core/_layouts
    + contains html defined in liquid 
    + 
- _modules/al-folio-core/_sass
- _modules/al-folio-core/assets/css/main.scss






