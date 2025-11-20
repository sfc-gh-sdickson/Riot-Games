<img src="Snowflake_Logo.svg" alt="Snowflake Logo" width="33%">

# Riot Games Snowflake Intelligence Agent

This package adapts the Applied Data Finance SI pattern for the Riot Games gaming business model. Run the assets in order to provision databases, load synthetic gaming data, build semantic layers, publish Cortex Search services, register ML models, and deploy the Riot Games Intelligence Agent.

## Business Model Overview

Riot Games operates on a **free-to-play** model with revenue generated through:
- **Cosmetic Purchases**: Skins, emotes, icons, ward skins
- **Premium Currency**: Riot Points (RP) purchased with real money
- **Earned Currency**: Blue Essence (BE) earned through gameplay
- **Battle Passes**: Seasonal content and rewards
- **Player Engagement**: Ranked competitive play, esports integration, and community events

## 1. Prerequisites

- Snowflake role with `ACCOUNTADMIN`-level privileges (or equivalent grants)
- Snowsight access for running SQL scripts and notebooks
- Warehouses with Snowpark and Cortex features enabled

## 2. Execution Order

| Step | File | Purpose |
|------|------|---------|
| 1 | `sql/setup/01_database_and_schema.sql` | Creates `RIOT_GAMES_INTELLIGENCE`, `RAW`, `ANALYTICS`, and warehouse `RIOT_GAMES_SI_WH` |
| 2 | `sql/setup/02_create_tables.sql` | Defines player, match, purchase, champion, and support tables |
| 3 | `sql/data/03_generate_synthetic_data.sql` | Populates synthetic gaming data using Snowflake generators |
| 4 | `sql/views/04_create_views.sql` | Creates curated analytical views |
| 5 | `sql/views/05_create_semantic_views.sql` | Creates Cortex Analyst semantic views |
| 6 | `sql/search/06_create_cortex_search.sql` | Enables change tracking and creates Cortex Search services |
| 7 | `notebooks/riot_ml_models.ipynb` | Trains and registers three ML models |
| 8 | `sql/ml/07_create_model_wrapper_functions.sql` | Wraps registry models in Snowflake procedures |
| 9 | `sql/agent/08_create_intelligence_agent.sql` | Grants privileges and creates the Riot Games Intelligence Agent |

## 3. Data Model

### Core Tables (~867k total records)

- **PLAYERS** (~50k): Player accounts, profiles, ranked status, segments (CORE, ENGAGED, CASUAL, NEW)
- **CHAMPIONS** (165): Playable champions with roles, difficulty, and pricing
- **MATCH_HISTORY** (~500k): Game results with KDA, damage, gold, vision scores
- **PURCHASES** (~150k): In-game transactions (skins, RP bundles, champions, battle passes)
- **SKINS** (~1,650): Cosmetic items with rarity tiers and themes
- **PLAYER_INTERACTIONS** (~80k): Support tickets and player contacts
- **SUPPORT_TRANSCRIPTS** (~12k): Unstructured support conversations
- **POLICY_DOCUMENTS** (4): Game policies, ToS, community guidelines
- **INCIDENT_REPORTS** (~15k): Cheating, toxicity, bugs, technical issues
- **CHURN_EVENTS** (~10k): Player retention and inactivity tracking

## 4. Data Generation Notes

- All synthetic data is created directly inside Snowflake using `TABLE(GENERATOR())`, `UNIFORM`, and `ARRAY_CONSTRUCT` functions (Step 3).
- Generates realistic gaming patterns: match histories, purchase behaviors, champion preferences, and support interactions
- No external files are required; run Step 3 once per environment.
- Data includes regional distribution (NA, EUW, KR, CN, etc.) and player segments

## 5. Cortex Search & Unstructured Data

- `SUPPORT_TRANSCRIPTS`, `POLICY_DOCUMENTS`, and `INCIDENT_REPORTS` tables have change tracking enabled prior to indexing.
- Three search services created:
  - **SUPPORT_TRANSCRIPTS_SEARCH**: Semantic search over player support conversations
  - **POLICY_DOCUMENTS_SEARCH**: Search game policies and community guidelines
  - **INCIDENT_REPORTS_SEARCH**: Search cheating, toxicity, and technical incidents
- Query services from the SI agent or via `SELECT * FROM TABLE(SNOWFLAKE.CORTEX_SEARCH(...))` once deployed.

## 6. Cortex Analyst Setup

- Semantic views expose three domains:
  - **SV_PLAYER_ENGAGEMENT**: Player activity, match performance, champion stats
  - **SV_MONETIZATION_INTELLIGENCE**: Revenue, purchases, player spending behavior
  - **SV_PLAYER_SUPPORT_INTELLIGENCE**: Support interactions, transcripts, incidents
- Grant `SNOWFLAKE.CORTEX_ANALYST_USER` plus `REFERENCES, SELECT` on each semantic view before creating the agent (Step 9).

## 7. Notebook & ML Models

- Import `notebooks/riot_ml_models.ipynb` into Snowsight and apply the included packages.
- Models registered:
  1. **REVENUE_FORECASTER**: Predicts future monthly revenue from player purchases
  2. **CHURN_RISK_MODEL**: Identifies players at risk of leaving the game
  3. **TOXICITY_PREDICTION_MODEL**: Assesses likelihood of player behavior incidents
- After notebook execution, run `sql/ml/07_create_model_wrapper_functions.sql` to expose the models as stored procedures for the agent.

## 8. Intelligence Agent Tools

The **RIOT_GAMES_INTELLIGENCE_AGENT** has access to:

### Cortex Analyst (Text-to-SQL)
- **PlayerEngagementAnalyst**: Query match data, champion performance, player activity
- **MonetizationAnalyst**: Analyze revenue, purchases, ARPU, LTV
- **PlayerSupportAnalyst**: Examine support interactions, sentiment, resolution metrics

### Cortex Search (Semantic Search)
- **SupportTranscriptsSearch**: Find relevant support conversations
- **PolicyDocumentsSearch**: Search game policies and guidelines
- **IncidentReportsSearch**: Discover cheating, toxicity, and technical incidents

### ML Predictions (Generic Tools)
- **PredictRevenue**: Forecast future revenue trends
- **PredictChurnRisk**: Identify at-risk players by segment
- **PredictToxicityRisk**: Assess behavior incident probability

## 9. Example Questions for the Agent

### Player Engagement
- "How many active players do we have by region?"
- "What is the average win rate for Diamond tier players?"
- "Which champions have the highest pick rate this month?"
- "Show me match completion rates by game mode"

### Monetization
- "What is our total revenue this quarter by region?"
- "Which skin themes generate the most revenue?"
- "Show me average revenue per user by player segment"
- "What percentage of players are paying customers?"

### Support & Operations
- "Search support transcripts about payment failures"
- "Show me recent toxicity incident reports"
- "What are the top support topics this month?"
- "Which policies cover account recovery procedures?"

### ML-Powered Insights
- "Predict revenue for the next 6 months"
- "Identify CASUAL players at high churn risk"
- "Which player segments have the highest toxicity risk?"

## 10. Testing Checklist

1. `SHOW TABLES IN RIOT_GAMES_INTELLIGENCE.RAW;`
2. `SELECT COUNT(*) FROM RIOT_GAMES_INTELLIGENCE.RAW.PLAYERS;`
3. `SELECT COUNT(*) FROM RIOT_GAMES_INTELLIGENCE.RAW.MATCH_HISTORY;`
4. `SHOW SEMANTIC VIEWS IN SCHEMA RIOT_GAMES_INTELLIGENCE.ANALYTICS;`
5. `SHOW CORTEX SEARCH SERVICES IN SCHEMA RIOT_GAMES_INTELLIGENCE.RAW;`
6. `SHOW MODELS IN SCHEMA RIOT_GAMES_INTELLIGENCE.ANALYTICS;`
7. `CHAT` with `RIOT_GAMES_INTELLIGENCE_AGENT` in Snowsight.

## 11. Key Metrics Tracked

### Player Metrics
- Monthly Active Users (MAU) by region
- Average Session Duration
- Match Completion Rate
- Win Rate by Champion/Role/Tier
- Honor Level Distribution

### Revenue Metrics
- Average Revenue Per User (ARPU)
- Lifetime Value (LTV) by cohort
- Conversion Rate (Free → Paying)
- Revenue by Item Type (Skins, RP, Battle Passes)
- Revenue by Region

### Community Health
- Incident Report Volume by Type
- Toxicity Detection Rate
- Support Ticket Resolution Time
- Player Sentiment Scores
- Churn Risk Distribution

## 12. Differences from Applied Data Finance

| Aspect | Applied Data Finance | Riot Games |
|--------|---------------------|------------|
| **Domain** | Lending & Loan Servicing | Gaming & Player Engagement |
| **Core Entities** | Borrowers, Loans, Payments, Collections | Players, Champions, Matches, Purchases |
| **Revenue Model** | Interest Income & Fees | Cosmetic Purchases (Skins, RP) |
| **Risk Focus** | Credit Risk & Delinquency | Churn Risk & Toxicity |
| **Key Metrics** | Outstanding Principal, DPD, Approval Rate | MAU, ARPU, Win Rate, Honor Level |
| **ML Models** | Payment Forecast, Default Risk, PTP Success | Revenue Forecast, Churn Risk, Toxicity |
| **Data Volume** | ~360k records | ~867k records |

## 13. Support

For questions or issues:
- Review `docs/AGENT_SETUP.md` for detailed agent configuration
- Check Snowflake Cortex documentation
- Contact your Snowflake account team

---

**Riot Games Intelligence Agent**  
*Adapted from Applied Data Finance Intelligence Agent template*  
*Generated with Snowflake Cortex*
