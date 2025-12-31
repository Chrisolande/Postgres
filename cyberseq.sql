-- CREATE DATABASE cybersecurity;

CREATE SCHEMA IF NOT EXISTS network_ids;
SET search_path TO network_ids;

-- ALTER TABLE clean_data RENAME TO network_traffic

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
       SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) as attacks,
        ROUND(100 * SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) as attack_rate_percentage
FROM network_traffic
WHERE stime IS NOT NULL
GROUP BY hour_of_day
ORDER BY total_traffic DESC;

-- Top 20 most suspicious source IPs by attack volume
SELECT
    srcip, COUNT(*) AS total_connections,
    SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) as attack_connections,
    ROUND(100 * SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) / COUNT(*), 2) as attack_rate,
    SUM(sbytes) as total_bytes_sent,
    STRING_AGG(DISTINCT attack_cat, ', ') as attack_types
FROM network_traffic
GROUP BY srcip
ORDER BY attack_connections DESC
LIMIT 20;

-- Source IP sending the most data
SELECT srcip, COUNT(*) as total_connections,
SUM(sbytes) as total_bytes_sent,
ROUND(AVG(sbytes)::numeric, 0) as avg_bytes_sent,
SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_count
FROM network_traffic
GROUP BY srcip
HAVING SUM(sbytes) > 0
ORDER BY total_bytes_sent DESC
LIMIT 20;

-- Source IP sending <100 bytes but labelled as attack
SELECT srcip, COUNT(*) as total_connections
FROM network_traffic
WHERE sbytes < 100 AND label = 1
GROUP BY srcip;

-- Most Targeted Destination IPs
SELECT dstip,
COUNT(*) as total_connections,
SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_count,
ROUND(100.0 * SUM(CASE WHEN Label = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) as attack_rate,
STRING_AGG(DISTINCT attack_cat, ', ') as attack_types,
COUNT(DISTINCT srcip) as unique_attackers
FROM network_traffic
GROUP BY dstip
HAVING SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) > 5
ORDER BY unique_attackers DESC
LIMIT 20;

-- Most targeted Ports
SELECT dsport, proto,
COUNT(*) as connection_count,
SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_count,
ROUND(100 * SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS attack_rate,
STRING_AGG(DISTINCT attack_cat, ', ') as attack_types
FROM network_traffic
GROUP BY dsport, proto
HAVING COUNT(*) > 5
ORDER BY COUNT(*) DESC
LIMIT 20;

-- Identify whichprotocols are most exploited
SELECT proto, COUNT(*) as total_connections,
SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) as attack_count,
ROUND(100 * COUNT(CASE WHEN label = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) as attack_rate,
ROUND(AVG(dur)::numeric, 4) as avg_duration,
ROUND(AVG(sbytes), 0) AS average_bytes_sent,
ROUND(AVG(dbytes), 0) AS average_bytes_downloaded
FROM network_traffic
GROUP BY proto
HAVING COUNT(*) > 100
ORDER BY total_connections DESC
LIMIT 20;

-- Identify High Risk Services
SELECT service, COUNT(*) as usage_count,
SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) AS attack_count,
ROUND(100 * SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) / COUNT(*)) AS vulnerability_rate,
STRING_AGG(DISTINCT attack_cat, ', ') as common_attacks
FROM network_traffic
WHERE service IS NOT NULL AND service != '-'
GROUP BY service
HAVING COUNT(*) > 50
ORDER BY vulnerability_rate DESC
LIMIT 20;

-- Protocols with the longest average connections
SELECT proto, COUNT(*) AS usage_count,
ROUND(AVG(dur)::numeric, 4) AS average_duration,
ROUND(MAX(dur)::numeric, 0) AS maximum_duration,
ROUND(STDDEV(dur)::numeric, 0) AS stdev_duration,
SUM(CASE WHEN LABEL=1 THEN 1 ELSE 0 END) AS attack_count
FROM network_traffic
GROUP BY proto
HAVING COUNT(*) > 100
ORDER BY average_duration DESC
LIMIT 20;


