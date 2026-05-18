from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import RealDictCursor

load_dotenv()

app = FastAPI(title = "Athletic Data ETL Pipeline API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SplitPayload(BaseModel):
    id: int
    athleteId: int
    rawTime: str
    raceContext: str
    syncStatus: str

class MeetPayload(BaseModel):
    meet_name: str
    meet_date: str
    location: str
    season: str

def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        cursor_factory=RealDictCursor
    )

@app.post("/api/sync-splits")
async def sync_splits(payloads: list[SplitPayload]):
    if not payloads:
        raise HTTPException(status_code=400, detail="No splits data provided.")

    conn = get_db_connection()
    cursor = conn.cursor()
    inserted_count = 0
    
    try:
        # CHRONOLOGICAL SORTING LAYER
        # We sort the entire incoming batch by rawTime ascending.
        # This guarantees Lap 1 is ALWAYS mathematically smaller than Lap 2,
        # no matter what order the coach clicked them or assigned them!
        payloads.sort(key=lambda x: x.rawTime)

        for item in payloads:
            # 1. Relational Lookup for entry_id
            cursor.execute(
                "SELECT entry_id FROM race_entries WHERE athlete_id = %s LIMIT 1;",
                (item.athleteId,)
            )
            result = cursor.fetchone()
            
            if result:
                entry_id = result['entry_id']
            else:
                cursor.execute(
                    """
                    INSERT INTO race_entries (athlete_id, meet_id, event_distance) 
                    VALUES (%s, 1, 5000) RETURNING entry_id;
                    """,
                    (item.athleteId,)
                )
                entry_id = cursor.fetchone()['entry_id']

            # 2. Dynamic Lap Number Calculation
            cursor.execute("SELECT COUNT(*) FROM splits WHERE entry_id = %s;", (entry_id,))
            next_lap = cursor.fetchone()['count'] + 1

            # 3. Format Interval
            formatted_interval = f"00:{item.rawTime}"

            # 4. Insert Record
            insert_query = """
                INSERT INTO splits (entry_id, lap_number, cumulative_time, lap_time)
                VALUES (%s, %s, %s, %s);
            """
            cursor.execute(insert_query, (entry_id, next_lap, formatted_interval, formatted_interval))
            inserted_count += 1
            
        conn.commit()
        print(f" Successfully synchronized {inserted_count} chronologically sorted splits!")
        return {"status": "success", "message": f"Successfully loaded {inserted_count} records."}

    except Exception as e:
        conn.rollback()
        print(f" Pipeline Loading Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
        
    finally:
        cursor.close()
        conn.close()

@app.get("/")
def read_root():
    return {"status": "online", "message": "XC Ingestion Pipeline Control Tower Running"}