#!/usr/bin/env python3
"""
Magic: The Gathering JSON Data Loader

This script loads the Magic: The Gathering card data from a JSON file
into the PostgreSQL database. It reads the MagicAllSets.json file
(which contains all card sets and their data) and inserts it into
the magic.allsets table.

The magic.allsets table should be created beforehand with:
    create table magic.allsets(data jsonb);

Environment variables used for database connection:
    PGUSER     - PostgreSQL username (default: taop)
    PGDATABASE - PostgreSQL database name (default: taop)

Usage:
    python3 magic.py

The script expects to find MagicAllSets.json in the current directory.
"""

import os
import psycopg2

# Default connection string - can be overridden by environment variables
PGCONNSTRING = "user={} dbname={}".format(
    os.environ.get('PGUSER', 'taop'),
    os.environ.get('PGDATABASE', 'taop')
)

def load_magic_data():
    """
    Load the Magic: The Gathering JSON data into the database.

    Reads the MagicAllSets.json file, escapes single quotes for SQL safety,
    and inserts the data into the magic.allsets table.
    """
    pgconn = psycopg2.connect(PGCONNSTRING)
    curs = pgconn.cursor()

    # Read the JSON file containing all Magic sets
    with open('MagicAllSets.json', 'r') as f:
        allset = f.read()

    # Escape single quotes for safe SQL insertion
    allset = allset.replace("'", "''")

    # Insert the JSON data into the database
    sql = "insert into magic.allsets(data) values('%s')" % allset
    curs.execute(sql)

    # Commit the transaction
    pgconn.commit()
    pgconn.close()

    print("Successfully loaded Magic: The Gathering data into database.")

if __name__ == '__main__':
    load_magic_data()
