#!/bin/bash
# backup.sh - Script to backup the MongoDB database

# Use the MONGO_URI environment variable or default to local messageboard database
: "${MONGO_URI:=mongodb://localhost:27017/messageboard}"

# Create a timestamped directory for the backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="/backup/mongodb_backup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Run mongodump to backup the database
mongodump --uri="$MONGO_URI" --out="$BACKUP_DIR"
