---
title: Dunegeons & Dragons
layout: post
category: dnd
permalink: /dnd/index.html
---

## The Lost Mine of Phandelver

  * Characters meet in city of Neverwinter.
  * Hired by Dwarf friend, *Gundren Rockseeker*, to escort wagon to
    *Phandalin*.
  * Gundren gone ahead to Phandalin w/ a warrior, *Sildar Hallwinter*, for
    business..
  * Characters will be payed 10gp each by owner of *Barthen's Provisions* in
    Phandalin when wagon is delivered safely to that trading post.

[Player Overviews](/dnd/player-overviews.html)


## Session Log

{% for session in site.categories.dnd reversed %}
  * {{ session.date | date: "%Y-%m-%d" }} [{{ session.title }}]({{ session.url }})
{% endfor %}

