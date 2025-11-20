-- ============================================================================
-- Riot Games Intelligence Agent - Analytical Views
-- ============================================================================
-- Purpose: Curated views used by semantic layer & dashboards
-- ============================================================================

USE DATABASE RIOT_GAMES_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RIOT_GAMES_SI_WH;

-- ============================================================================
-- Player 360 View
-- ============================================================================
CREATE OR REPLACE VIEW V_PLAYER_360 AS
SELECT
    p.player_id,
    p.summoner_name,
    p.email,
    p.region,
    p.country,
    p.account_level,
    p.honor_level,
    p.ranked_tier,
    p.ranked_division,
    p.total_playtime_hours,
    p.account_status,
    p.player_segment,
    p.acquisition_channel,
    p.account_created_date,
    COUNT(DISTINCT m.match_id) AS total_matches,
    COUNT(DISTINCT CASE WHEN m.result = 'WIN' THEN m.match_id END) AS total_wins,
    COUNT(DISTINCT CASE WHEN m.result = 'LOSS' THEN m.match_id END) AS total_losses,
    ROUND(COUNT(DISTINCT CASE WHEN m.result = 'WIN' THEN m.match_id END)::FLOAT / NULLIF(COUNT(DISTINCT m.match_id), 0), 3) AS win_rate,
    SUM(pur.amount_usd) AS total_spending_usd,
    COUNT(DISTINCT pur.transaction_id) AS total_purchases,
    COUNT(DISTINCT pi.interaction_id) AS support_interactions,
    AVG(pi.sentiment_score) AS avg_sentiment_score,
    MAX(m.match_date) AS last_match_date,
    DATEDIFF('day', MAX(m.match_date), CURRENT_DATE()) AS days_since_last_match,
    p.created_at,
    p.updated_at
FROM RAW.PLAYERS p
LEFT JOIN RAW.MATCH_HISTORY m ON p.player_id = m.player_id
LEFT JOIN RAW.PURCHASES pur ON p.player_id = pur.player_id
LEFT JOIN RAW.PLAYER_INTERACTIONS pi ON p.player_id = pi.player_id
GROUP BY
    p.player_id, p.summoner_name, p.email, p.region, p.country,
    p.account_level, p.honor_level, p.ranked_tier, p.ranked_division,
    p.total_playtime_hours, p.account_status, p.player_segment,
    p.acquisition_channel, p.account_created_date, p.created_at, p.updated_at;

-- ============================================================================
-- Match Analytics View
-- ============================================================================
CREATE OR REPLACE VIEW V_MATCH_ANALYTICS AS
SELECT
    m.match_id,
    m.player_id,
    m.champion_id,
    c.champion_name,
    m.match_date,
    DATE_TRUNC('month', m.match_date) AS match_month,
    m.game_mode,
    m.queue_type,
    m.match_duration_seconds,
    m.result,
    m.kills,
    m.deaths,
    m.assists,
    CASE WHEN m.deaths = 0 THEN m.kills + m.assists ELSE (m.kills + m.assists)::FLOAT / m.deaths END AS kda_ratio,
    m.gold_earned,
    m.damage_dealt,
    m.damage_taken,
    m.vision_score,
    m.role_played,
    m.premade_team_size,
    m.player_rank_at_match,
    m.afk_flag
FROM RAW.MATCH_HISTORY m
JOIN RAW.CHAMPIONS c ON m.champion_id = c.champion_id;

-- ============================================================================
-- Purchase Analytics View
-- ============================================================================
CREATE OR REPLACE VIEW V_PURCHASE_ANALYTICS AS
SELECT
    pur.transaction_id,
    pur.player_id,
    pur.purchase_date,
    DATE_TRUNC('month', pur.purchase_date) AS purchase_month,
    pur.item_type,
    pur.item_name,
    pur.currency_type,
    pur.amount_usd,
    pur.amount_rp,
    pur.amount_be,
    pur.payment_method,
    pur.region,
    pur.purchase_channel,
    pur.promotion_applied,
    pur.refund_flag,
    p.player_segment,
    p.ranked_tier,
    p.account_level
FROM RAW.PURCHASES pur
JOIN RAW.PLAYERS p ON pur.player_id = p.player_id;

-- ============================================================================
-- Champion Performance View
-- ============================================================================
CREATE OR REPLACE VIEW V_CHAMPION_PERFORMANCE AS
SELECT
    c.champion_id,
    c.champion_name,
    c.role,
    c.difficulty,
    COUNT(DISTINCT m.match_id) AS total_matches_played,
    COUNT(DISTINCT m.player_id) AS unique_players,
    COUNT(DISTINCT CASE WHEN m.result = 'WIN' THEN m.match_id END) AS total_wins,
    ROUND(COUNT(DISTINCT CASE WHEN m.result = 'WIN' THEN m.match_id END)::FLOAT / NULLIF(COUNT(DISTINCT m.match_id), 0), 3) AS win_rate,
    AVG(m.kills) AS avg_kills,
    AVG(m.deaths) AS avg_deaths,
    AVG(m.assists) AS avg_assists,
    AVG(m.damage_dealt) AS avg_damage_dealt,
    COUNT(DISTINCT pur.transaction_id) AS total_skin_purchases
FROM RAW.CHAMPIONS c
LEFT JOIN RAW.MATCH_HISTORY m ON c.champion_id = m.champion_id
LEFT JOIN RAW.PURCHASES pur ON c.champion_id = pur.item_id AND pur.item_type IN ('CHAMPION','SKIN')
GROUP BY c.champion_id, c.champion_name, c.role, c.difficulty;

-- ============================================================================
-- Player Interaction View
-- ============================================================================
CREATE OR REPLACE VIEW V_PLAYER_INTERACTION_ANALYTICS AS
SELECT
    pi.interaction_id,
    pi.player_id,
    pi.interaction_date,
    DATE_TRUNC('month', pi.interaction_date) AS interaction_month,
    pi.interaction_type,
    pi.channel,
    pi.agent_name,
    pi.topic,
    pi.outcome,
    pi.sentiment_score,
    pi.escalation_flag,
    pi.follow_up_date,
    p.player_segment,
    p.ranked_tier,
    p.region
FROM RAW.PLAYER_INTERACTIONS pi
JOIN RAW.PLAYERS p ON pi.player_id = p.player_id;

-- ============================================================================
-- Revenue Summary View
-- ============================================================================
CREATE OR REPLACE VIEW V_RIOT_REVENUE_SUMMARY AS
SELECT
    p.player_id,
    p.summoner_name,
    p.player_segment,
    p.region,
    p.account_created_date,
    DATE_TRUNC('month', p.account_created_date) AS cohort_month,
    SUM(pur.amount_usd) AS lifetime_revenue,
    COUNT(DISTINCT pur.transaction_id) AS total_transactions,
    AVG(pur.amount_usd) AS avg_transaction_value,
    MAX(pur.purchase_date) AS last_purchase_date,
    COUNT(DISTINCT CASE WHEN pur.item_type = 'SKIN' THEN pur.transaction_id END) AS skin_purchases,
    COUNT(DISTINCT CASE WHEN pur.item_type = 'RP_BUNDLE' THEN pur.transaction_id END) AS rp_purchases,
    COUNT(DISTINCT ir.incident_report_id) AS incident_count
FROM RAW.PLAYERS p
LEFT JOIN RAW.PURCHASES pur ON p.player_id = pur.player_id
LEFT JOIN RAW.INCIDENT_REPORTS ir ON p.player_id = ir.player_id
GROUP BY
    p.player_id, p.summoner_name, p.player_segment, p.region,
    p.account_created_date;

-- ============================================================================
-- Churn Risk View
-- ============================================================================
CREATE OR REPLACE VIEW V_CHURN_RISK_ANALYTICS AS
SELECT
    ce.event_id,
    ce.player_id,
    ce.event_date,
    ce.event_type,
    ce.days_since_last_login,
    ce.churn_risk_score,
    ce.intervention_attempted,
    p.player_segment,
    p.ranked_tier,
    p.total_playtime_hours,
    p.account_level,
    COALESCE(SUM(pur.amount_usd), 0) AS lifetime_value
FROM RAW.CHURN_EVENTS ce
JOIN RAW.PLAYERS p ON ce.player_id = p.player_id
LEFT JOIN RAW.PURCHASES pur ON p.player_id = pur.player_id
GROUP BY
    ce.event_id, ce.player_id, ce.event_date, ce.event_type,
    ce.days_since_last_login, ce.churn_risk_score, ce.intervention_attempted,
    p.player_segment, p.ranked_tier, p.total_playtime_hours, p.account_level;

-- ============================================================================
-- Incident Analytics View
-- ============================================================================
CREATE OR REPLACE VIEW V_INCIDENT_ANALYTICS AS
SELECT
    ir.incident_report_id,
    ir.player_id,
    ir.match_id,
    ir.incident_type,
    ir.severity,
    ir.status,
    ir.report_date,
    ir.investigator,
    ir.report_text,
    ir.findings_summary,
    ir.recommendations,
    p.player_segment,
    p.ranked_tier,
    p.honor_level,
    p.region
FROM RAW.INCIDENT_REPORTS ir
LEFT JOIN RAW.PLAYERS p ON ir.player_id = p.player_id;

-- ============================================================================
-- Confirmation
-- ============================================================================
SELECT 'Riot Games analytical views created successfully' AS STATUS;
