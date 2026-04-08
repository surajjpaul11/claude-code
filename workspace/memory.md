# Claude Memory

Everything Claude remembers across conversations for this workspace.

---

## Project Context

**Active project:** tradingview-mcp — a TradingView MCP server with multiple trading strategies, backtesting engine, and live trade execution (Bitget + Alpaca).

**Strategies built (newest first):** Smart Hold (VIX-based buy & hold), Curved Channels (polynomial regression), EMA 21, Enhanced Straight Lines, Straight Line trendline break, VWMA 17, Higher Highs MTF, Buy and Protect, Volatility Harvester.

User is iterating on and fine-tuning trading logic across multiple strategies. Work typically happens on feature branches off main.

---

## Workflow Preferences

### Commit & Branch Workflow
Commit to GitHub each time a new strategy is added or significant code changes are made. Create a new branch for this work rather than committing directly to existing branches.

**Why:** User wants changes tracked and pushed regularly so nothing is lost and work is reviewable.

### Clone Workflow
Always clone git repos into a subfolder named after the project, not directly into the current directory.
Example: `git clone <url> tradingview-mcp` instead of `git clone <url> .`

**Why:** User had to manually move files into a container/subfolder after a flat clone polluted the workspace root.
