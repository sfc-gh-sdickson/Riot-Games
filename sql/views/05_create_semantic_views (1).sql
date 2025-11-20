-- ============================================================================
-- Riot Games Intelligence Agent - Semantic Views
-- ============================================================================
-- Purpose: Semantic views for Cortex Analyst text-to-SQL capabilities
-- ============================================================================

USE DATABASE RIOT_GAMES_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RIOT_GAMES_SI_WH;

-- ============================================================================
-- Semantic View 1: Player Engagement & Match Performance
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_PLAYER_ENGAGEMENT
  TABLES (
    players AS RAW.PLAYERS
      PRIMARY KEY (player_id),
    matches AS RAW.MATCH_HISTORY
      PRIMARY KEY (match_id),
    champions AS RAW.CHAMPIONS
      PRIMARY KEY (champion_id),
    churn AS RAW.CHURN_EVENTS
      PRIMARY KEY (event_id)
  )
  RELATIONSHIPS (
    matches(player_id) REFERENCES players(player_id),
    matches(champion_id) REFERENCES champions(champion_id),
    churn(player_id) REFERENCES players(player_id)
  )
  DIMENSIONS (
    players.summoner_name AS players.summoner_name,
    players.player_region AS players.region,
    players.segment AS players.player_segment,
    players.tier AS players.ranked_tier,
    players.division AS players.ranked_division,
    players.honor AS players.honor_level,
    players.status AS players.account_status,
    matches.mode AS matches.game_mode,
    matches.outcome AS matches.result,
    matches.role AS matches.role_played,
    champions.name AS champions.champion_name,
    champions.champion_role AS champions.role,
    champions.skill_level AS champions.difficulty,
    churn.event_category AS churn.event_type
  )
  METRICS (
    players.total_players AS COUNT(DISTINCT player_id),
    players.avg_level AS AVG(account_level),
    players.avg_playtime AS AVG(total_playtime_hours),
    matches.total_matches AS COUNT(DISTINCT match_id),
    matches.total_wins AS COUNT_IF(result = 'WIN'),
    matches.total_losses AS COUNT_IF(result = 'LOSS'),
    matches.win_rate AS (COUNT_IF(result = 'WIN')::FLOAT / NULLIF(COUNT(*), 0)),
    matches.avg_kills AS AVG(kills),
    matches.avg_deaths AS AVG(deaths),
    matches.avg_assists AS AVG(assists),
    matches.avg_kda AS AVG((kills + assists)::FLOAT / NULLIF(deaths, 1)),
    matches.avg_duration AS AVG(match_duration_seconds),
    matches.afk_rate AS (COUNT_IF(afk_flag)::FLOAT / NULLIF(COUNT(*), 0)),
    champions.unique_played AS COUNT(DISTINCT champion_id),
    churn.total_events AS COUNT(DISTINCT event_id),
    churn.avg_risk AS AVG(churn_risk_score)
  )
  COMMENT = 'Semantic view for player engagement, match performance, and champion statistics';

-- ============================================================================
-- Semantic View 2: Monetization & Revenue Intelligence
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_MONETIZATION_INTELLIGENCE
  TABLES (
    players AS RAW.PLAYERS
      PRIMARY KEY (player_id),
    purchases AS RAW.PURCHASES
      PRIMARY KEY (transaction_id),
    skins AS RAW.SKINS
      PRIMARY KEY (skin_id),
    champions AS RAW.CHAMPIONS
      PRIMARY KEY (champion_id)
  )
  RELATIONSHIPS (
    purchases(player_id) REFERENCES players(player_id),
    skins(champion_id) REFERENCES champions(champion_id)
  )
  DIMENSIONS (
    players.segment AS players.player_segment,
    players.player_region AS players.region,
    players.tier AS players.ranked_tier,
    purchases.product_type AS purchases.item_type,
    purchases.currency AS purchases.currency_type,
    purchases.payment_type AS purchases.payment_method,
    purchases.channel AS purchases.purchase_channel,
    purchases.promo_flag AS purchases.promotion_applied,
    purchases.refunded AS purchases.refund_flag,
    skins.tier AS skins.rarity,
    skins.collection AS skins.theme,
    skins.limited AS skins.is_limited_edition
  )
  METRICS (
    players.total_buyers AS COUNT(DISTINCT player_id),
    purchases.total_purchases AS COUNT(DISTINCT transaction_id),
    purchases.total_revenue AS SUM(amount_usd),
    purchases.avg_transaction AS AVG(amount_usd),
    purchases.total_rp AS SUM(amount_rp),
    purchases.total_be AS SUM(amount_be),
    purchases.skin_count AS COUNT_IF(item_type = 'SKIN'),
    purchases.champion_count AS COUNT_IF(item_type = 'CHAMPION'),
    purchases.battlepass_count AS COUNT_IF(item_type = 'BATTLE_PASS'),
    purchases.refund_rate AS (COUNT_IF(refund_flag)::FLOAT / NULLIF(COUNT(*), 0)),
    purchases.promo_rate AS (COUNT_IF(promotion_applied)::FLOAT / NULLIF(COUNT(*), 0)),
    skins.total_skins AS COUNT(DISTINCT skin_id),
    skins.avg_price AS AVG(price_rp)
  )
  COMMENT = 'Semantic view for revenue, purchases, and monetization analytics';

-- ============================================================================
-- Semantic View 3: Player Support & Incident Intelligence
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_PLAYER_SUPPORT_INTELLIGENCE
  TABLES (
    players AS RAW.PLAYERS
      PRIMARY KEY (player_id),
    interactions AS RAW.PLAYER_INTERACTIONS
      PRIMARY KEY (interaction_id),
    transcripts AS RAW.SUPPORT_TRANSCRIPTS
      PRIMARY KEY (transcript_id),
    incidents AS RAW.INCIDENT_REPORTS
      PRIMARY KEY (incident_report_id)
  )
  RELATIONSHIPS (
    interactions(player_id) REFERENCES players(player_id),
    transcripts(interaction_id) REFERENCES interactions(interaction_id),
    incidents(player_id) REFERENCES players(player_id)
  )
  DIMENSIONS (
    players.segment AS players.player_segment,
    players.player_region AS players.region,
    players.tier AS players.ranked_tier,
    players.honor AS players.honor_level,
    interactions.type AS interactions.interaction_type,
    interactions.contact_channel AS interactions.channel,
    interactions.resolution AS interactions.outcome,
    interactions.escalated AS interactions.escalation_flag,
    transcripts.issue_type AS transcripts.issue_category,
    transcripts.status AS transcripts.resolution_status,
    transcripts.channel AS transcripts.interaction_channel,
    incidents.violation_type AS incidents.incident_type,
    incidents.priority AS incidents.severity,
    incidents.investigation_status AS incidents.status
  )
  METRICS (
    players.total_players AS COUNT(DISTINCT player_id),
    interactions.total_interactions AS COUNT(DISTINCT interaction_id),
    interactions.escalation_rate AS (COUNT_IF(escalation_flag)::FLOAT / NULLIF(COUNT(*), 0)),
    interactions.avg_sentiment AS AVG(sentiment_score),
    interactions.resolution_rate AS (COUNT_IF(outcome = 'RESOLVED')::FLOAT / NULLIF(COUNT(*), 0)),
    transcripts.total_transcripts AS COUNT(DISTINCT transcript_id),
    transcripts.resolution_rate AS (COUNT_IF(resolution_status = 'RESOLVED')::FLOAT / NULLIF(COUNT(*), 0)),
    incidents.total_incidents AS COUNT(DISTINCT incident_report_id),
    incidents.cheating_count AS COUNT_IF(incident_type = 'CHEATING'),
    incidents.toxicity_count AS COUNT_IF(incident_type = 'TOXICITY'),
    incidents.critical_count AS COUNT_IF(severity = 'CRITICAL'),
    incidents.open_count AS COUNT_IF(status = 'OPEN')
  )
  COMMENT = 'Semantic view for player support interactions, transcripts, and incident reports';

-- ============================================================================
-- Confirmation
-- ============================================================================
SELECT 'All Riot Games semantic views created successfully' AS STATUS;
