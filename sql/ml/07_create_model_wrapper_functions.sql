-- ============================================================================
-- Riot Games Intelligence Agent - ML Wrapper Procedures
-- ============================================================================
-- Purpose: Expose ML models from Model Registry as callable stored procedures
-- ============================================================================

USE DATABASE RIOT_GAMES_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE RIOT_GAMES_SI_WH;

-- ============================================================================
-- Procedure 1: Revenue Forecast Wrapper
-- ============================================================================
DROP PROCEDURE IF EXISTS PREDICT_REVENUE(INT);

CREATE OR REPLACE PROCEDURE PREDICT_REVENUE(
    months_ahead INT
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-ml-python', 'pandas')
HANDLER = 'predict_revenue'
COMMENT = 'Invokes REVENUE_FORECASTER model to project future revenue trends'
AS
$$
import json
from datetime import date
from dateutil.relativedelta import relativedelta
import pandas as pd
from snowflake.ml.registry import Registry

def predict_revenue(session, months_ahead: int):
    reg = Registry(session)
    model = reg.get_model("REVENUE_FORECASTER").default

    # Query for the last available month of data to use as a baseline
    base_query = """
    SELECT
        DATE_TRUNC('month', purchase_date)::DATE AS purchase_month,
        COUNT(DISTINCT player_id)::FLOAT AS player_count,
        AVG(amount_usd)::FLOAT AS avg_transaction_amount,
        COUNT(DISTINCT CASE WHEN item_type = 'SKIN' THEN transaction_id END)::FLOAT AS skin_purchase_count
    FROM RAW.PURCHASES
    WHERE amount_usd > 0
    ORDER BY purchase_month DESC
    LIMIT 1
    """
    base_df = session.sql(base_query).to_pandas()
    base_date = pd.to_datetime(base_df['PURCHASE_MONTH'].iloc[0])
    
    # Generate future dates and features for prediction
    future_dates = [base_date + relativedelta(months=i) for i in range(1, months_ahead + 1)]
    future_features_list = []
    for dt in future_dates:
        future_features_list.append({
            "MONTH_NUM": dt.month,
            "YEAR_NUM": dt.year,
            "PLAYER_COUNT": base_df['PLAYER_COUNT'].iloc[0],
            "AVG_TRANSACTION_AMOUNT": base_df['AVG_TRANSACTION_AMOUNT'].iloc[0],
            "SKIN_PURCHASE_COUNT": base_df['SKIN_PURCHASE_COUNT'].iloc[0]
        })

    input_df = session.create_dataframe(pd.DataFrame(future_features_list))
    
    # Make predictions
    preds = model.run(input_df, function_name="predict")
    
    # Combine predictions with future dates for clarity
    preds_pdf = preds.to_pandas()
    results_df = pd.DataFrame({
        "FORECAST_MONTH": [d.strftime('%Y-%m') for d in future_dates],
        "PREDICTED_REVENUE_USD": preds_pdf["PREDICTED_REVENUE"]
    })

    return json.dumps({
        "months_ahead": months_ahead,
        "prediction": results_df.to_dict(orient="records")
    })
$$;

-- ============================================================================
-- Procedure 2: Player Churn Risk Wrapper
-- ============================================================================
DROP PROCEDURE IF EXISTS PREDICT_CHURN_RISK(VARCHAR);

CREATE OR REPLACE PROCEDURE PREDICT_CHURN_RISK(
    player_segment VARCHAR
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-ml-python', 'pandas')
HANDLER = 'predict_churn'
COMMENT = 'Invokes CHURN_RISK_MODEL to identify players at risk of leaving'
AS
$$
def predict_churn(session, player_segment):
    from snowflake.ml.registry import Registry
    import json

    reg = Registry(session)
    model = reg.get_model("CHURN_RISK_MODEL").default

    segment_clause = f"AND p.player_segment = '{player_segment}'" if player_segment and player_segment.upper() != 'ALL' else ""

    query = f"""
    SELECT
        p.player_id,
        p.player_segment AS segment,
        p.ranked_tier AS rank,
        p.account_level::FLOAT AS account_level,
        p.honor_level::FLOAT AS honor_level,
        p.total_playtime_hours::FLOAT AS total_playtime_hours,
        COUNT(DISTINCT m.match_id)::FLOAT AS total_matches,
        COALESCE(SUM(pur.amount_usd), 0)::FLOAT AS lifetime_spending,
        DATEDIFF('day', MAX(m.match_date), CURRENT_DATE())::FLOAT AS days_since_last_match,
        COUNT_IF(m.afk_flag)::FLOAT AS afk_count,
        (DATEDIFF('day', MAX(m.match_date), CURRENT_DATE()) > 30)::BOOLEAN AS is_churned
    FROM RAW.PLAYERS p
    LEFT JOIN RAW.MATCH_HISTORY m ON p.player_id = m.player_id
    LEFT JOIN RAW.PURCHASES pur ON p.player_id = pur.player_id
    WHERE 1=1 {segment_clause}
    GROUP BY 1,2,3,4,5,6
    LIMIT 500
    """

    input_df = session.sql(query).drop("PLAYER_ID")

    preds = model.run(input_df, function_name="predict")
    pdf = preds.to_pandas()

    return json.dumps({
        "player_segment": player_segment or "ALL",
        "results": pdf.to_dict(orient="records")
    })
$$;

-- ============================================================================
-- Procedure 3: Toxicity Risk Prediction Wrapper
-- ============================================================================
DROP PROCEDURE IF EXISTS PREDICT_TOXICITY_RISK(VARCHAR);

CREATE OR REPLACE PROCEDURE PREDICT_TOXICITY_RISK(
    player_segment VARCHAR
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-ml-python', 'pandas')
HANDLER = 'predict_toxicity'
COMMENT = 'Invokes TOXICITY_PREDICTION_MODEL to assess behavior incident likelihood'
AS
$$
def predict_toxicity(session, player_segment):
    from snowflake.ml.registry import Registry
    import json

    reg = Registry(session)
    model = reg.get_model("TOXICITY_PREDICTION_MODEL").default

    segment_clause = f"AND p.player_segment = '{player_segment}'" if player_segment and player_segment.upper() != 'ALL' else ""

    query = f"""
    SELECT
        p.player_id,
        p.player_segment AS segment,
        p.ranked_tier AS rank,
        p.honor_level::FLOAT AS honor_level,
        COUNT(DISTINCT m.match_id)::FLOAT AS total_matches,
        COUNT_IF(m.afk_flag)::FLOAT AS afk_count,
        AVG(m.deaths)::FLOAT AS avg_deaths,
        COUNT(DISTINCT ir.incident_report_id)::FLOAT AS past_incidents,
        DATEDIFF('day', p.account_created_date, CURRENT_DATE())::FLOAT AS account_age_days,
        (COUNT(DISTINCT ir.incident_report_id) > 0)::BOOLEAN AS has_incident
    FROM RAW.PLAYERS p
    LEFT JOIN RAW.MATCH_HISTORY m ON p.player_id = m.player_id
    LEFT JOIN RAW.INCIDENT_REPORTS ir ON p.player_id = ir.player_id
    WHERE 1=1 {segment_clause}
    GROUP BY 1,2,3,4,9
    LIMIT 500
    """

    input_df = session.sql(query).drop("PLAYER_ID")

    preds = model.run(input_df, function_name="predict")
    pdf = preds.to_pandas()

    return json.dumps({
        "player_segment": player_segment or "ALL",
        "results": pdf.to_dict(orient="records")
    })
$$;

-- ============================================================================
-- Confirmation
-- ============================================================================
SELECT 'Riot Games ML wrapper procedures created successfully' AS STATUS;
