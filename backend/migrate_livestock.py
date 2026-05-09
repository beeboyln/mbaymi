#!/usr/bin/env python
from app.database import engine
from sqlalchemy import text

# Read and execute the migration SQL
with open('sql/add_deleted_at_to_livestock.sql', 'r') as f:
    sql_script = f.read()

with engine.connect() as connection:
    # Split by semicolon and execute each statement
    statements = sql_script.split(';')
    for statement in statements:
        statement = statement.strip()
        if statement:
            try:
                connection.execute(text(statement))
                connection.commit()
                print(f"✓ Executed: {statement[:50]}...")
            except Exception as e:
                print(f"✗ Error executing: {statement[:50]}... - {e}")

print("\nMigration completed!")
