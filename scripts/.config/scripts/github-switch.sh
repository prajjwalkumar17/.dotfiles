#!/usr/bin/env bash

# ========= CONFIG =========

WORK_NAME="prajjwalkumar17"
WORK_EMAIL="prajjwal.kumar@juspay.in"
WORK_USER="${WORK_USER:-prajjwalkumar17}"

BOT_NAME="bot4pk"
BOT_EMAIL="clawbot4pk@gmail.com"
BOT_USER="${BOT_USER:-bot4pk}"

REPO_NAME=$(basename -s .git `git config --get remote.origin.url 2>/dev/null`)

if [ -z "$REPO_NAME" ]; then
  REPO_NAME=$(basename "$PWD")
fi

WORK_REMOTE="git@github-work:${WORK_USER}/${REPO_NAME}.git"
BOT_REMOTE="git@github-personal:${BOT_USER}/${REPO_NAME}.git"

COMMAND=$1

if [ -z "$COMMAND" ]; then
  echo "Usage: ./git-switch.sh [init|work|bot]"
  exit 1
fi

# ========= INIT =========
if [ "$COMMAND" = "init" ]; then
  echo "Initializing repository..."

  if [ ! -d ".git" ]; then
    git init
  fi

  # Add both remotes
  git remote remove work 2>/dev/null
  git remote remove bot 2>/dev/null

  git remote add work "$WORK_REMOTE"
  git remote add bot "$BOT_REMOTE"

  # Default origin → work
  git remote remove origin 2>/dev/null
  git remote add origin "$WORK_REMOTE"

  git config user.name "$WORK_NAME"
  git config user.email "$WORK_EMAIL"

  echo "Initialized with WORK profile"
  exit 0
fi

# ========= SWITCH =========
if [ "$COMMAND" = "work" ]; then
  echo "Switching to WORK profile..."

  git config user.name "$WORK_NAME"
  git config user.email "$WORK_EMAIL"

  git remote set-url origin "$WORK_REMOTE"

elif [ "$COMMAND" = "bot" ]; then
  echo "Switching to BOT profile..."

  git config user.name "$BOT_NAME"
  git config user.email "$BOT_EMAIL"

  git remote set-url origin "$BOT_REMOTE"

else
  echo "Invalid command. Use init | work | bot"
  exit 1
fi

# ========= STATUS =========
echo "Current Identity:"
git config user.name
git config user.email

echo "Origin Remote:"
git remote get-url origin

echo "Done."
