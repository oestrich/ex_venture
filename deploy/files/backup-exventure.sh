#!/bin/bash

sudo -u postgres pg_dump exventure > /opt/backups/exventure-`date +%FT%R`.sql
