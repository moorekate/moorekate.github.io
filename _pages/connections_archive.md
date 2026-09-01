---
layout: page
title: Connections Archive
permalink: /connections/archive/
nav: false
---

<div class="connections-archive">
  {% for game in site.data.connections %}
    <div class="connections-game">
      <h3>Game #{{ game.game }}</h3>
      <p>{{ game.date }} · {{ game.mistakes }} mistakes</p>

      <div class="connections-grid">
        {% for row in game.rows %}
          <div class="connections-row">{{ row }}</div>
        {% endfor %}
      </div>
    </div>
  {% endfor %}
</div>