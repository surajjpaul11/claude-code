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

## 2026-04-10 — Smart Hold v15+v16: Bear Market Regime Gate
Fixed GOOGL 5y underperformance (-41.37% → -13.28% vs B&H). Root cause: GOOGL's 2022 bear entries happened at VIX 20-27 (below v14 VIX gate). Fix: double declining MA gate blocks entries when SMA200 20-bar slope < threshold AND SMA50 5-bar slope < -1%. ATR-adaptive threshold: -2.0% for stocks (ATR%>1.3), -2.5% for ETFs. All 6 backtests (3 symbols × 2y/5y) improved or unchanged vs v14.
Branch: smart-hold-v16

## 2026-04-10 — Smart Hold v17: vix_recovery_below_sma entry signal
Created new entry signal that fills gap in fast_reentry: fires after vix_accel exits when price is still below the exit SMA but fast EMA has reversed up for 2+ bars. GOOGL improved +6.35pp vs_BH (93.75% → 100.10%, total return 197.73% → 204.08%). SPY/QQQ neutral (fires same bar as ema_momentum). Signal is architecturally mutually exclusive with fast_reentry by the SMA condition.
Branch: smart-hold-v17

## 2026-04-10 — Smart Hold Run #18: peak_gain_trail exit signal (REVERTED)
Attempted to close the GOOGL T4 trailing stop gap (peaked at +27.8%, exited at +10.95%) via a peak-gain based trailing exit. Signal designed to fire when position peaked at 20-45% gain and price drops 12% from peak. GOOGL REGRESSED -5.39%: fired on T1 (initial_entry) prematurely at 167.28 vs baseline 170.29. T4 gap-down eliminated timing advantage. Signal file retained but disabled in registry. No push. Key insight: gap-down exits in GOOGL mean peak-trail fires at same bar/price as ATR stop. SMA slope guard suggested as potential future fix.
Branch: N/A (not pushed)

## 2026-04-10 — Smart Hold Optimizer Run #19 (REVERTED)
Created `ema_sma_cross_exit` exit signal (EMA/SMA death cross + negative MACD on 8%+ gain trades, 20+ bars held).
Signal regressed SPY -2.92% and QQQ -7.82% (GOOGL unchanged). Reverted. Root cause: early exit triggered cascading failed re-entries.
Signal file retained in exits/ but disabled in registry.py. Logged in optimizer_log.md.
Branch: N/A (reverted, no push). Current branch: smart-hold-v17.

## 2026-04-10 — smart-hold-v18 (Run #20)
Kept false_breakdown_reclaim with 1-bar SMA reclaim (was 2-bar). QQQ +65.42%→+66.17% (+0.75%), GOOGL/SPY unchanged. Explored ma_breakdown_recovery (below-SMA re-entry after ma_breakdown) but reverted: GOOGL regressed -14.26% due to multi-leg corrections being indistinguishable from false breakdowns. Branch: smart-hold-v18.

## 2026-04-10 — smart-hold-v18 (Run #22, Ceiling Analysis)
2y optimization ceiling reached. Confirmed v18 baseline (GOOGL +204.08%, SPY +63.60%, QQQ +66.17%). Only actionable gap is QQQ T8+T9 (ema_momentum fires after macd_reversal_exit into false recovery) — ~+2pp QQQ-only. Cannot meet 2+ symbol improvement threshold. No changes made. Full ceiling analysis in optimizer_log.md. Next: expand to 5y window or new symbols (AAPL/MSFT/NVDA). Branch: smart-hold-v18 (unchanged).

## 2026-04-10 — smart-hold-v19 (Run #23, 5y Window)
Switched to 5y window. Identified 2022 bear market as primary damage: GOOGL had 13 losing trades in 2022 totaling -38.54%. Root cause: bear_regime_gate SMA50 secondary condition (< -0.01) was too strict — GOOGL dead-cat bounces only flatten SMA50 to -0.4% to -0.7%, bypassing the gate. Fix: ATR-adaptive SMA50 threshold (-0.003 for high-vol stocks like GOOGL, keep -0.01 for ETFs to avoid cascade). Results: GOOGL 5y -13.28% → +9.34% (+22.62pp), SPY +39.82% → +40.51% (+0.69pp), QQQ +34.50% → +35.62% (+1.12pp). All 3 symbols improve. Zero 2y regressions. Branch: smart-hold-v19.

## 2026-04-11 — Reversal Channel Breakout Strategy (v1)
New standalone strategy: detects downtrend → uptrend reversals using HH+HL state machine. Entry on first Higher Low after first Higher High following confirmed descending channel. Exits: 8x ATR trail, reversal_failed, EOD. Results (2y): PLTR +455.50% vs B&H +460.68% (near-perfect match, single trade Jul'24-Jan'26 @ $26→$147). SNDK +658.75% (late entry Sep'25). WULF +212.54% (2 trades, +344.65% catching 2025 bull run @ $4→$19). Key fix: min_swings=1 (was 2) so downtrend confirms with 2 pivots instead of 3 — lets strategy re-engage faster after a failed reversal.
Branch: hyperbolic-runner-v2 (commit 4a31e32)

## 2026-04-10 — smart-hold-v20 (Run #24, 5y Window)
Identified ma_reclaim as the dominant signal for 2022 bear losses across all 3 symbols: 6 total ma_reclaim losses across GOOGL/SPY/QQQ, ALL occurred while price was BELOW SMA200 (bear market dead-cat bounces). The only winning ma_reclaim (GOOGL Sep 2024) had price +4.53% ABOVE SMA200. Added ATR-adaptive SMA200 guard: for high-vol stocks (ATR% > 1.3) only, require close > SMA200 before ma_reclaim fires. ETFs exempt (blocking causes cascade to ema_momentum 1-5 days later with worse outcomes). Results: GOOGL 5y +9.34% → +34.75% (+25.41pp major), SPY/QQQ neutral. 2y: GOOGL -0.30pp (rounding), SPY/QQQ neutral. Branch: smart-hold-v20.
