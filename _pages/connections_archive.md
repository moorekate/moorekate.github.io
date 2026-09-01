---
layout: page
title: Connections Archive
permalink: /connections/archive/
nav: false
---

<div class="row">
  {% for game in site.data.connections %}
    <div class="col-sm-6 col-md-4 mb-4">
      <div class="card h-100">
        <div class="card-body">
          <h5 class="card-title">Game #{{ game.game }}</h5>
          <p class="card-text">
            {{ game.date }}<br>
            {{ game.mistakes }} mistakes
          </p>

          {% for row in game.rows %}
            <div style="font-size: 1.4rem; line-height: 1.3;">
              {{ row }}
            </div>
          {% endfor %}
        </div>
      </div>
    </div>
  {% endfor %}
</div>