CREATE TABLE `houses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,

  `ownerid` int DEFAULT NULL,              -- char_id aus deinem Charactersystem

  `entry_x` double NOT NULL,
  `entry_y` double NOT NULL,
  `entry_z` double NOT NULL,

  `garage_trigger_x` double DEFAULT NULL,
  `garage_trigger_y` double DEFAULT NULL,
  `garage_trigger_z` double DEFAULT NULL,

  `garage_x` double DEFAULT NULL,
  `garage_y` double DEFAULT NULL,
  `garage_z` double DEFAULT NULL,

  `price` int NOT NULL DEFAULT 0,
  `buyed_at` datetime DEFAULT NULL,

  `rent` int DEFAULT NULL,                 -- Mietpreis pro Lauf (z.B. Woche)
  `rent_start` datetime DEFAULT NULL,      -- Startdatum des Mietvertrags

  `data` json DEFAULT NULL,                -- Freies JSON für Flags/Config
  `lock_state` tinyint(1) NOT NULL DEFAULT 1, -- 0 = offen, 1 = zu

  `inside_x` double DEFAULT NULL,          -- Optional: Override für Innenposition
  `inside_y` double DEFAULT NULL,
  `inside_z` double DEFAULT NULL,

  `ipl` int DEFAULT NULL,                  -- Verknüpfung zu house_ipl.id

  `fridgeid` int DEFAULT NULL,
  `storeid` int DEFAULT NULL,

  PRIMARY KEY (`id`),
  KEY `idx_ownerid` (`ownerid`),
  KEY `idx_ipl` (`ipl`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
