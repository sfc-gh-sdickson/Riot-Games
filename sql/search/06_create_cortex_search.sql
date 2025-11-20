-- ============================================================================
-- Riot Games Intelligence Agent - Cortex Search Services
-- ============================================================================
-- Purpose: Enable semantic search over unstructured support, policy, and incident data
-- Prereq tables: SUPPORT_TRANSCRIPTS, POLICY_DOCUMENTS, INCIDENT_REPORTS
-- ============================================================================

USE DATABASE RIOT_GAMES_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE RIOT_GAMES_SI_WH;

-- ============================================================================
-- Step 1: Ensure Change Tracking (required before CREATE CORTEX SEARCH SERVICE)
-- ============================================================================
ALTER TABLE SUPPORT_TRANSCRIPTS SET CHANGE_TRACKING = TRUE;
ALTER TABLE POLICY_DOCUMENTS SET CHANGE_TRACKING = TRUE;
ALTER TABLE INCIDENT_REPORTS SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- Step 2: (Optional) Seed extra policy content
-- ============================================================================
INSERT INTO POLICY_DOCUMENTS (policy_id, title, content, document_category, business_unit, owner,
                              effective_date, revision, keywords, created_at, last_updated)
SELECT
    'POLICY005',
    'Ranked Play Guidelines and Penalties',
    $$Ranked play guidelines covering queue restrictions, LP penalties, promotion series rules, and rank decay policies.
Includes information on win trading, boosting prohibitions, and competitive integrity standards.$$,
    'COMPETITIVE',
    'ESPORTS_OPS',
    'Competitive Operations',
    '2025-04-01',
    'v3.4',
    'ranked, competitive, penalties, LP',
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
WHERE NOT EXISTS (SELECT 1 FROM POLICY_DOCUMENTS WHERE policy_id = 'POLICY005');

-- ============================================================================
-- Step 3: Create Cortex Search Service for Support Transcripts
-- ============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE SUPPORT_TRANSCRIPTS_SEARCH
  ON transcript_text
  ATTRIBUTES player_id, interaction_channel, issue_category, resolution_status
  WAREHOUSE = RIOT_GAMES_SI_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Semantic search across player support transcripts for issue resolution insights'
AS
  SELECT
    transcript_id,
    transcript_text,
    interaction_id,
    player_id,
    interaction_channel,
    transcript_date,
    agent_id,
    issue_category,
    resolution_status,
    created_at
  FROM SUPPORT_TRANSCRIPTS;

-- ============================================================================
-- Step 4: Create Cortex Search Service for Policy Documents
-- ============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE POLICY_DOCUMENTS_SEARCH
  ON content
  ATTRIBUTES document_category, business_unit, title, keywords
  WAREHOUSE = RIOT_GAMES_SI_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Search over game policies, terms of service, and community guidelines'
AS
  SELECT
    policy_id,
    content,
    title,
    document_category,
    business_unit,
    owner,
    effective_date,
    revision,
    keywords,
    last_updated
  FROM POLICY_DOCUMENTS;

-- ============================================================================
-- Step 5: Create Cortex Search Service for Incident Reports
-- ============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE INCIDENT_REPORTS_SEARCH
  ON report_text
  ATTRIBUTES player_id, match_id, incident_type, severity, status
  WAREHOUSE = RIOT_GAMES_SI_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Searchable repository of cheating, toxicity, and technical incident investigations'
AS
  SELECT
    incident_report_id,
    report_text,
    player_id,
    match_id,
    incident_type,
    severity,
    status,
    findings_summary,
    recommendations,
    report_date,
    investigator
  FROM INCIDENT_REPORTS;

-- ============================================================================
-- Step 6: Status Summary
-- ============================================================================
SHOW TABLES LIKE 'SUPPORT_TRANSCRIPTS' IN SCHEMA RAW;
SELECT
    "name" AS table_name,
    "change_tracking" AS change_tracking
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW TABLES LIKE 'POLICY_DOCUMENTS' IN SCHEMA RAW;
SELECT
    "name" AS table_name,
    "change_tracking" AS change_tracking
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW TABLES LIKE 'INCIDENT_REPORTS' IN SCHEMA RAW;
SELECT
    "name" AS table_name,
    "change_tracking" AS change_tracking
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SELECT 'Riot Games Cortex Search services created successfully' AS status;
