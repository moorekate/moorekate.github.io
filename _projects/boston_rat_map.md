---
layout: page
title: Rodent Tracker + Web App
description:
  <strong>APIs · Python · AWS · Spatial</strong><br>
  An end-to-end data pipeline that incrementally ingests Boston 311 rodent reports and serves them through an interactive MapLibre application. 
img: assets/img/rat-map-capture.png
importance: 4
# category: 
related_publications: false # removes references
# redirect: https://moorekate.github.io/boston-rat-map/
# hide_learn_more: true
card_footer: See the web app!
---
<div class="rat-map-embed">
  <iframe
    src="https://moorekate.github.io/boston-rat-map/"
    width="100%"
    height="700"
    style="border: 0;"
    loading="lazy"
    allowfullscreen>
  </iframe>
</div>

<a href="https://moorekate.github.io/boston-rat-map/"
   class="btn btn-primary"
   target="_blank"
   rel="noopener noreferrer">
  Launch in Fullscreen
</a>

# Project Overview

I originally built this web app for an interesting reason: I’m not from Boston, and urban rodent problems are basically unheard of where I grew up in the southeastern U.S. (where you’re much more likely to encounter a snake in your home, rather than a rodent). Imagine my surprise when I moved to Boston for college and discovered just how large and persistent the rodents are. In apartment after apartment, I endured rodents in the walls, my kitchen, or even popping out of toilets ([I wish I was joking](https://www.boston.com/news/local-news/2024/01/31/rats-boston-in-toilets/)).

Circa 2021, I was completing my undergraduate capstone at Northeastern University, which asked me to identify a problem that could be improved using location-enabled data and build a tailored data solution. At the time, I was dealing with a mouse problem in my Fenway studio and had contacted the City of Boston’s Inspectional Services Department (ISD) after my landlord failed to provide adequate pest control. When an inspector came to my apartment, I noticed they carried a handheld device where they entered information under my case ID, including photos, location data, descriptions, and more. That data had to be going *somewhere*, right?

The idea was right in front of me. Could I surface public ISD case data to help Boston renters uncover rodent problems before making a binding, expensive housing decision? The deliverable was simple: a public web app where anyone could search any Boston address and see all past and present rodent-related 311 cases associated with that address. Before signing a lease, you'd be able to quickly check whether the building or unit has a history of rodent problems-- information landlords and brokers generally never disclose to potential tenants. 

The data I needed was available through the [Analyze Boston](https://data.boston.gov/) open data portal as annual datasets of Boston 311 records that receive new incremental data daily, and could be accessed either programmatically through the CKAN API or by downloading individual CSV files.

Way back when, the first version of this project pulled those annual CSVs and combined them into a master dataset using Python, which I then uploaded to ArcGIS Online to handle hosting, geocoding, visualization, and popup configuration automatically. It worked, but updates required manually rerunning Python scripts and uploading, and I simply didn't know enough at the time to establish more complex architecture. Not to mention my project lived on the Northeatern ArcGIS Enterprise account, which stopped publicly hosting my project sometime in 2024. 

Earlier this year, I came back to my rat map and realized it was the perfect excuse to rebuild the same little idea as a more complete data engineering system: one that could automatically ingest new records, process data incrementally, regenerate the master dataset, and move data between distributed pieces of architecture without my intervention. It was also an opportunity to move away from managed tooling and demonstrate my years of experience building and hosting systems myself from the last half-decade. 

The result is what you see now!

## How it works

The application is backed by an automated pipeline that incrementally retrieves new rodent reports from the City's open data API, stores the historical dataset in S3 in parquet format, and generates a GeoJSON serving artifact to power the web application, which renders and handles interactions using the MapLibre open-source library. 

The pipeline starts with the City of Boston's CKAN API. A scheduled AWS EventBridge job triggers an AWS Lambda function, which runs predefined Python requesting new rodent-related records from the API rather than rebuilding the entire dataset on every run. The raw records are written to Amazon S3 as Parquet files. Apache Iceberg provides a table layer over those files. Instead of treating the Parquet objects as a collection of unrelated files, Iceberg maintains table metadata and snapshots that allow the dataset to behave more like a database table. This makes incremental ingestion and future changes to the dataset easier to manage while keeping the underlying data in object storage.

Once new data has been loaded, the pipeline processes the records needed by the application and regenerates a GeoJSON representation of the current whole dataset. That GeoJSON is the serving layer for the map. The frontend is built with MapLibre GL JS. When someone opens the application, MapLibre loads the generated GeoJSON and renders the individual rodent reports spatially. Address search and map interactions happen in the browser, including the ability to inspect reports around a particular location. 

The overall flow looks roughly like:

<div class="text-center my-4">
  <img
    src="/assets/img/brm-arch-diagram.png"
    alt="Boston Rat Map data pipeline architecture"
    style="max-height: 550px; width: auto; max-width: 100%;"
  >
</div>


## Why build it this way?

A map this small doesn't *need* this much infrastructure. That's part of the point.

The original project answered a specific question. The rebuilt version became a sandbox for thinking about the engineering problems behind continuously updated datasets: incremental ingestion, idempotency, storage formats, table management, orchestration, failure recovery, and separating analytical storage from the format actually consumed by an application.

It also reflects the intersection of two parts of my background. I started my career working with GIS and spatial data, but increasingly moved toward building the systems that collect, transform, and serve data. Rebuilding the rat map gave me a way to revisit an old project through the lens of my current engineering work. And, admittedly, building a tiny production-ish data platform to answer the question **"how many rats have been reported near this apartment?"** is much more fun than another generic ETL demo.

This web app actually got me my first job out of college, where I served as the resident spatial analyst for the City of Boston within the Department of Innovation & Technology. I worked with ISD and other departments to modernize the architecture for reporting and responding to--you guessed it--rodent requests in the City of Boston. I also had many opportunities to be involved in public policy and operations initiatives across all the City's various departments, saw Prince William and Princess Kate when they came for the Green New Deal celebration, and constructed the City of Boston's first-ever combined dataset all City-owned, operated, or leased land parcels. But ask me for more details about my time with the City another day! 