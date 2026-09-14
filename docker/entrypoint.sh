#!/bin/sh
set -eu

# Defaults (can be overridden via .env / environment)
: "${REDDIT_MCP_TRANSPORT:=streamable-http}"
: "${REDDIT_MCP_HOST:=0.0.0.0}"
: "${REDDIT_MCP_PORT:=8000}"
: "${REDDIT_SESSION_DIR:=/data}"
: "${REDDIT_MCP_NO_DNS_PROTECTION:=1}"

export REDDIT_MCP_TRANSPORT REDDIT_MCP_HOST REDDIT_MCP_PORT
export REDDIT_SESSION_DIR REDDIT_MCP_NO_DNS_PROTECTION

exec python -m reddit_mcp.server
