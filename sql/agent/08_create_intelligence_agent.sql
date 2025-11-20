-- ============================================================================
-- Riot Games Intelligence Agent - Creation Script
-- ============================================================================
-- Purpose: Create the Riot Games Intelligence Agent with all tools configured
-- Execution order: run after setup, tables, data, views, semantic views,
-- Cortex Search, and ML wrapper procedures are in place.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE RIOT_GAMES_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RIOT_GAMES_SI_WH;

-- ============================================================================
-- Step 1: Grant Required Privileges
-- (Adjust role SYSADMIN below if you use a different primary role)
-- ============================================================================
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_ANALYST_USER TO ROLE SYSADMIN;

GRANT USAGE ON DATABASE RIOT_GAMES_INTELLIGENCE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA RIOT_GAMES_INTELLIGENCE.ANALYTICS TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA RIOT_GAMES_INTELLIGENCE.RAW TO ROLE SYSADMIN;

GRANT REFERENCES, SELECT ON SEMANTIC VIEW RIOT_GAMES_INTELLIGENCE.ANALYTICS.SV_PLAYER_ENGAGEMENT TO ROLE SYSADMIN;
GRANT REFERENCES, SELECT ON SEMANTIC VIEW RIOT_GAMES_INTELLIGENCE.ANALYTICS.SV_MONETIZATION_INTELLIGENCE TO ROLE SYSADMIN;
GRANT REFERENCES, SELECT ON SEMANTIC VIEW RIOT_GAMES_INTELLIGENCE.ANALYTICS.SV_PLAYER_SUPPORT_INTELLIGENCE TO ROLE SYSADMIN;

GRANT USAGE ON WAREHOUSE RIOT_GAMES_SI_WH TO ROLE SYSADMIN;

GRANT USAGE ON CORTEX SEARCH SERVICE RIOT_GAMES_INTELLIGENCE.RAW.SUPPORT_TRANSCRIPTS_SEARCH TO ROLE SYSADMIN;
GRANT USAGE ON CORTEX SEARCH SERVICE RIOT_GAMES_INTELLIGENCE.RAW.POLICY_DOCUMENTS_SEARCH TO ROLE SYSADMIN;
GRANT USAGE ON CORTEX SEARCH SERVICE RIOT_GAMES_INTELLIGENCE.RAW.INCIDENT_REPORTS_SEARCH TO ROLE SYSADMIN;

GRANT USAGE ON PROCEDURE RIOT_GAMES_INTELLIGENCE.ANALYTICS.PREDICT_REVENUE(INT) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE RIOT_GAMES_INTELLIGENCE.ANALYTICS.PREDICT_CHURN_RISK(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE RIOT_GAMES_INTELLIGENCE.ANALYTICS.PREDICT_TOXICITY_RISK(VARCHAR) TO ROLE SYSADMIN;

-- ============================================================================
-- Step 2: Create the Intelligence Agent
-- ============================================================================
CREATE OR REPLACE AGENT RIOT_GAMES_INTELLIGENCE_AGENT
  COMMENT = 'Riot Games SI agent for player engagement, monetization, and support insights'
  PROFILE = '{"display_name": "Riot Games Intelligence Agent", "avatar": "game-controller.png", "color": "red"}'
  FROM SPECIFICATION
  $$
models:
  orchestration: auto

orchestration:
  budget:
    seconds: 60
    tokens: 32000

instructions:
  response: 'You are the Riot Games analytics assistant. Use semantic views for structured gaming data, Cortex Search for policies/transcripts/incidents, and ML tools for predictions. Keep answers specific, cite data, and explain how results impact player engagement, monetization, or community health.'
  orchestration: 'Favor structured SQL via Cortex Analyst when questions involve metrics. Use search services for policy or transcript lookups, and call ML procedures for forecasts or risk predictions.'
  system: 'Provide insights on player engagement, match performance, revenue and monetization, champion balance, player support, and incident management across Riot Games datasets.'
  sample_questions:
    - question: 'How many active players do we have by region?'
      answer: 'I will query the player engagement semantic view and group by region.'
    - question: 'What is the total revenue this quarter?'
      answer: 'I will use the monetization intelligence semantic view to sum revenue by purchase date.'
    - question: 'Show me support transcripts about payment failures.'
      answer: 'I will call the SupportTranscriptsSearch Cortex service filtered for payment issues.'
    - question: 'Predict revenue for the next 6 months.'
      answer: 'I will run the PredictRevenue tool with months_ahead = 6.'
    - question: 'Which champions have the highest win rates?'
      answer: 'I will analyze match metrics in the player engagement semantic view grouped by champion.'
    - question: 'Summarize toxicity incidents last month.'
      answer: 'I will query the incident search service and the support semantic view for toxicity counts.'
    - question: 'Identify CASUAL players at high churn risk.'
      answer: 'I will use the PredictChurnRisk tool with segment filter CASUAL.'
    - question: 'List policies covering ranked play penalties.'
      answer: 'I will call PolicyDocumentsSearch with keywords ranked, penalties.'
    - question: 'What is our skin purchase conversion rate?'
      answer: 'I will reference the monetization semantic view for skin purchase metrics.'
    - question: 'Predict toxicity risk for ENGAGED segment players.'
      answer: 'I will run PredictToxicityRisk with player segment ENGAGED.'

tools:
  - tool_spec:
      type: 'cortex_analyst_text_to_sql'
      name: 'PlayerEngagementAnalyst'
      description: 'Structured analysis of player activity, match performance, and champion statistics'
  - tool_spec:
      type: 'cortex_analyst_text_to_sql'
      name: 'MonetizationAnalyst'
      description: 'Structured analysis of revenue, purchases, and player spending behavior'
  - tool_spec:
      type: 'cortex_analyst_text_to_sql'
      name: 'PlayerSupportAnalyst'
      description: 'Structured analysis of support interactions, sentiment, and incident reports'
  - tool_spec:
      type: 'cortex_search'
      name: 'SupportTranscriptsSearch'
      description: 'Search across player support transcripts and conversations'
  - tool_spec:
      type: 'cortex_search'
      name: 'PolicyDocumentsSearch'
      description: 'Search across game policies, terms of service, and community guidelines'
  - tool_spec:
      type: 'cortex_search'
      name: 'IncidentReportsSearch'
      description: 'Search cheating, toxicity, and technical incident investigations'
  - tool_spec:
      type: 'generic'
      name: 'PredictRevenue'
      description: 'Forecasts future monthly revenue from player purchases'
      input_schema:
        type: 'object'
        properties:
          months_ahead:
            type: 'integer'
            description: 'Number of months to forecast (1-12)'
        required: ['months_ahead']
  - tool_spec:
      type: 'generic'
      name: 'PredictChurnRisk'
      description: 'Identifies players at risk of quitting by segment'
      input_schema:
        type: 'object'
        properties:
          player_segment:
            type: 'string'
            description: 'Player segment filter (CORE, ENGAGED, CASUAL, NEW, or ALL)'
        required: ['player_segment']
  - tool_spec:
      type: 'generic'
      name: 'PredictToxicityRisk'
      description: 'Predicts likelihood of player behavior incidents'
      input_schema:
        type: 'object'
        properties:
          player_segment:
            type: 'string'
            description: 'Player segment filter (CORE, ENGAGED, CASUAL, NEW, or ALL)'
        required: ['player_segment']

tool_resources:
  PlayerEngagementAnalyst:
    semantic_view: 'RIOT_GAMES_INTELLIGENCE.ANALYTICS.SV_PLAYER_ENGAGEMENT'
    execution_environment:
      type: 'warehouse'
      warehouse: 'RIOT_GAMES_SI_WH'
      query_timeout: 60
  MonetizationAnalyst:
    semantic_view: 'RIOT_GAMES_INTELLIGENCE.ANALYTICS.SV_MONETIZATION_INTELLIGENCE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'RIOT_GAMES_SI_WH'
      query_timeout: 60
  PlayerSupportAnalyst:
    semantic_view: 'RIOT_GAMES_INTELLIGENCE.ANALYTICS.SV_PLAYER_SUPPORT_INTELLIGENCE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'RIOT_GAMES_SI_WH'
      query_timeout: 60
  SupportTranscriptsSearch:
    search_service: 'RIOT_GAMES_INTELLIGENCE.RAW.SUPPORT_TRANSCRIPTS_SEARCH'
    max_results: 8
    title_column: 'interaction_id'
    id_column: 'transcript_id'
  PolicyDocumentsSearch:
    search_service: 'RIOT_GAMES_INTELLIGENCE.RAW.POLICY_DOCUMENTS_SEARCH'
    max_results: 5
    title_column: 'title'
    id_column: 'policy_id'
  IncidentReportsSearch:
    search_service: 'RIOT_GAMES_INTELLIGENCE.RAW.INCIDENT_REPORTS_SEARCH'
    max_results: 8
    title_column: 'incident_type'
    id_column: 'incident_report_id'
  PredictRevenue:
    type: 'procedure'
    identifier: 'RIOT_GAMES_INTELLIGENCE.ANALYTICS.PREDICT_REVENUE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'RIOT_GAMES_SI_WH'
      query_timeout: 60
  PredictChurnRisk:
    type: 'procedure'
    identifier: 'RIOT_GAMES_INTELLIGENCE.ANALYTICS.PREDICT_CHURN_RISK'
    execution_environment:
      type: 'warehouse'
      warehouse: 'RIOT_GAMES_SI_WH'
      query_timeout: 60
  PredictToxicityRisk:
    type: 'procedure'
    identifier: 'RIOT_GAMES_INTELLIGENCE.ANALYTICS.PREDICT_TOXICITY_RISK'
    execution_environment:
      type: 'warehouse'
      warehouse: 'RIOT_GAMES_SI_WH'
      query_timeout: 60
  $$;

-- ============================================================================
-- Step 3: Verify & Grant Agent Usage
-- ============================================================================
SHOW AGENTS LIKE 'RIOT_GAMES_INTELLIGENCE_AGENT';
DESCRIBE AGENT RIOT_GAMES_INTELLIGENCE_AGENT;

GRANT USAGE ON AGENT RIOT_GAMES_INTELLIGENCE_AGENT TO ROLE SYSADMIN;

-- ============================================================================
-- Step 4: Reference Notes
-- ============================================================================
-- Use Snowsight > AI & ML > Agents to test RIOT_GAMES_INTELLIGENCE_AGENT.
-- Example prompts:
--   'Show me revenue by player segment this quarter'
--   'Which champions have the lowest win rates in ranked?'
--   'Predict churn risk for CASUAL players'
--   'Search for support tickets about account recovery'
--   'What is the toxicity incident rate by region?'
