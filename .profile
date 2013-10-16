#!/usr/bin/env bash
echo [trac] > env/conf/db.ini
echo database = $DATABASE_URL >> env/conf/db.ini
