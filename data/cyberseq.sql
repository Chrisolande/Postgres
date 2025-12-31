CREATE DATABASE cybersecurity;

CREATE SCHEMA IF NOT EXISTS network_ids;
SET search_path TO network_ids;

ALTER TABLE clean_data RENAME TO network_traffic

-- SELECT current_database(), current_schema();

-- Change Datatypes
ALTER TABLE network_traffic
    ALTER COLUMN dur TYPE REAL USING dur::REAL,
    ALTER COLUMN sbytes TYPE INTEGER USING sbytes::INTEGER,
    ALTER COLUMN dbytes TYPE INTEGER USING dbytes::INTEGER,
    ALTER COLUMN label TYPE INTEGER USING label::INTEGER,
    ALTER COLUMN stime TYPE DOUBLE PRECISION USING stime::DOUBLE PRECISION,
    ALTER COLUMN ltime TYPE DOUBLE PRECISION USING ltime::DOUBLE PRECISION;
-- Fix the issue of Null Values in the Attack Categories as normal
UPDATE network_traffic
SET attack_cat = 'Normal'
WHERE attack_cat IS NULL;

-- Get a sneak peak of the data
SELECT
    attack_cat, label, srcip, dstip,
    proto, dur, sbytes,dbytes
FROM network_traffic
LIMIT 10;

-- Overall attack Distribution
SELECT attack_cat, COUNT(*) as frequency,
ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage,
ROUND(AVG(dur)::numeric, 2) as avg_duration,
ROUND(AVG(sbytes)::numeric, 0) as avg_bytes_sent,
ROUND(AVG(dbytes)::numeric, 0) as avg_bytes_downloaded
FROM network_traffic
GROUP BY attack_cat
ORDER BY frequency DESC;

-- Top 10 attack types exluding Normal
SELECT attack_cat, COUNT(*) as frequency,
ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentage
FROM network_traffic
WHERE attack_cat != 'Normal'
GROUP BY attack_cat
ORDER BY frequency DESC
LIMIT 10;

-- Attack Trends by hour
SELECT EXTRACT(HOUR FROM TO_TIMESTAMP(stime)) as hour_of_day,
       COUNT(*) as total_traffic,
       SUM(CASE WHEN label='1' THEN 1 ELSE 0 END) as attacks,
        ROUND(100 * SUM(CASE WHEN label = '1' THEN 1 ELSE 0 END) / COUNT(*), 2) as attack_rate_percentage
FROM network_traffic
WHERE stime IS NOT NULL
GROUP BY hour_of_day
ORDER BY total_traffic DESC;

-- Top 20 most suspicious source IPs by attack volume
SELECT
    srcip, COUNT(*) AS total_connections,
    SUM(CASE WHEN label='1' THEN 1 ELSE 0 END) as attack_connections,
    ROUND(100 * SUM(CASE WHEN label='1' THEN 1 ELSE 0 END) / COUNT(*), 2) as attack_rate,
    SUM(sbytes) as total_bytes_sent,
    STRING_AGG(DISTINCT attack_cat, ', ') as attack_types
FROM network_traffic
GROUP BY srcip
ORDER BY attack_connections DESC
LIMIT 20;