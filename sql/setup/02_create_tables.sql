-- ============================================================================
-- Riot Games Intelligence Agent - Table Definitions
-- ============================================================================
-- Purpose: Create raw tables aligned to Riot Games business model (players,
--          matches, purchases, champions, skins, support tickets, game events)
-- ============================================================================

USE DATABASE RIOT_GAMES_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE RIOT_GAMES_SI_WH;

-- ============================================================================
-- PLAYERS (registered players with account details)
-- ============================================================================
CREATE OR REPLACE TABLE PLAYERS (
    player_id VARCHAR(20) PRIMARY KEY,
    summoner_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL,
    account_created_date DATE NOT NULL,
    region VARCHAR(10) NOT NULL,
    preferred_language VARCHAR(30),
    date_of_birth DATE,
    country VARCHAR(50),
    account_level NUMBER(5,0) DEFAULT 1,
    honor_level NUMBER(2,0) DEFAULT 2,
    ranked_tier VARCHAR(20),
    ranked_division VARCHAR(10),
    total_playtime_hours NUMBER(10,2) DEFAULT 0,
    account_status VARCHAR(30) DEFAULT 'ACTIVE',
    player_segment VARCHAR(30),
    acquisition_channel VARCHAR(50),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- CHAMPIONS (playable champions in the game)
-- ============================================================================
CREATE OR REPLACE TABLE CHAMPIONS (
    champion_id VARCHAR(20) PRIMARY KEY,
    champion_name VARCHAR(100) NOT NULL,
    role VARCHAR(50),
    difficulty VARCHAR(20),
    release_date DATE,
    is_free BOOLEAN DEFAULT FALSE,
    base_price_rp NUMBER(10,0),
    base_price_be NUMBER(10,0),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- MATCH_HISTORY (game match records)
-- ============================================================================
CREATE OR REPLACE TABLE MATCH_HISTORY (
    match_id VARCHAR(25) PRIMARY KEY,
    player_id VARCHAR(20) NOT NULL,
    champion_id VARCHAR(20) NOT NULL,
    match_date TIMESTAMP_NTZ NOT NULL,
    game_mode VARCHAR(50) NOT NULL,
    match_duration_seconds NUMBER(10,0) NOT NULL,
    result VARCHAR(20) NOT NULL,
    kills NUMBER(5,0) DEFAULT 0,
    deaths NUMBER(5,0) DEFAULT 0,
    assists NUMBER(5,0) DEFAULT 0,
    gold_earned NUMBER(10,0) DEFAULT 0,
    damage_dealt NUMBER(12,0) DEFAULT 0,
    damage_taken NUMBER(12,0) DEFAULT 0,
    vision_score NUMBER(5,0) DEFAULT 0,
    role_played VARCHAR(50),
    queue_type VARCHAR(50),
    premade_team_size NUMBER(1,0) DEFAULT 1,
    player_rank_at_match VARCHAR(30),
    afk_flag BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (player_id) REFERENCES PLAYERS(player_id),
    FOREIGN KEY (champion_id) REFERENCES CHAMPIONS(champion_id)
);

-- ============================================================================
-- PURCHASES (in-game purchases - RP, skins, champions, etc.)
-- ============================================================================
CREATE OR REPLACE TABLE PURCHASES (
    transaction_id VARCHAR(25) PRIMARY KEY,
    player_id VARCHAR(20) NOT NULL,
    purchase_date TIMESTAMP_NTZ NOT NULL,
    item_type VARCHAR(50) NOT NULL,
    item_id VARCHAR(50),
    item_name VARCHAR(200),
    currency_type VARCHAR(10) NOT NULL,
    amount_usd NUMBER(12,2) NOT NULL,
    amount_rp NUMBER(10,0),
    amount_be NUMBER(10,0),
    payment_method VARCHAR(50),
    region VARCHAR(10),
    purchase_channel VARCHAR(50),
    promotion_applied BOOLEAN DEFAULT FALSE,
    refund_flag BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (player_id) REFERENCES PLAYERS(player_id)
);

-- ============================================================================
-- SKINS (cosmetic items for champions)
-- ============================================================================
CREATE OR REPLACE TABLE SKINS (
    skin_id VARCHAR(25) PRIMARY KEY,
    champion_id VARCHAR(20) NOT NULL,
    skin_name VARCHAR(200) NOT NULL,
    rarity VARCHAR(30),
    price_rp NUMBER(10,0),
    release_date DATE,
    is_limited_edition BOOLEAN DEFAULT FALSE,
    theme VARCHAR(100),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (champion_id) REFERENCES CHAMPIONS(champion_id)
);

-- ============================================================================
-- PLAYER_INTERACTIONS (customer support, reports, feedback)
-- ============================================================================
CREATE OR REPLACE TABLE PLAYER_INTERACTIONS (
    interaction_id VARCHAR(25) PRIMARY KEY,
    player_id VARCHAR(20) NOT NULL,
    interaction_date TIMESTAMP_NTZ NOT NULL,
    interaction_type VARCHAR(50),
    channel VARCHAR(50),
    agent_name VARCHAR(100),
    topic VARCHAR(100),
    outcome VARCHAR(100),
    sentiment_score NUMBER(5,2),
    notes VARCHAR(5000),
    follow_up_date DATE,
    escalation_flag BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (player_id) REFERENCES PLAYERS(player_id)
);

-- ============================================================================
-- SUPPORT_TRANSCRIPTS (unstructured support conversations)
-- ============================================================================
CREATE OR REPLACE TABLE SUPPORT_TRANSCRIPTS (
    transcript_id VARCHAR(25) PRIMARY KEY,
    interaction_id VARCHAR(25),
    player_id VARCHAR(20),
    transcript_text VARCHAR(16777216) NOT NULL,
    interaction_channel VARCHAR(50),
    transcript_date TIMESTAMP_NTZ NOT NULL,
    agent_id VARCHAR(20),
    issue_category VARCHAR(50),
    resolution_status VARCHAR(30),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (interaction_id) REFERENCES PLAYER_INTERACTIONS(interaction_id),
    FOREIGN KEY (player_id) REFERENCES PLAYERS(player_id)
);

-- ============================================================================
-- POLICY_DOCUMENTS (game policies, terms of service, community guidelines)
-- ============================================================================
CREATE OR REPLACE TABLE POLICY_DOCUMENTS (
    policy_id VARCHAR(25) PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    content VARCHAR(16777216) NOT NULL,
    document_category VARCHAR(50),
    business_unit VARCHAR(50),
    owner VARCHAR(100),
    effective_date DATE,
    revision VARCHAR(20),
    keywords VARCHAR(500),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    last_updated TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- INCIDENT_REPORTS (cheating, toxicity, technical issues)
-- ============================================================================
CREATE OR REPLACE TABLE INCIDENT_REPORTS (
    incident_report_id VARCHAR(25) PRIMARY KEY,
    player_id VARCHAR(20),
    match_id VARCHAR(25),
    report_text VARCHAR(16777216) NOT NULL,
    incident_type VARCHAR(50),
    severity VARCHAR(20),
    status VARCHAR(30),
    findings_summary VARCHAR(5000),
    recommendations VARCHAR(5000),
    report_date TIMESTAMP_NTZ NOT NULL,
    investigator VARCHAR(100),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (player_id) REFERENCES PLAYERS(player_id),
    FOREIGN KEY (match_id) REFERENCES MATCH_HISTORY(match_id)
);

-- ============================================================================
-- CHURN_EVENTS (player churn/retention tracking)
-- ============================================================================
CREATE OR REPLACE TABLE CHURN_EVENTS (
    event_id VARCHAR(25) PRIMARY KEY,
    player_id VARCHAR(20) NOT NULL,
    event_date DATE NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    days_since_last_login NUMBER(10,0),
    churn_risk_score NUMBER(5,2),
    intervention_attempted BOOLEAN DEFAULT FALSE,
    notes VARCHAR(2000),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (player_id) REFERENCES PLAYERS(player_id)
);

-- ============================================================================
-- Display confirmation
-- ============================================================================
SELECT 'All Riot Games raw tables created successfully' AS STATUS;
