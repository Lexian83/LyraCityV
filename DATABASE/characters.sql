-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20251020.3eab4de5d8
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 10, 2025 at 09:39 PM
-- Server version: 8.4.3
-- PHP Version: 8.3.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `lyracityv`
--

-- --------------------------------------------------------

--
-- Table structure for table `characters`
--

CREATE TABLE `characters` (
  `id` int NOT NULL,
  `account_id` int NOT NULL,
  `name` varchar(60) COLLATE utf8mb4_general_ci NOT NULL,
  `gender` tinyint(1) NOT NULL DEFAULT '1',
  `heritage_country` char(2) COLLATE utf8mb4_general_ci NOT NULL,
  `health` float DEFAULT '100',
  `thirst` float DEFAULT '100',
  `food` float DEFAULT '100',
  `pos_x` float DEFAULT '0',
  `pos_y` float DEFAULT '0',
  `pos_z` float DEFAULT '0',
  `heading` float DEFAULT '0',
  `dimension` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `level` tinyint DEFAULT '0',
  `birthdate` date DEFAULT NULL,
  `type` tinyint NOT NULL,
  `is_locked` tinyint(1) DEFAULT '0',
  `appearance` json DEFAULT NULL,
  `clothes` json DEFAULT NULL,
  `residence_permit` tinyint(1) NOT NULL DEFAULT '0',
  `past` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `characters`
--

INSERT INTO `characters` (`id`, `account_id`, `name`, `gender`, `heritage_country`, `health`, `thirst`, `food`, `pos_x`, `pos_y`, `pos_z`, `heading`, `dimension`, `created_at`, `level`, `birthdate`, `type`, `is_locked`, `appearance`, `clothes`, `residence_permit`, `past`) VALUES
(1, 1, 'Bildhauer,Casandra', 0, 'BR', 200, 200, 200, 0, 0, 0, 0, 0, '2025-11-10 17:08:37', 10, '2000-01-12', 0, 0, '{\"sex\": 0, \"eyes\": 3, \"hair\": 10, \"faceF\": 0, \"faceM\": 35, \"faceMix\": 0.5, \"skinMix\": 0.5, \"eyebrows\": 1, \"structure\": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], \"faceFather\": 45, \"faceMother\": 35, \"facialHair\": 30, \"hairColor1\": 32, \"hairColor2\": 36, \"skinFather\": 45, \"skinMother\": 35, \"hairOverlay\": {\"overlay\": \"NG_F_Hair_010\", \"collection\": \"multiplayer_overlays\"}, \"colorOverlays\": [{\"id\": 4, \"value\": 0, \"color1\": 0, \"color2\": 0, \"opacity\": 0}, {\"id\": 5, \"value\": 0, \"color1\": 0, \"opacity\": 0}, {\"id\": 8, \"value\": 4, \"color1\": 22, \"opacity\": 0.8}], \"eyebrowsColor1\": 3, \"eyebrowsOpacity\": 1, \"opacityOverlays\": [{\"id\": 0, \"value\": 0, \"opacity\": 0}, {\"id\": 3, \"value\": 0, \"opacity\": 0}, {\"id\": 6, \"value\": 0, \"opacity\": 0}, {\"id\": 7, \"value\": 0, \"opacity\": 0}, {\"id\": 9, \"value\": 0, \"opacity\": 0}, {\"id\": 11, \"value\": 0, \"opacity\": 0}], \"facialHairColor1\": 0, \"facialHairOpacity\": 0}', '{\"top\": 105, \"pants\": 3, \"shoes\": 43, \"torso\": 4, \"topcolor\": 2, \"pantsColor\": 0, \"shoesColor\": 1, \"undershirt\": 14, \"undershirtColor\": 0}', 0, 0),
(5, 1, 'Jackson,Timothy', 1, 'GB', 200, 200, 200, 140.677, -1029.63, 29.3473, 73.7008, 0, '2025-11-10 21:00:41', 10, '1985-01-08', 0, 0, '{\"sex\": 1, \"eyes\": 3, \"hair\": 19, \"faceF\": 17, \"faceM\": 40, \"faceMix\": 0.5, \"skinMix\": 0, \"eyebrows\": 0, \"structure\": [0, -0.3, -0.3, 0, -0.2, 0, 0.4, -0.5, -0.3, -0.8, 0, -0.8, 0, 0, 0, 0.1, 0.4, -0.1, -1, 0.9], \"faceFather\": 17, \"faceMother\": 40, \"facialHair\": 2, \"hairColor1\": 26, \"hairColor2\": 4, \"skinFather\": 17, \"skinMother\": 40, \"hairOverlay\": {\"overlay\": \"NGBus_M_Hair_001\", \"collection\": \"multiplayer_overlays\"}, \"colorOverlays\": [{\"id\": 4, \"value\": 0, \"color1\": 0, \"color2\": 0, \"opacity\": 0}, {\"id\": 5, \"value\": 0, \"color1\": 0, \"opacity\": 0}, {\"id\": 8, \"value\": 0, \"color1\": 0, \"opacity\": 0}], \"eyebrowsColor1\": 4, \"eyebrowsOpacity\": 1, \"opacityOverlays\": [{\"id\": 0, \"value\": 0, \"opacity\": 0}, {\"id\": 3, \"value\": 1, \"opacity\": 0.8}, {\"id\": 6, \"value\": 0, \"opacity\": 0}, {\"id\": 7, \"value\": 0, \"opacity\": 0}, {\"id\": 9, \"value\": 0, \"opacity\": 0}, {\"id\": 11, \"value\": 0, \"opacity\": 0}], \"facialHairColor1\": 4, \"facialHairOpacity\": 0.89999999999999}', '{\"top\": 35, \"glass\": 38, \"pants\": 24, \"shoes\": 40, \"torso\": 14, \"watch\": 18, \"topcolor\": 0, \"glassColor\": 0, \"pantsColor\": 0, \"shoesColor\": 2, \"undershirt\": 3, \"watchColor\": 0, \"undershirtColor\": 2}', 1, 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `characters`
--
ALTER TABLE `characters`
  ADD PRIMARY KEY (`id`),
  ADD KEY `account_id` (`account_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `characters`
--
ALTER TABLE `characters`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `characters`
--
ALTER TABLE `characters`
  ADD CONSTRAINT `characters_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
