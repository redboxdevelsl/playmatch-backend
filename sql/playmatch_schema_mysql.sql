
-- PlayMatch Prototype -> Relational Schema (MySQL 8.0)
-- This schema is adapted from the frontend-only app models (constants.ts / types.ts)
-- Notes:
--  * All IDs are VARCHAR(191) for index compatibility with utf8mb4.
--  * Date/timestamps use DATE or DATETIME (UTC recommended at application layer).
--  * Arrays from TS are modeled as relation tables (e.g., court_game_types, match_players).
--  * PostgreSQL CHECK constraints were converted to ENUMs where appropriate.
--  * ENGINE=InnoDB, CHARSET utf8mb4 for FK support and emoji-safe text.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS playmatch CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE playmatch;

-- === Clubs ===
CREATE TABLE clubs (
  id VARCHAR(191) PRIMARY KEY,
  name VARCHAR(191) NOT NULL,
  nif VARCHAR(64),
  address VARCHAR(255),
  postal_code VARCHAR(32),
  city VARCHAR(128),
  province VARCHAR(128),
  country VARCHAR(128),
  phone VARCHAR(64),
  email VARCHAR(191),
  description TEXT,
  status ENUM('active','inactive') NOT NULL,
  registration_date DATETIME,
  payment_method_type ENUM('none','card','bank') NOT NULL DEFAULT 'none'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Game Types / Modality / Level ===
CREATE TABLE game_types (
  id VARCHAR(191) PRIMARY KEY,
  name VARCHAR(191) NOT NULL,
  club_id VARCHAR(191) NOT NULL,
  color VARCHAR(64),
  CONSTRAINT fk_game_types_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE modalities (
  id VARCHAR(191) PRIMARY KEY,
  name VARCHAR(191) NOT NULL,
  club_id VARCHAR(191) NOT NULL,
  CONSTRAINT fk_modalities_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE levels (
  id VARCHAR(191) PRIMARY KEY,
  name VARCHAR(191) NOT NULL,
  club_id VARCHAR(191) NOT NULL,
  game_type_id VARCHAR(191) NOT NULL,
  CONSTRAINT fk_levels_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_levels_game_type FOREIGN KEY (game_type_id) REFERENCES game_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === User Role Tags ===
CREATE TABLE user_role_tags (
  id VARCHAR(191) PRIMARY KEY,
  club_id VARCHAR(191) NOT NULL,
  name VARCHAR(191) NOT NULL,
  color VARCHAR(64),
  CONSTRAINT fk_role_tags_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Users ===
CREATE TABLE users (
  id VARCHAR(191) PRIMARY KEY,
  member_id INT,
  username VARCHAR(191) UNIQUE,
  full_name VARCHAR(191) NOT NULL,
  password_hash VARCHAR(255),
  email VARCHAR(191) UNIQUE,
  role ENUM('superadmin','admin','manager','coach','member','guest') NOT NULL,
  avatar_url VARCHAR(255),
  gender ENUM('male','female','other'),
  birth_date DATE,
  registration_date DATETIME,
  theme_id VARCHAR(191),
  status ENUM('active','inactive','blocked') NOT NULL DEFAULT 'active',
  club_id VARCHAR(191),
  user_role_tag_id VARCHAR(191),
  level_id VARCHAR(191),
  CONSTRAINT fk_users_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE SET NULL,
  CONSTRAINT fk_users_role_tag FOREIGN KEY (user_role_tag_id) REFERENCES user_role_tags(id) ON DELETE SET NULL,
  CONSTRAINT fk_users_level FOREIGN KEY (level_id) REFERENCES levels(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === User Groups ===
CREATE TABLE user_groups (
  id VARCHAR(191) PRIMARY KEY,
  club_id VARCHAR(191) NOT NULL,
  name VARCHAR(191) NOT NULL,
  primary_member_id VARCHAR(191),
  created_date DATETIME,
  CONSTRAINT fk_user_groups_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_groups_primary_member FOREIGN KEY (primary_member_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_group_members (
  group_id VARCHAR(191) NOT NULL,
  user_id VARCHAR(191) NOT NULL,
  PRIMARY KEY (group_id, user_id),
  CONSTRAINT fk_group_member_group FOREIGN KEY (group_id) REFERENCES user_groups(id) ON DELETE CASCADE,
  CONSTRAINT fk_group_member_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === User Passes ===
CREATE TABLE user_passes (
  id VARCHAR(191) PRIMARY KEY,
  user_id VARCHAR(191) NOT NULL,
  club_id VARCHAR(191) NOT NULL,
  name VARCHAR(191),
  remaining_uses INT,
  expiration_date DATE,
  CONSTRAINT fk_user_passes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_passes_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Courts ===
CREATE TABLE courts (
  id VARCHAR(191) PRIMARY KEY,
  name VARCHAR(191) NOT NULL,
  club_id VARCHAR(191) NOT NULL,
  max_participants INT NOT NULL,
  allow_player_reservations TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_courts_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE court_game_types (
  court_id VARCHAR(191) NOT NULL,
  game_type_id VARCHAR(191) NOT NULL,
  PRIMARY KEY (court_id, game_type_id),
  CONSTRAINT fk_cgt_court FOREIGN KEY (court_id) REFERENCES courts(id) ON DELETE CASCADE,
  CONSTRAINT fk_cgt_gametype FOREIGN KEY (game_type_id) REFERENCES game_types(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Court Blocks (maintenance, events) ===
CREATE TABLE court_blocks (
  id VARCHAR(191) PRIMARY KEY,
  court_id VARCHAR(191) NOT NULL,
  date DATE NOT NULL,
  reason VARCHAR(255),
  event_id VARCHAR(191),
  class_id VARCHAR(191),
  club_id VARCHAR(191) NOT NULL,
  CONSTRAINT fk_court_blocks_court FOREIGN KEY (court_id) REFERENCES courts(id) ON DELETE CASCADE,
  CONSTRAINT fk_court_blocks_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Blocked slots for a given block (TS had timeSlots: string[])
CREATE TABLE court_block_slots (
  block_id VARCHAR(191) NOT NULL,
  time_slot VARCHAR(64) NOT NULL,
  PRIMARY KEY (block_id, time_slot),
  CONSTRAINT fk_block_slots_block FOREIGN KEY (block_id) REFERENCES court_blocks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Matches & Bookings ===
CREATE TABLE matches (
  id VARCHAR(191) PRIMARY KEY,
  club_id VARCHAR(191) NOT NULL,
  court_id VARCHAR(191) NOT NULL,
  date DATE NOT NULL,
  time_slot VARCHAR(64) NOT NULL,
  level_id VARCHAR(191),
  game_type_id VARCHAR(191),
  modality_id VARCHAR(191),
  status ENUM('open','full','completed') NOT NULL,
  created_by VARCHAR(191),
  -- MatchResult (flattened)
  result_team_a INT,
  result_team_b INT,
  result_notes TEXT,
  result_confirmed_by VARCHAR(191),
  result_is_official TINYINT(1),
  CONSTRAINT fk_matches_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_matches_court FOREIGN KEY (court_id) REFERENCES courts(id),
  CONSTRAINT fk_matches_level FOREIGN KEY (level_id) REFERENCES levels(id) ON DELETE SET NULL,
  CONSTRAINT fk_matches_gametype FOREIGN KEY (game_type_id) REFERENCES game_types(id) ON DELETE SET NULL,
  CONSTRAINT fk_matches_modality FOREIGN KEY (modality_id) REFERENCES modalities(id) ON DELETE SET NULL,
  CONSTRAINT fk_matches_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_matches_confirmed_by FOREIGN KEY (result_confirmed_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_matches_club_date (club_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE match_players (
  match_id VARCHAR(191) NOT NULL,
  user_id VARCHAR(191) NOT NULL,
  PRIMARY KEY (match_id, user_id),
  CONSTRAINT fk_match_players_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
  CONSTRAINT fk_match_players_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Booking in TS has no ID; we use a natural composite PK
CREATE TABLE bookings (
  club_id VARCHAR(191) NOT NULL,
  court_id VARCHAR(191) NOT NULL,
  date DATE NOT NULL,
  time_slot VARCHAR(64) NOT NULL,
  match_id VARCHAR(191),
  PRIMARY KEY (club_id, court_id, date, time_slot),
  CONSTRAINT fk_bookings_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_bookings_court FOREIGN KEY (court_id) REFERENCES courts(id) ON DELETE CASCADE,
  CONSTRAINT fk_bookings_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE SET NULL,
  INDEX idx_bookings_match (match_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Chat & Messaging ===
CREATE TABLE chats (
  id VARCHAR(191) PRIMARY KEY,
  club_id VARCHAR(191) NOT NULL,
  type ENUM('global','private') NOT NULL,
  name VARCHAR(191),
  avatar_url VARCHAR(255),
  CONSTRAINT fk_chats_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE chat_participants (
  chat_id VARCHAR(191) NOT NULL,
  user_id VARCHAR(191) NOT NULL,
  PRIMARY KEY (chat_id, user_id),
  CONSTRAINT fk_chat_part_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_part_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE messages (
  id VARCHAR(191) PRIMARY KEY,
  chat_id VARCHAR(191) NOT NULL,
  type ENUM('text','match','event') NOT NULL,
  timestamp DATETIME NOT NULL,
  sender_id VARCHAR(191),
  text TEXT,
  match_id VARCHAR(191),
  event_id VARCHAR(191),
  CONSTRAINT fk_messages_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_messages_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE SET NULL,
  INDEX idx_messages_chat_time (chat_id, timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Bar / Commerce ===
CREATE TABLE bar_tables (
  id VARCHAR(191) PRIMARY KEY,
  club_id VARCHAR(191) NOT NULL,
  name VARCHAR(191) NOT NULL,
  status ENUM('free','occupied','reserved') NOT NULL DEFAULT 'free',
  CONSTRAINT fk_bar_tables_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bar_orders (
  id VARCHAR(191) PRIMARY KEY,
  club_id VARCHAR(191) NOT NULL,
  table_id VARCHAR(191) NOT NULL,
  status ENUM('open','preparing','served','paid','cancelled') NOT NULL,
  created_at DATETIME NOT NULL,
  CONSTRAINT fk_bar_orders_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_bar_orders_table FOREIGN KEY (table_id) REFERENCES bar_tables(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bar_order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id VARCHAR(191) NOT NULL,
  product_id VARCHAR(191),
  product_name VARCHAR(191) NOT NULL,
  quantity INT NOT NULL,
  price_per_item DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_boi_order FOREIGN KEY (order_id) REFERENCES bar_orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Cash Drawer Sessions ===
CREATE TABLE cash_drawer_sessions (
  id VARCHAR(191) PRIMARY KEY,
  club_id VARCHAR(191) NOT NULL,
  type ENUM('bar','commerce') NOT NULL,
  opening_timestamp DATETIME NOT NULL,
  opening_user_id VARCHAR(191),
  opening_balance DECIMAL(12,2) NOT NULL,
  closing_timestamp DATETIME,
  closing_user_id VARCHAR(191),
  calculated_cash_total DECIMAL(12,2),
  calculated_card_total DECIMAL(12,2),
  status ENUM('open','closed') NOT NULL,
  is_balanced TINYINT(1) NOT NULL,
  discrepancy_amount DECIMAL(12,2),
  CONSTRAINT fk_cds_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  CONSTRAINT fk_cds_opening_user FOREIGN KEY (opening_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_cds_closing_user FOREIGN KEY (closing_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Access Logs ===
CREATE TABLE access_logs (
  id VARCHAR(191) PRIMARY KEY,
  user_id VARCHAR(191),
  club_id VARCHAR(191),
  timestamp DATETIME NOT NULL,
  entry_point VARCHAR(191),
  entry_type ENUM('member','guest','staff'),
  CONSTRAINT fk_access_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_access_logs_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
  INDEX idx_access_logs_club_time (club_id, timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Internal Messages (superadmin -> clubs/users) ===
CREATE TABLE internal_messages (
  id VARCHAR(191) PRIMARY KEY,
  sender_id VARCHAR(191) NOT NULL,
  recipient_id VARCHAR(191) NOT NULL, -- 'all', 'superadmin', or specific id
  subject VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  timestamp DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE internal_message_readers (
  message_id VARCHAR(191) NOT NULL,
  user_id VARCHAR(191) NOT NULL,
  PRIMARY KEY (message_id, user_id),
  CONSTRAINT fk_imr_message FOREIGN KEY (message_id) REFERENCES internal_messages(id) ON DELETE CASCADE,
  CONSTRAINT fk_imr_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- === Themes (UI) ===
CREATE TABLE themes (
  id VARCHAR(191) PRIMARY KEY,
  name VARCHAR(191) NOT NULL,
  colors JSON NULL -- optional; store theme colors map
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
