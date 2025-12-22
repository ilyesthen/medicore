#!/usr/bin/env python3
"""
MediCore Production Data Migration Script
Migrates data from SQLite to PostgreSQL with progress tracking
"""

import sqlite3
import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_batch
import sys
from datetime import datetime
import os

# Configuration
SQLITE_DB = "/Applications/eye/medicore.db"
PG_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'medicore_db',
    'user': 'medicore',
    'password': 'medicore_secure_2025'
}

# Table migration order (respecting foreign keys)
TABLES = [
    'users',
    'templates',
    'rooms',
    'message_templates',
    'medical_acts',
    'medications',
    'patients',
    'visits',
    'messages',
    'ordonnances',
    'payments',
    'waiting_patients',
    'appointments',
    'surgery_plans',
    'nurse_preferences'
]

def print_step(message, level="INFO"):
    """Print formatted step message"""
    prefix = {
        "INFO": "ℹ️ ",
        "SUCCESS": "✅",
        "ERROR": "❌",
        "WARN": "⚠️ "
    }.get(level, "  ")
    print(f"{prefix} {message}")

def connect_sqlite():
    """Connect to SQLite database"""
    try:
        conn = sqlite3.connect(SQLITE_DB)
        conn.row_factory = sqlite3.Row
        print_step(f"Connected to SQLite: {SQLITE_DB}", "SUCCESS")
        return conn
    except Exception as e:
        print_step(f"Failed to connect to SQLite: {e}", "ERROR")
        sys.exit(1)

def connect_postgres():
    """Connect to PostgreSQL database"""
    try:
        conn = psycopg2.connect(**PG_CONFIG)
        conn.autocommit = False
        print_step(f"Connected to PostgreSQL: {PG_CONFIG['database']}", "SUCCESS")
        return conn
    except Exception as e:
        print_step(f"Failed to connect to PostgreSQL: {e}", "ERROR")
        sys.exit(1)

def get_table_columns(pg_cursor, table_name):
    """Get column names from PostgreSQL table"""
    pg_cursor.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = %s 
        ORDER BY ordinal_position
    """, (table_name,))
    return [row[0] for row in pg_cursor.fetchall()]

def migrate_table(sqlite_conn, pg_conn, table_name):
    """Migrate a single table from SQLite to PostgreSQL"""
    print_step(f"Migrating table: {table_name}")
    
    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()
    
    try:
        # Get row count
        sqlite_cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        total_rows = sqlite_cursor.fetchone()[0]
        
        if total_rows == 0:
            print_step(f"  {table_name}: 0 rows (skipped)", "WARN")
            return
        
        # Get PostgreSQL columns
        pg_columns = get_table_columns(pg_cursor, table_name)
        
        # Fetch all data from SQLite
        sqlite_cursor.execute(f"SELECT * FROM {table_name}")
        rows = sqlite_cursor.fetchall()
        
        # Prepare data for PostgreSQL
        data_to_insert = []
        for row in rows:
            row_dict = dict(row)
            # Only include columns that exist in PostgreSQL
            pg_row = tuple(row_dict.get(col) for col in pg_columns)
            data_to_insert.append(pg_row)
        
        # Clear existing data
        pg_cursor.execute(sql.SQL("DELETE FROM {}").format(sql.Identifier(table_name)))
        
        # Insert data in batches
        if data_to_insert:
            placeholders = ','.join(['%s'] * len(pg_columns))
            insert_query = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
                sql.Identifier(table_name),
                sql.SQL(',').join(map(sql.Identifier, pg_columns)),
                sql.SQL(placeholders)
            )
            
            batch_size = 1000
            for i in range(0, len(data_to_insert), batch_size):
                batch = data_to_insert[i:i + batch_size]
                execute_batch(pg_cursor, insert_query, batch, page_size=batch_size)
                progress = min(i + batch_size, len(data_to_insert))
                print(f"  Progress: {progress}/{total_rows} rows", end='\r')
            
            print()  # New line after progress
        
        # Update sequences for SERIAL columns
        if table_name == 'patients':
            pg_cursor.execute("SELECT setval('patients_code_seq', COALESCE((SELECT MAX(code) FROM patients), 1))")
        elif table_name == 'visits':
            pg_cursor.execute("SELECT setval('visits_id_seq', COALESCE((SELECT MAX(id) FROM visits), 1))")
        elif table_name == 'messages':
            pg_cursor.execute("SELECT setval('messages_id_seq', COALESCE((SELECT MAX(id) FROM messages), 1))")
        elif table_name == 'ordonnances':
            pg_cursor.execute("SELECT setval('ordonnances_id_seq', COALESCE((SELECT MAX(id) FROM ordonnances), 1))")
        elif table_name == 'payments':
            pg_cursor.execute("SELECT setval('payments_id_seq', COALESCE((SELECT MAX(id) FROM payments), 1))")
        elif table_name == 'waiting_patients':
            pg_cursor.execute("SELECT setval('waiting_patients_id_seq', COALESCE((SELECT MAX(id) FROM waiting_patients), 1))")
        elif table_name == 'message_templates':
            pg_cursor.execute("SELECT setval('message_templates_id_seq', COALESCE((SELECT MAX(id) FROM message_templates), 1))")
        elif table_name == 'medical_acts':
            pg_cursor.execute("SELECT setval('medical_acts_id_seq', COALESCE((SELECT MAX(id) FROM medical_acts), 1))")
        elif table_name == 'medications':
            pg_cursor.execute("SELECT setval('medications_id_seq', COALESCE((SELECT MAX(id) FROM medications), 1))")
        elif table_name == 'appointments':
            pg_cursor.execute("SELECT setval('appointments_id_seq', COALESCE((SELECT MAX(id) FROM appointments), 1))")
        elif table_name == 'surgery_plans':
            pg_cursor.execute("SELECT setval('surgery_plans_id_seq', COALESCE((SELECT MAX(id) FROM surgery_plans), 1))")
        
        pg_conn.commit()
        print_step(f"  {table_name}: {total_rows} rows migrated", "SUCCESS")
        
    except Exception as e:
        pg_conn.rollback()
        print_step(f"  {table_name}: Migration failed - {e}", "ERROR")
        raise

def verify_migration(sqlite_conn, pg_conn):
    """Verify that all data was migrated correctly"""
    print_step("Verifying migration...")
    
    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()
    
    all_good = True
    
    for table in TABLES:
        # Get SQLite count
        sqlite_cursor.execute(f"SELECT COUNT(*) FROM {table}")
        sqlite_count = sqlite_cursor.fetchone()[0]
        
        # Get PostgreSQL count
        pg_cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}").format(sql.Identifier(table)))
        pg_count = pg_cursor.fetchone()[0]
        
        if sqlite_count == pg_count:
            print_step(f"  {table}: {pg_count} rows ✓", "SUCCESS")
        else:
            print_step(f"  {table}: MISMATCH! SQLite={sqlite_count}, PostgreSQL={pg_count}", "ERROR")
            all_good = False
    
    return all_good

def main():
    """Main migration process"""
    print("━" * 60)
    print("🚀 MediCore Production Data Migration")
    print("━" * 60)
    print(f"Source: {SQLITE_DB}")
    print(f"Target: PostgreSQL ({PG_CONFIG['host']}:{PG_CONFIG['port']}/{PG_CONFIG['database']})")
    print("━" * 60)
    print()
    
    # Check if SQLite database exists
    if not os.path.exists(SQLITE_DB):
        print_step(f"SQLite database not found: {SQLITE_DB}", "ERROR")
        sys.exit(1)
    
    # Get SQLite database info
    file_size = os.path.getsize(SQLITE_DB) / (1024 * 1024)  # MB
    mod_time = datetime.fromtimestamp(os.path.getmtime(SQLITE_DB))
    print_step(f"Database file: {file_size:.1f} MB, modified: {mod_time}", "INFO")
    print()
    
    # Connect to databases
    sqlite_conn = connect_sqlite()
    pg_conn = connect_postgres()
    
    try:
        # Migrate each table
        print()
        print_step("Starting migration...")
        print()
        
        for table in TABLES:
            try:
                migrate_table(sqlite_conn, pg_conn, table)
            except Exception as e:
                print_step(f"Failed to migrate {table}: {e}", "ERROR")
                # Continue with other tables
        
        # Verify migration
        print()
        if verify_migration(sqlite_conn, pg_conn):
            print()
            print("━" * 60)
            print_step("Migration completed successfully!", "SUCCESS")
            print("━" * 60)
        else:
            print()
            print("━" * 60)
            print_step("Migration completed with errors - please verify!", "WARN")
            print("━" * 60)
        
    finally:
        sqlite_conn.close()
        pg_conn.close()

if __name__ == "__main__":
    main()
