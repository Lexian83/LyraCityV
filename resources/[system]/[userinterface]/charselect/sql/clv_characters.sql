-- LCV Character Select - minimal schema
CREATE TABLE IF NOT EXISTS `characters` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `account_id` VARCHAR(64) NOT NULL,
  `firstname` VARCHAR(50) NOT NULL,
  `lastname`  VARCHAR(50) NOT NULL,
  `birthdate` DATE DEFAULT NULL,
  `status` ENUM('normal','coma','wildlife') NOT NULL DEFAULT 'normal',
  `char_type` ENUM('human','wildlife') NOT NULL DEFAULT 'human',
  `is_locked` TINYINT(1) NOT NULL DEFAULT 0,
  `portrait` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_char_identifier` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;