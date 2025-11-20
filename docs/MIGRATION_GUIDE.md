# Riot Games Intelligence Agent - File Migration Guide

## Creating the New Workspace

### Step 1: Create New Workspace in Snowsight
1. In Snowsight, go to **Projects** → **Worksheets**
2. Click the workspace dropdown (currently showing "Applied-Data-Finance")
3. Click **"+ New Workspace"**
4. Name it: **"Riot-Games"**

### Step 2: Copy These Modified/New Files

#### ✅ Core Documentation
- **README.md** - ✨ MODIFIED - Complete Riot Games documentation

#### ✅ SQL Setup Scripts
- **sql/setup/01_database_and_schema.sql** - ✨ NEW - Riot Games database
- **sql/setup/02_create_tables.sql** - ✨ NEW - 10 gaming tables

#### ✅ Data Generation
- **sql/data/03_generate_synthetic_data.sql** - ✨ NEW - 867k gaming records

#### ✅ Views
- **sql/views/04_create_views.sql** - ✨ NEW - 8 analytical views
- **sql/views/05_create_semantic_views.sql** - ✨ NEW - 3 semantic views for Cortex Analyst

#### ✅ Search Services
- **sql/search/06_create_cortex_search.sql** - ✨ NEW - 3 Cortex Search services

#### ✅ ML Components
- **sql/ml/07_create_model_wrapper_functions.sql** - ✨ NEW - 3 ML wrapper procedures
- **notebooks/riot_ml_models.ipynb** - ✨ NEW - ML model training notebook

#### ✅ Agent Configuration
- **sql/agent/08_create_intelligence_agent.sql** - ✨ NEW - Riot Games Intelligence Agent

#### 📋 Files to Keep Unchanged (Copy as Reference)
- **Snowflake_Logo.svg** - Logo image
- **.gitignore** - Git configuration
- **notebooks/environment.yml** - Python environment spec
- **questions.md** - Example questions (optional)
- **docs/*.html** - Snowflake documentation references (keep for syntax validation)

---

## Quick Copy Commands

If you have access to the file system, you can use these commands:

```bash
# Create new workspace structure
mkdir -p Riot-Games/sql/{setup,data,views,search,ml,agent}
mkdir -p Riot-Games/notebooks
mkdir -p Riot-Games/docs

# Copy modified files
cp README.md Riot-Games/
cp sql/setup/01_database_and_schema.sql Riot-Games/sql/setup/
cp sql/setup/02_create_tables.sql Riot-Games/sql/setup/
cp sql/data/03_generate_synthetic_data.sql Riot-Games/sql/data/
cp sql/views/04_create_views.sql Riot-Games/sql/views/
cp sql/views/05_create_semantic_views.sql Riot-Games/sql/views/
cp sql/search/06_create_cortex_search.sql Riot-Games/sql/search/
cp sql/ml/07_create_model_wrapper_functions.sql Riot-Games/sql/ml/
cp sql/agent/08_create_intelligence_agent.sql Riot-Games/sql/agent/
cp notebooks/riot_ml_models.ipynb Riot-Games/notebooks/

# Copy reference files
cp Snowflake_Logo.svg Riot-Games/
cp .gitignore Riot-Games/
cp notebooks/environment.yml Riot-Games/notebooks/
cp -r docs/ Riot-Games/
```

---

## File Inventory

### Total Files: 13 New/Modified

#### New Files (11):
1. `sql/setup/01_database_and_schema.sql`
2. `sql/setup/02_create_tables.sql`
3. `sql/data/03_generate_synthetic_data.sql`
4. `sql/views/04_create_views.sql`
5. `sql/views/05_create_semantic_views.sql`
6. `sql/search/06_create_cortex_search.sql`
7. `sql/ml/07_create_model_wrapper_functions.sql`
8. `sql/agent/08_create_intelligence_agent.sql`
9. `notebooks/riot_ml_models.ipynb`

#### Modified Files (1):
1. `README.md`

---

## Verification Checklist

After copying to new workspace, verify:

- [ ] All SQL files are in correct directories
- [ ] README.md shows "Riot Games" not "Applied Data Finance"
- [ ] Notebook is named `riot_ml_models.ipynb`
- [ ] Database names reference `RIOT_GAMES_INTELLIGENCE`
- [ ] Agent name is `RIOT_GAMES_INTELLIGENCE_AGENT`
- [ ] No references to ADF or Applied Data Finance remain

---

## Key Differences from Applied Data Finance

| Aspect | Applied Data Finance | Riot Games |
|--------|---------------------|------------|
| **Database** | ADF_INTELLIGENCE | RIOT_GAMES_INTELLIGENCE |
| **Warehouse** | ADF_SI_WH | RIOT_GAMES_SI_WH |
| **Agent Name** | ADF_INTELLIGENCE_AGENT | RIOT_GAMES_INTELLIGENCE_AGENT |
| **Tables** | 9 (lending focused) | 10 (gaming focused) |
| **Records** | ~360k | ~867k |
| **ML Models** | Payment/Borrower/Collection | Revenue/Churn/Toxicity |
| **Semantic Views** | 3 (lending) | 3 (gaming) |

---

## Next Steps After Migration

1. **Test the setup**: Run all SQL scripts in order (see README.md)
2. **Train models**: Execute the riot_ml_models.ipynb notebook
3. **Deploy agent**: Run the agent creation script
4. **Verify**: Test agent with sample questions from README.md

---

## Support

If you encounter issues during migration:
1. Check that all file paths are correct
2. Verify database/warehouse names are updated
3. Ensure all references to "ADF" are changed to "RIOT_GAMES"
4. Review the main README.md for troubleshooting steps

---

**Riot Games Intelligence Agent**  
*Complete workspace migration from Applied Data Finance template*  
*Generated with Snowflake Cortex*
