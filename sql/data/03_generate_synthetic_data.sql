-- ============================================================================
-- Riot Games Intelligence Agent - Synthetic Data Generation
-- ============================================================================
-- Purpose: Populate RAW tables with realistic gaming, purchase, and support data
-- Volume targets (~):
--   Players 50k, Champions 165, Matches 500k, Purchases 150k,
--   Interactions 80k, Transcripts 12k, Policy docs 4,
--   Incident reports 15k, Churn events 10k
-- ============================================================================

USE DATABASE RIOT_GAMES_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE RIOT_GAMES_SI_WH;

-- ============================================================================
-- Step 1: Generate Champions
-- ============================================================================
INSERT INTO CHAMPIONS
SELECT
    'CHAMP' || LPAD(SEQ4(), 4, '0') AS champion_id,
    ARRAY_CONSTRUCT('Ahri','Akali','Ashe','Caitlyn','Darius','Diana','Draven','Ekko','Ezreal','Fiora',
                    'Garen','Graves','Irelia','Janna','Jax','Jinx','Kai Sa','Katarina','Kayn','Leblanc',
                    'Lee Sin','Lux','Malphite','Master Yi','Miss Fortune','Morgana','Nasus','Orianna','Pyke','Riven',
                    'Senna','Seraphine','Sett','Shen','Sivir','Sona','Soraka','Syndra','Tahm Kench','Talon',
                    'Teemo','Thresh','Tristana','Tryndamere','Twisted Fate','Twitch','Varus','Vayne','Veigar','Vi',
                    'Vladimir','Warwick','Wukong','Xayah','Xerath','Yasuo','Yone','Yuumi','Zed','Ziggs',
                    'Zilean','Zoe','Zyra','Aatrox','Alistar','Amumu','Anivia','Annie','Aphelios','Azir',
                    'Bard','Blitzcrank','Brand','Braum','Cassiopeia','Cho Gath','Corki','Dr Mundo','Elise','Evelynn',
                    'Fiddlesticks','Galio','Gangplank','Gnar','Gragas','Hecarim','Heimerdinger','Illaoi','Ivern','Jarvan IV',
                    'Jayce','Jhin','Kalista','Karma','Karthus','Kassadin','Kennen','Kha Zix','Kindred','Kled',
                    'Kog Maw','Leona','Lillia','Lissandra','Lucian','Lulu','Malzahar','Maokai','Mordekaiser','Nami',
                    'Nautilus','Neeko','Nidalee','Nocturne','Nunu','Olaf','Ornn','Pantheon','Poppy','Quinn',
                    'Rakan','Rammus','Rek Sai','Rell','Renata','Renekton','Rengar','Rumble','Ryze','Samira',
                    'Sejuani','Shaco','Shyvana','Singed','Sion','Skarner','Swain','Sylas','Taliyah','Trundle',
                    'Udyr','Urgot','Vel Koz','Vex','Viego','Viktor','Volibear','Xin Zhao','Yorick','Zac',
                    'Zeri','Akshan','Bel Veth','Briar','Gwen','K Sante','Milio','Naafiri','Nilah','Smolder','Hwei')[UNIFORM(0, 19, RANDOM())] AS champion_name,
    ARRAY_CONSTRUCT('TOP','JUNGLE','MID','ADC','SUPPORT')[UNIFORM(0, 4, RANDOM())] AS role,
    ARRAY_CONSTRUCT('EASY','MODERATE','HARD')[UNIFORM(0, 2, RANDOM())] AS difficulty,
    DATEADD('day', -1 * UNIFORM(1, 4000, RANDOM()), CURRENT_DATE()) AS release_date,
    UNIFORM(0, 100, RANDOM()) < 10 AS is_free,
    ARRAY_CONSTRUCT(880, 975, 1350, 4800, 6300, 7800)[UNIFORM(0, 5, RANDOM())] AS base_price_rp,
    ARRAY_CONSTRUCT(450, 1350, 3150, 4800, 6300)[UNIFORM(0, 4, RANDOM())] AS base_price_be,
    CURRENT_TIMESTAMP() AS created_at
FROM TABLE(GENERATOR(ROWCOUNT => 165));

-- ============================================================================
-- Step 2: Generate Players
-- ============================================================================
INSERT INTO PLAYERS
WITH base AS (
    SELECT
        SEQ4() AS seq,
        UNIFORM(1, 500, RANDOM()) AS player_level,
        UNIFORM(0, 5, RANDOM()) AS honor_level_raw
    FROM TABLE(GENERATOR(ROWCOUNT => 50000))
)
SELECT
    'PLAYER' || LPAD(seq, 8, '0') AS player_id,
    CONCAT('Summoner', seq) AS summoner_name,
    LOWER(CONCAT('player', seq, '@riotgames.com')) AS email,
    DATEADD('day', -1 * UNIFORM(30, 3650, RANDOM()), CURRENT_DATE()) AS account_created_date,
    ARRAY_CONSTRUCT('NA','EUW','EUNE','KR','CN','BR','LAN','LAS','OCE','RU','TR','JP','SEA')[UNIFORM(0, 12, RANDOM())] AS region,
    ARRAY_CONSTRUCT('ENGLISH','SPANISH','FRENCH','GERMAN','KOREAN','CHINESE','JAPANESE','PORTUGUESE')[UNIFORM(0, 7, RANDOM())] AS preferred_language,
    DATEADD('year', -1 * UNIFORM(13, 50, RANDOM()), CURRENT_DATE()) AS date_of_birth,
    ARRAY_CONSTRUCT('USA','UK','Germany','France','Korea','China','Brazil','Mexico','Australia','Canada')[UNIFORM(0, 9, RANDOM())] AS country,
    player_level AS account_level,
    honor_level_raw AS honor_level,
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 5 THEN ARRAY_CONSTRUCT('CHALLENGER','GRANDMASTER','MASTER')[UNIFORM(0, 2, RANDOM())]
        WHEN UNIFORM(0, 100, RANDOM()) < 20 THEN ARRAY_CONSTRUCT('DIAMOND','PLATINUM')[UNIFORM(0, 1, RANDOM())]
        WHEN UNIFORM(0, 100, RANDOM()) < 50 THEN ARRAY_CONSTRUCT('GOLD','SILVER')[UNIFORM(0, 1, RANDOM())]
        ELSE ARRAY_CONSTRUCT('BRONZE','IRON','UNRANKED')[UNIFORM(0, 2, RANDOM())]
    END AS ranked_tier,
    ARRAY_CONSTRUCT('I','II','III','IV')[UNIFORM(0, 3, RANDOM())] AS ranked_division,
    (UNIFORM(10, 5000, RANDOM()) / 1.0)::NUMBER(10,2) AS total_playtime_hours,
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 90 THEN 'ACTIVE'
        WHEN UNIFORM(0, 100, RANDOM()) < 95 THEN 'SUSPENDED'
        ELSE 'BANNED'
    END AS account_status,
    CASE
        WHEN total_playtime_hours > 2000 THEN 'CORE'
        WHEN total_playtime_hours > 500 THEN 'ENGAGED'
        WHEN total_playtime_hours > 100 THEN 'CASUAL'
        ELSE 'NEW'
    END AS player_segment,
    ARRAY_CONSTRUCT('ORGANIC','SOCIAL_MEDIA','INFLUENCER','FRIEND_REFERRAL','ESPORTS_EVENT','ADVERTISEMENT')[UNIFORM(0, 5, RANDOM())] AS acquisition_channel,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS updated_at
FROM base;

-- ============================================================================
-- Step 3: Generate Match History
-- ============================================================================
INSERT INTO MATCH_HISTORY
SELECT
    'MATCH' || LPAD(SEQ4(), 10, '0') AS match_id,
    p.player_id,
    c.champion_id,
    DATEADD('minute', -1 * UNIFORM(0, 525600, RANDOM()), CURRENT_TIMESTAMP()) AS match_date,
    ARRAY_CONSTRUCT('CLASSIC_RANKED','CLASSIC_NORMAL','ARAM','URF','NEXUS_BLITZ','CLASH','CUSTOM')[UNIFORM(0, 6, RANDOM())] AS game_mode,
    UNIFORM(900, 3600, RANDOM()) AS match_duration_seconds,
    CASE WHEN UNIFORM(0, 100, RANDOM()) < 50 THEN 'WIN' ELSE 'LOSS' END AS result,
    UNIFORM(0, 30, RANDOM()) AS kills,
    UNIFORM(0, 15, RANDOM()) AS deaths,
    UNIFORM(0, 35, RANDOM()) AS assists,
    UNIFORM(5000, 25000, RANDOM()) AS gold_earned,
    UNIFORM(10000, 80000, RANDOM()) AS damage_dealt,
    UNIFORM(8000, 50000, RANDOM()) AS damage_taken,
    UNIFORM(5, 100, RANDOM()) AS vision_score,
    ARRAY_CONSTRUCT('TOP','JUNGLE','MID','ADC','SUPPORT')[UNIFORM(0, 4, RANDOM())] AS role_played,
    ARRAY_CONSTRUCT('RANKED_SOLO','RANKED_FLEX','NORMAL_DRAFT','NORMAL_BLIND','ARAM')[UNIFORM(0, 4, RANDOM())] AS queue_type,
    UNIFORM(1, 5, RANDOM()) AS premade_team_size,
    p.ranked_tier AS player_rank_at_match,
    UNIFORM(0, 100, RANDOM()) < 2 AS afk_flag,
    CURRENT_TIMESTAMP() AS created_at
FROM PLAYERS p
CROSS JOIN (SELECT champion_id FROM CHAMPIONS ORDER BY RANDOM() LIMIT 1) c
WHERE UNIFORM(0, 100, RANDOM()) < 60
LIMIT 500000;

-- ============================================================================
-- Step 4: Generate Skins
-- ============================================================================
INSERT INTO SKINS
SELECT
    'SKIN' || LPAD(SEQ4(), 6, '0') AS skin_id,
    c.champion_id,
    CONCAT(c.champion_name, ' ', 
           ARRAY_CONSTRUCT('Arcane','PROJECT','Star Guardian','K/DA','Pool Party','Blood Moon','Cosmic','Dark Star',
                          'High Noon','Elderwood','Spirit Blossom','Pulsefire','Dawnbringer','Nightbringer','Battle Academia',
                          'Hextech','Prestige','Championship','Victorious','Lunar Beast','Crime City','Battle Boss','Dragon',
                          'Mecha','Infernal','Steel Legion','Astronaut','Porcelain','Mythmaker','Bee','Cat','Dog')[UNIFORM(0, 30, RANDOM())]) AS skin_name,
    ARRAY_CONSTRUCT('STANDARD','EPIC','LEGENDARY','ULTIMATE','MYTHIC')[UNIFORM(0, 4, RANDOM())] AS rarity,
    CASE rarity
        WHEN 'STANDARD' THEN 520
        WHEN 'EPIC' THEN 1350
        WHEN 'LEGENDARY' THEN 1820
        WHEN 'ULTIMATE' THEN 3250
        ELSE 2000
    END AS price_rp,
    DATEADD('day', -1 * UNIFORM(1, 2000, RANDOM()), CURRENT_DATE()) AS release_date,
    UNIFORM(0, 100, RANDOM()) < 5 AS is_limited_edition,
    ARRAY_CONSTRUCT('Fantasy','Sci-Fi','Horror','Sports','Music','Holiday','Animals','Mecha')[UNIFORM(0, 7, RANDOM())] AS theme,
    CURRENT_TIMESTAMP() AS created_at
FROM CHAMPIONS c
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 10))
WHERE UNIFORM(0, 100, RANDOM()) < 60
LIMIT 1650;

-- ============================================================================
-- Step 5: Generate Purchases
-- ============================================================================
INSERT INTO PURCHASES
SELECT
    'TXN' || LPAD(SEQ4(), 12, '0') AS transaction_id,
    p.player_id,
    DATEADD('day', -1 * UNIFORM(0, 1095, RANDOM()), CURRENT_TIMESTAMP()) AS purchase_date,
    ARRAY_CONSTRUCT('SKIN','CHAMPION','RP_BUNDLE','BATTLE_PASS','LOOT_BOX','EMOTE','WARD_SKIN','ICON')[UNIFORM(0, 7, RANDOM())] AS item_type,
    CASE
        WHEN item_type = 'SKIN' THEN (SELECT skin_id FROM SKINS ORDER BY RANDOM() LIMIT 1)
        WHEN item_type = 'CHAMPION' THEN (SELECT champion_id FROM CHAMPIONS ORDER BY RANDOM() LIMIT 1)
        ELSE CONCAT('ITEM', UNIFORM(1000, 9999, RANDOM()))
    END AS item_id,
    CASE
        WHEN item_type = 'SKIN' THEN 'Cosmetic Skin'
        WHEN item_type = 'CHAMPION' THEN 'Champion Unlock'
        WHEN item_type = 'RP_BUNDLE' THEN CONCAT(ARRAY_CONSTRUCT(650, 1380, 2800, 5000, 7200)[UNIFORM(0, 4, RANDOM())], ' RP')
        WHEN item_type = 'BATTLE_PASS' THEN 'Battle Pass Token'
        ELSE item_type
    END AS item_name,
    CASE
        WHEN item_type IN ('SKIN','RP_BUNDLE','BATTLE_PASS') THEN 'USD'
        ELSE ARRAY_CONSTRUCT('USD','RP','BE')[UNIFORM(0, 2, RANDOM())]
    END AS currency_type,
    CASE
        WHEN currency_type = 'USD' THEN (UNIFORM(5, 100, RANDOM()) / 1.0)::NUMBER(12,2)
        ELSE 0
    END AS amount_usd,
    CASE
        WHEN currency_type = 'RP' THEN UNIFORM(200, 5000, RANDOM())
        WHEN item_type = 'SKIN' THEN UNIFORM(520, 1820, RANDOM())
        ELSE NULL
    END AS amount_rp,
    CASE
        WHEN currency_type = 'BE' THEN UNIFORM(450, 6300, RANDOM())
        ELSE NULL
    END AS amount_be,
    ARRAY_CONSTRUCT('CREDIT_CARD','PAYPAL','MOBILE_PAYMENT','GIFT_CARD','PREPAID_RP')[UNIFORM(0, 4, RANDOM())] AS payment_method,
    p.region AS region,
    ARRAY_CONSTRUCT('IN_GAME_STORE','WEB_STORE','MOBILE_APP')[UNIFORM(0, 2, RANDOM())] AS purchase_channel,
    UNIFORM(0, 100, RANDOM()) < 15 AS promotion_applied,
    UNIFORM(0, 100, RANDOM()) < 3 AS refund_flag,
    CURRENT_TIMESTAMP() AS created_at
FROM PLAYERS p
JOIN TABLE(GENERATOR(ROWCOUNT => 3)) g
WHERE p.account_status = 'ACTIVE'
  AND UNIFORM(0, 100, RANDOM()) < 50
LIMIT 150000;

-- ============================================================================
-- Step 6: Generate Player Interactions
-- ============================================================================
INSERT INTO PLAYER_INTERACTIONS
SELECT
    'INT' || LPAD(SEQ4(), 10, '0') AS interaction_id,
    p.player_id,
    DATEADD('day', -1 * UNIFORM(0, 365, RANDOM()), CURRENT_TIMESTAMP()) AS interaction_date,
    ARRAY_CONSTRUCT('BUG_REPORT','ACCOUNT_RECOVERY','PAYMENT_ISSUE','BAN_APPEAL','TOXICITY_REPORT','TECHNICAL_SUPPORT','FEATURE_REQUEST','GENERAL_INQUIRY')[UNIFORM(0, 7, RANDOM())] AS interaction_type,
    ARRAY_CONSTRUCT('PHONE','CHAT','EMAIL','TICKET_SYSTEM','SOCIAL_MEDIA')[UNIFORM(0, 4, RANDOM())] AS channel,
    ARRAY_CONSTRUCT('Sarah Chen','Marcus Rodriguez','Aisha Patel','Tom Wilson','Yuki Tanaka','Maria Silva')[UNIFORM(0, 5, RANDOM())] AS agent_name,
    ARRAY_CONSTRUCT('Login issues','Payment failure','Skin not received','Report toxic player','Game crash','Connection problems','Account hacked','Refund request')[UNIFORM(0, 7, RANDOM())] AS topic,
    ARRAY_CONSTRUCT('RESOLVED','ESCALATED','FOLLOW_UP','INFO_PROVIDED','CLOSED')[UNIFORM(0, 4, RANDOM())] AS outcome,
    (UNIFORM(100, 1000, RANDOM()) / 100.0)::NUMBER(5,2) AS sentiment_score,
    'Support interaction for ' || topic || ' via ' || channel || ' outcome ' || outcome AS notes,
    CASE WHEN outcome IN ('FOLLOW_UP','ESCALATED') THEN DATEADD('day', UNIFORM(2, 14, RANDOM()), CURRENT_DATE()) END AS follow_up_date,
    outcome = 'ESCALATED' AS escalation_flag,
    CURRENT_TIMESTAMP() AS created_at
FROM PLAYERS p
JOIN TABLE(GENERATOR(ROWCOUNT => 2)) g
WHERE UNIFORM(0, 100, RANDOM()) < 40
LIMIT 80000;

-- ============================================================================
-- Step 7: Generate Support Transcripts
-- ============================================================================
INSERT INTO SUPPORT_TRANSCRIPTS
SELECT
    'TRANS' || LPAD(SEQ4(), 10, '0') AS transcript_id,
    pi.interaction_id,
    pi.player_id,
    CASE (ABS(RANDOM()) % 5)
        WHEN 0 THEN 'Agent: Thanks for contacting Riot Support, this is ' || pi.agent_name ||
            '. Player: I purchased a skin but didn''t receive it. Agent: I see the transaction in our system. The skin has been granted to your account. Please restart your client.' ||
            ' Player: Got it, thanks! Agent: You''re welcome. Enjoy your new skin!'
        WHEN 1 THEN 'Chat log - player reported toxic teammate. Agent reviewed chat logs and confirmed verbal abuse. Issued 14-day suspension to reported player. Notified reporter of action taken.'
        WHEN 2 THEN 'Email thread regarding payment failure. Player''s credit card was declined due to insufficient funds. Agent recommended trying alternative payment method or adding funds to account.'
        WHEN 3 THEN 'Phone call about account recovery. Player forgot password and no longer has access to registered email. Agent verified identity through security questions and updated email address.'
        ELSE 'Ticket regarding connection issues during ranked game. Agent ran diagnostics, identified ISP routing problem. Provided loss prevention LP adjustment due to server-side issue.'
    END AS transcript_text,
    pi.channel AS interaction_channel,
    pi.interaction_date AS transcript_date,
    pi.agent_name AS agent_id,
    ARRAY_CONSTRUCT('PAYMENT','TECHNICAL','TOXICITY','ACCOUNT','GENERAL')[UNIFORM(0, 4, RANDOM())] AS issue_category,
    ARRAY_CONSTRUCT('OPEN','IN_PROGRESS','RESOLVED')[UNIFORM(0, 2, RANDOM())] AS resolution_status,
    CURRENT_TIMESTAMP() AS created_at
FROM PLAYER_INTERACTIONS pi
WHERE UNIFORM(0, 100, RANDOM()) < 20
LIMIT 12000;

-- ============================================================================
-- Step 8: Seed Policy Documents
-- ============================================================================
INSERT INTO POLICY_DOCUMENTS VALUES
('POLICY001', 'Riot Games Terms of Service',
 $$RIOT GAMES TERMS OF SERVICE
Core topics: Account ownership, acceptable use policy, intellectual property rights, virtual goods policy, dispute resolution, and termination conditions. Updated quarterly to reflect legal and regulatory requirements.$$,
 'LEGAL', 'LEGAL', 'Legal Team', '2025-01-15', 'v12.3', 'terms, legal, tos',
 CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
('POLICY002', 'Player Behavior and Code of Conduct',
 $$Player Behavior Standards:
1. Zero tolerance for hate speech, harassment, or threats
2. Gameplay integrity - no cheating, scripting, or exploiting
3. Sportsmanship expectations in all game modes
4. Punishment framework: warnings, chat restrictions, suspensions, permanent bans$$,
 'COMMUNITY', 'PLAYER_SUPPORT', 'Community Team', '2024-11-01', 'v8.1', 'behavior, conduct, toxicity',
 CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
('POLICY003', 'Virtual Goods and Monetization Policy',
 $$Guidelines for in-game purchases, Riot Points (RP), Blue Essence (BE), skin pricing, refund policies, and loot box disclosure requirements.
Covers regional pricing adjustments and promotional event rules.$$,
 'MONETIZATION', 'COMMERCE', 'Commerce Team', '2025-03-01', 'v5.2', 'purchases, RP, monetization',
 CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
('POLICY004', 'Anti-Cheat and Security Guidelines',
 $$Anti-cheat system (Vanguard) documentation, detection methods, appeal process for false positives, and security best practices for players.
Includes information on two-factor authentication and account security recommendations.$$,
 'SECURITY', 'ANTI_CHEAT', 'Security Team', '2025-02-10', 'v4.7', 'anti-cheat, security, vanguard',
 CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

-- ============================================================================
-- Step 9: Generate Incident Reports
-- ============================================================================
INSERT INTO INCIDENT_REPORTS
SELECT
    'INC' || LPAD(SEQ4(), 9, '0') AS incident_report_id,
    p.player_id,
    m.match_id,
    'Incident summary for player ' || p.player_id || ': ' ||
    CASE (ABS(RANDOM()) % 5)
        WHEN 0 THEN 'Automated system detected unusual mouse movement patterns consistent with scripting. Investigation confirmed use of third-party software. Account permanently banned.'
        WHEN 1 THEN 'Multiple players reported toxic behavior including hate speech in post-game lobby. Chat logs reviewed. Issued 14-day suspension and honor level reset.'
        WHEN 2 THEN 'Player reported game-breaking bug allowing infinite gold generation. Bug reproduced and escalated to dev team. Player received bug bounty reward.'
        WHEN 3 THEN 'AFK detection triggered - player disconnected for 15+ minutes in ranked match. Loss prevention applied to team. Player received leaver penalty.'
        ELSE 'Payment dispute escalation. Player claimed unauthorized charges. Investigation found account sharing. Refund denied, account suspended pending password reset.'
    END AS report_text,
    ARRAY_CONSTRUCT('CHEATING','TOXICITY','BUG_EXPLOIT','AFK_GRIEFING','PAYMENT_FRAUD','ACCOUNT_SHARING','TECHNICAL')[UNIFORM(0, 6, RANDOM())] AS incident_type,
    ARRAY_CONSTRUCT('LOW','MEDIUM','HIGH','CRITICAL')[UNIFORM(0, 3, RANDOM())] AS severity,
    ARRAY_CONSTRUCT('OPEN','INVESTIGATING','RESOLVED','CLOSED')[UNIFORM(0, 3, RANDOM())] AS status,
    'Key findings documented for ' || incident_type || ' severity ' || severity AS findings_summary,
    'Recommendations: enhance detection systems, update policies, player education campaign' AS recommendations,
    DATEADD('day', -1 * UNIFORM(0, 180, RANDOM()), CURRENT_TIMESTAMP()) AS report_date,
    ARRAY_CONSTRUCT('Anti-Cheat Team','Player Support','Security Team','Community Ops')[UNIFORM(0, 3, RANDOM())] AS investigator,
    CURRENT_TIMESTAMP() AS created_at
FROM PLAYERS p
LEFT JOIN (SELECT player_id, match_id FROM MATCH_HISTORY ORDER BY RANDOM() LIMIT 15000) m ON p.player_id = m.player_id
WHERE UNIFORM(0, 100, RANDOM()) < 30
LIMIT 15000;

-- ============================================================================
-- Step 10: Generate Churn Events
-- ============================================================================
INSERT INTO CHURN_EVENTS
SELECT
    'CHURN' || LPAD(SEQ4(), 9, '0') AS event_id,
    p.player_id,
    DATEADD('day', -1 * UNIFORM(0, 365, RANDOM()), CURRENT_DATE()) AS event_date,
    ARRAY_CONSTRUCT('INACTIVITY_7_DAYS','INACTIVITY_30_DAYS','INACTIVITY_90_DAYS','CHURN_PREDICTION','RE_ENGAGEMENT')[UNIFORM(0, 4, RANDOM())] AS event_type,
    UNIFORM(7, 180, RANDOM()) AS days_since_last_login,
    (UNIFORM(10, 95, RANDOM()) / 100.0)::NUMBER(5,2) AS churn_risk_score,
    UNIFORM(0, 100, RANDOM()) < 30 AS intervention_attempted,
    'Churn risk assessment for player segment ' || p.player_segment AS notes,
    CURRENT_TIMESTAMP() AS created_at
FROM PLAYERS p
WHERE p.player_segment IN ('CASUAL','NEW')
  AND UNIFORM(0, 100, RANDOM()) < 40
LIMIT 10000;

-- ============================================================================
-- Completion Summary
-- ============================================================================
SELECT
    'Riot Games synthetic data generation completed' AS STATUS,
    (SELECT COUNT(*) FROM PLAYERS) AS players,
    (SELECT COUNT(*) FROM CHAMPIONS) AS champions,
    (SELECT COUNT(*) FROM MATCH_HISTORY) AS match_history_rows,
    (SELECT COUNT(*) FROM PURCHASES) AS purchases,
    (SELECT COUNT(*) FROM SKINS) AS skins,
    (SELECT COUNT(*) FROM PLAYER_INTERACTIONS) AS interactions,
    (SELECT COUNT(*) FROM SUPPORT_TRANSCRIPTS) AS transcripts,
    (SELECT COUNT(*) FROM POLICY_DOCUMENTS) AS policy_documents,
    (SELECT COUNT(*) FROM INCIDENT_REPORTS) AS incident_reports,
    (SELECT COUNT(*) FROM CHURN_EVENTS) AS churn_events;
