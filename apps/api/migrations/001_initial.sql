CREATE TABLE IF NOT EXISTS anonymous_users (
  user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (user_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movement_sessions (
  session_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  anonymous_user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  movement_type ENUM('WHEELCHAIR', 'STROLLER', 'WALKING') NOT NULL,
  status ENUM('ACTIVE', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'ACTIVE',
  started_at TIMESTAMP(3) NOT NULL,
  ended_at TIMESTAMP(3) NULL,
  app_version VARCHAR(32) NULL,
  device_model VARCHAR(80) NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (session_id),
  KEY idx_sessions_user_started (anonymous_user_id, started_at),
  KEY idx_sessions_status_started (status, started_at),
  CONSTRAINT fk_sessions_user
    FOREIGN KEY (anonymous_user_id) REFERENCES anonymous_users (user_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS road_segments (
  road_segment_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  road_name VARCHAR(160) NOT NULL,
  location POINT NOT NULL SRID 4326,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
    ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (road_segment_id),
  SPATIAL INDEX sidx_road_segments_location (location)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sensor_events (
  event_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  session_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  road_segment_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
  movement_type ENUM('WHEELCHAIR', 'STROLLER', 'WALKING') NOT NULL,
  event_status ENUM(
    'ACCEPTED',
    'HELD_LOW_GPS_ACCURACY',
    'HELD_DROP_PATTERN',
    'REJECTED_STATIONARY',
    'REJECTED_DUPLICATE',
    'REJECTED_BELOW_THRESHOLD'
  ) NOT NULL,
  impact_level ENUM('LOW_IMPACT', 'MEDIUM_IMPACT', 'HIGH_IMPACT') NOT NULL,
  latitude DECIMAL(10, 7) NOT NULL,
  longitude DECIMAL(10, 7) NOT NULL,
  gps_accuracy DECIMAL(7, 2) NOT NULL,
  speed DECIMAL(7, 3) NULL,
  severity DECIMAL(6, 5) NOT NULL,
  anomaly_score DECIMAL(6, 5) NOT NULL,
  peak_value DECIMAL(9, 4) NOT NULL,
  window_duration_ms SMALLINT UNSIGNED NULL,
  window_mean DECIMAL(10, 5) NULL,
  window_std DECIMAL(10, 5) NULL,
  window_rms DECIMAL(10, 5) NULL,
  window_peak_count SMALLINT UNSIGNED NULL,
  detected_at TIMESTAMP(3) NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (event_id),
  KEY idx_events_segment_movement_time (
    road_segment_id,
    movement_type,
    detected_at
  ),
  KEY idx_events_session_time (session_id, detected_at),
  KEY idx_events_status_time (event_status, detected_at),
  CONSTRAINT fk_events_session
    FOREIGN KEY (session_id) REFERENCES movement_sessions (session_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_events_road_segment
    FOREIGN KEY (road_segment_id) REFERENCES road_segments (road_segment_id)
    ON UPDATE RESTRICT ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS road_traversals (
  road_segment_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  session_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  movement_type ENUM('WHEELCHAIR', 'STROLLER', 'WALKING') NOT NULL,
  first_detected_at TIMESTAMP(3) NOT NULL,
  PRIMARY KEY (road_segment_id, session_id, movement_type),
  KEY idx_traversals_movement (movement_type, first_detected_at),
  CONSTRAINT fk_traversals_road
    FOREIGN KEY (road_segment_id) REFERENCES road_segments (road_segment_id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT fk_traversals_session
    FOREIGN KEY (session_id) REFERENCES movement_sessions (session_id)
    ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS road_scores (
  score_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  road_segment_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  movement_type ENUM('WHEELCHAIR', 'STROLLER', 'WALKING') NOT NULL,
  score TINYINT UNSIGNED NOT NULL,
  grade ENUM('GOOD', 'NORMAL', 'CAUTION', 'POOR') NOT NULL,
  confidence DECIMAL(6, 5) NOT NULL,
  confidence_level ENUM('LOW', 'MEDIUM', 'HIGH') NOT NULL,
  event_count INT UNSIGNED NOT NULL,
  unique_contributor_count INT UNSIGNED NOT NULL,
  traversal_count INT UNSIGNED NOT NULL,
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
    ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (score_id),
  UNIQUE KEY uq_road_scores_segment_movement (
    road_segment_id,
    movement_type
  ),
  KEY idx_road_scores_priority (
    movement_type,
    score,
    confidence
  ),
  CONSTRAINT fk_scores_road
    FOREIGN KEY (road_segment_id) REFERENCES road_segments (road_segment_id)
    ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS schema_migrations (
  migration_name VARCHAR(160) NOT NULL,
  applied_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (migration_name)
) ENGINE=InnoDB;
