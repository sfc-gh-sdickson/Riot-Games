-- ============================================================================
-- Riot Games Intelligence Agent - Database and Schema Setup
-- ============================================================================
-- Purpose: Initialize the database, schemas, and warehouse for the Riot Games SI solution
-- ============================================================================

-- Create the database
CREATE DATABASE IF NOT EXISTS RIOT_GAMES_INTELLIGENCE;

-- Use the database
USE DATABASE RIOT_GAMES_INTELLIGENCE;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- Create a virtual warehouse for query processing
CREATE OR REPLACE WAREHOUSE RIOT_GAMES_SI_WH WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for Riot Games SI workloads';

-- Set the warehouse as active
USE WAREHOUSE RIOT_GAMES_SI_WH;

-- Display confirmation
SELECT 'Riot Games database, schema, and warehouse setup completed successfully' AS STATUS;
