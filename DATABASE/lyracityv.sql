-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20251020.3eab4de5d8
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 10, 2025 at 12:02 PM
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
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` int NOT NULL,
  `username` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `discord_id` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `steam_id` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `last_login` datetime DEFAULT CURRENT_TIMESTAMP,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `new` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`id`, `username`, `discord_id`, `steam_id`, `password_hash`, `last_login`, `created_at`, `new`) VALUES
(1, 'jhurt', '487762720263766019', NULL, NULL, '2025-11-10 13:01:53', '2025-10-19 10:43:44', 1),
(2, 'fsdfa', 'adfadsf', 'adfadf', 'adfadsf', '2025-10-30 20:48:23', '2025-10-30 20:48:23', 1);

-- --------------------------------------------------------

--
-- Table structure for table `bank_accounts`
--

CREATE TABLE `bank_accounts` (
  `id` int NOT NULL,
  `owner` int NOT NULL,
  `account_number` varchar(16) NOT NULL,
  `balance` int NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `bank_accounts`
--

INSERT INTO `bank_accounts` (`id`, `owner`, `account_number`, `balance`, `created_at`) VALUES
(1, 7, '28416903', 100000000, '2025-11-04 16:12:59'),
(2, 6, '76690787', 1000000000, '2025-11-06 10:51:29');

-- --------------------------------------------------------

--
-- Table structure for table `bank_log`
--

CREATE TABLE `bank_log` (
  `id` int NOT NULL,
  `account_number` varchar(16) NOT NULL,
  `kind` enum('deposit','withdraw','transfer_in','transfer_out') NOT NULL,
  `amount` int NOT NULL,
  `source` varchar(64) DEFAULT NULL,
  `destination` varchar(64) DEFAULT NULL,
  `meta` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `bank_log`
--

INSERT INTO `bank_log` (`id`, `account_number`, `kind`, `amount`, `source`, `destination`, `meta`, `created_at`) VALUES
(1, '28416903', 'deposit', 1000, 'wallet', 'account', '{\"by\": 1, \"owner\": 7}', '2025-11-05 14:21:45'),
(2, '28416903', 'deposit', 100000, 'wallet', 'account', '{\"by\": 1, \"owner\": 7}', '2025-11-05 14:21:53'),
(3, '28416903', 'deposit', 1000000, 'wallet', 'account', '{\"by\": 1, \"owner\": 7}', '2025-11-05 14:21:59'),
(4, '28416903', 'deposit', 98899000, 'wallet', 'account', '{\"by\": 1, \"owner\": 7}', '2025-11-05 14:22:25'),
(5, '28416903', 'withdraw', 10, 'account', 'wallet', '{\"by\": 1, \"owner\": 7}', '2025-11-05 14:22:55'),
(6, '28416903', 'deposit', 11, 'wallet', 'account', '{\"by\": 1, \"owner\": 7}', '2025-11-05 14:23:05'),
(7, '28416903', 'withdraw', 1, 'account', 'wallet', '{\"by\": 1, \"owner\": 7}', '2025-11-05 14:23:11'),
(8, '28416903', 'deposit', 500, 'wallet', 'account', '{\"by\": 2, \"owner\": 7}', '2025-11-05 15:48:25'),
(9, '28416903', 'withdraw', 500, 'account', 'wallet', '{\"by\": 2, \"owner\": 7}', '2025-11-05 15:48:32'),
(10, '28416903', 'deposit', 100, 'wallet', 'account', '{\"by\": 2, \"owner\": 7}', '2025-11-05 22:05:33'),
(11, '28416903', 'withdraw', 100, 'account', 'wallet', '{\"by\": 1, \"owner\": 7}', '2025-11-06 08:25:30'),
(12, '76690787', 'withdraw', 100, 'account', 'wallet', '{\"by\": 1, \"owner\": 6}', '2025-11-06 22:43:39');

-- --------------------------------------------------------

--
-- Table structure for table `blips`
--

CREATE TABLE `blips` (
  `id` int UNSIGNED NOT NULL,
  `name` varchar(80) NOT NULL DEFAULT '',
  `x` double NOT NULL,
  `y` double NOT NULL,
  `z` double NOT NULL DEFAULT '0',
  `sprite` int NOT NULL DEFAULT '1',
  `color` int NOT NULL DEFAULT '0',
  `scale` float NOT NULL DEFAULT '1',
  `shortRange` tinyint(1) NOT NULL DEFAULT '1',
  `display` int NOT NULL DEFAULT '4',
  `category` varchar(50) DEFAULT NULL,
  `visiblefor` int NOT NULL DEFAULT '0',
  `enabled` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `blips`
--

INSERT INTO `blips` (`id`, `name`, `x`, `y`, `z`, `sprite`, `color`, `scale`, `shortRange`, `display`, `category`, `visiblefor`, `enabled`) VALUES
(1, '24/7', 373.0002746582031, 328.0467224121094, 103.55924224853516, 52, 0, 1, 0, 4, 'shops', 0, 1),
(2, 'Suburban', 126.6242446899414, -225.0174255371093, 54.55763626098633, 73, 0, 1, 0, 2, 'kleidung', 0, 1),
(3, 'Binco', 426.9739990234375, -806.2677612304688, 29.48391914367676, 73, 0, 1, 0, 2, 'kleidung', 0, 1),
(5, 'Stadthalle', -539.0931396484375, -215.2918243408203, 37.650245666503906, 351, 0, 1, 1, 4, 'allgemein', 0, 1),
(6, 'Kranknehaus', 291.3162841796875, -587.1670532226562, 43.195335388183594, 61, 0, 1, 1, 4, 'ems', 0, 1),
(7, 'LSPD Mission Row', 418.4214782714844, -978.4151000976562, 29.426359176635746, 526, 0, 1, 1, 4, 'allgemein', 0, 1),
(8, '24/7', 1728.5557861328125, 6416.6318359375, 35.03718948364258, 52, 0, 1, 1, 4, 'shops', 0, 1);

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
(5, 1, 'Croock,Lyra', 0, 'US', 200, 200, 200, 0, 0, 0, 0, 0, '2025-10-30 15:08:37', 0, '2025-10-17', 0, 0, '{\"sex\": 0, \"eyes\": 0, \"hair\": 11, \"faceMix\": 0.5, \"skinMix\": 0.5, \"eyebrows\": 0, \"structure\": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], \"faceFather\": 33, \"faceMother\": 45, \"facialHair\": 30, \"hairColor1\": 5, \"hairColor2\": 2, \"skinFather\": 45, \"skinMother\": 45, \"hairOverlay\": {\"overlay\": \"NG_F_Hair_011\", \"collection\": \"multiplayer_overlays\"}, \"colorOverlays\": [{\"id\": 4, \"value\": 0, \"color1\": 0, \"color2\": 0, \"opacity\": 0}, {\"id\": 5, \"value\": 0, \"color1\": 0, \"opacity\": 0}, {\"id\": 8, \"value\": 0, \"color1\": 0, \"opacity\": 0}], \"eyebrowsColor1\": 0, \"eyebrowsOpacity\": 1, \"opacityOverlays\": [{\"id\": 0, \"value\": 0, \"opacity\": 0}, {\"id\": 3, \"value\": 0, \"opacity\": 0}, {\"id\": 6, \"value\": 0, \"opacity\": 0}, {\"id\": 7, \"value\": 0, \"opacity\": 0}, {\"id\": 9, \"value\": 0, \"opacity\": 0}, {\"id\": 11, \"value\": 0, \"opacity\": 0}], \"facialHairColor1\": 62, \"facialHairOpacity\": 0}', '{\"top\": 3, \"pants\": 8, \"shoes\": 9, \"torso\": 3, \"topcolor\": 0, \"pantsColor\": 0, \"shoesColor\": 0, \"undershirt\": 2, \"undershirtColor\": 0}', 0, 0),
(6, 1, 'Colemann,Kendra', 0, 'BR', 200, 200, 200, 0, 0, 0, 0, 0, '2025-10-30 20:44:09', 10, '2000-06-22', 0, 0, '{\"sex\": 0, \"eyes\": 3, \"hair\": 53, \"faceF\": 8, \"faceM\": 23, \"faceMix\": 0.8, \"skinMix\": 0.2, \"eyebrows\": 1, \"structure\": [0.3, 0, -0.5, 0, -0.3, 0, -0.1, -0.7, 0, 0, 0, -0.9, -0.9, 0, 0, 0, 0, 0, 0, 0], \"faceFather\": 21, \"faceMother\": 25, \"facialHair\": 30, \"hairColor1\": 28, \"hairColor2\": 32, \"skinFather\": 36, \"skinMother\": 41, \"hairOverlay\": {\"overlay\": \"NG_M_Hair_015\", \"collection\": \"multiplayer_overlays\"}, \"colorOverlays\": [{\"id\": 4, \"value\": 5, \"color1\": 31, \"color2\": 29, \"opacity\": 0.9}, {\"id\": 5, \"value\": 0, \"color1\": 0, \"opacity\": 0}, {\"id\": 8, \"value\": 3, \"color1\": 31, \"opacity\": 0.9}], \"eyebrowsColor1\": 4, \"eyebrowsOpacity\": 1, \"opacityOverlays\": [{\"id\": 0, \"value\": 0, \"opacity\": 0}, {\"id\": 3, \"value\": 0, \"opacity\": 0}, {\"id\": 6, \"value\": 0, \"opacity\": 0}, {\"id\": 7, \"value\": 0, \"opacity\": 0}, {\"id\": 9, \"value\": 0, \"opacity\": 0.8}, {\"id\": 11, \"value\": 0, \"opacity\": 0}], \"facialHairColor1\": 0, \"facialHairOpacity\": 0}', '{\"top\": 35, \"pants\": 12, \"shoes\": 77, \"torso\": 5, \"topcolor\": 10, \"pantsColor\": 9, \"shoesColor\": 1, \"undershirt\": 28, \"undershirtColor\": 3}', 0, 0),
(7, 1, 'Hawk,Oswald', 1, 'US', 200, 200, 200, 0, 0, 0, 0, 0, '2025-10-30 21:15:20', 10, '1993-02-08', 0, 0, '{\"sex\": 1, \"eyes\": 1, \"hair\": 19, \"faceF\": 2, \"faceM\": 21, \"faceMix\": 0.4, \"skinMix\": 0.6, \"eyebrows\": 25, \"structure\": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], \"faceFather\": 2, \"faceMother\": 21, \"facialHair\": 2, \"hairColor1\": 3, \"hairColor2\": 28, \"skinFather\": 2, \"skinMother\": 21, \"hairOverlay\": {\"overlay\": \"NGBus_M_Hair_001\", \"collection\": \"multiplayer_overlays\"}, \"colorOverlays\": [{\"id\": 4, \"value\": 0, \"color1\": 0, \"color2\": 0, \"opacity\": 0}, {\"id\": 5, \"value\": 0, \"color1\": 0, \"opacity\": 0}, {\"id\": 8, \"value\": 0, \"color1\": 0, \"opacity\": 0}], \"eyebrowsColor1\": 3, \"eyebrowsOpacity\": 1, \"opacityOverlays\": [{\"id\": 0, \"value\": 0, \"opacity\": 0}, {\"id\": 3, \"value\": 1, \"opacity\": 0.7}, {\"id\": 6, \"value\": 0, \"opacity\": 0}, {\"id\": 7, \"value\": 0, \"opacity\": 0}, {\"id\": 9, \"value\": 0, \"opacity\": 0.7}, {\"id\": 11, \"value\": 0, \"opacity\": 0}], \"facialHairColor1\": 3, \"facialHairOpacity\": 0.89999999999999}', '{\"top\": 348, \"pants\": 10, \"shoes\": 10, \"torso\": 0, \"topcolor\": 3, \"pantsColor\": 0, \"shoesColor\": 0, \"undershirt\": 15, \"undershirtColor\": 0}', 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `connection_logs`
--

CREATE TABLE `connection_logs` (
  `id` int UNSIGNED NOT NULL,
  `identifier_license` varchar(120) DEFAULT NULL,
  `identifier_steam` varchar(120) DEFAULT NULL,
  `identifier_discord` varchar(120) DEFAULT NULL,
  `ip` varchar(64) DEFAULT NULL,
  `name` varchar(128) DEFAULT NULL,
  `connect_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `extra` json DEFAULT NULL,
  `disconnect_time` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `connection_logs`
--

INSERT INTO `connection_logs` (`id`, `identifier_license`, `identifier_steam`, `identifier_discord`, `ip`, `name`, `connect_time`, `extra`, `disconnect_time`) VALUES
(223, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 15:01:52', '{\"clientName\": \"Lexian83\"}', '2025-11-07 15:34:44'),
(224, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 15:57:50', '{\"clientName\": \"Lexian83\"}', '2025-11-07 16:00:46'),
(225, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 16:18:57', '{\"clientName\": \"Lexian83\"}', '2025-11-07 16:28:32'),
(226, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 16:32:30', '{\"clientName\": \"Lexian83\"}', '2025-11-07 16:39:41'),
(227, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 16:40:26', '{\"clientName\": \"Lexian83\"}', '2025-11-07 16:45:44'),
(228, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 16:46:28', '{\"clientName\": \"Lexian83\"}', '2025-11-07 16:58:14'),
(229, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 17:00:29', '{\"clientName\": \"Lexian83\"}', '2025-11-07 17:17:39'),
(230, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 17:39:08', '{\"clientName\": \"Lexian83\"}', '2025-11-07 17:49:50'),
(231, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 17:51:16', '{\"clientName\": \"Lexian83\"}', '2025-11-07 17:55:58'),
(232, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 17:56:39', '{\"clientName\": \"Lexian83\"}', '2025-11-07 18:01:24'),
(233, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 18:06:47', '{\"clientName\": \"Lexian83\"}', '2025-11-07 18:13:51'),
(234, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 18:18:00', '{\"clientName\": \"Lexian83\"}', '2025-11-07 18:32:06'),
(235, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 18:33:07', '{\"clientName\": \"Lexian83\"}', '2025-11-07 19:10:33'),
(236, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 19:13:13', '{\"clientName\": \"Lexian83\"}', '2025-11-07 19:16:54'),
(237, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 19:17:47', '{\"clientName\": \"Lexian83\"}', NULL),
(238, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 19:18:17', '{\"clientName\": \"Lexian83\"}', NULL),
(239, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 19:18:40', '{\"clientName\": \"Lexian83\"}', NULL),
(240, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 19:19:10', '{\"clientName\": \"Lexian83\"}', '2025-11-07 19:30:47'),
(241, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 19:32:28', '{\"clientName\": \"Lexian83\"}', '2025-11-07 19:37:09'),
(242, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 19:38:00', '{\"clientName\": \"Lexian83\"}', '2025-11-07 19:39:52'),
(243, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 19:40:34', '{\"clientName\": \"Lexian83\"}', '2025-11-07 20:26:47'),
(244, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 20:29:41', '{\"clientName\": \"Lexian83\"}', '2025-11-07 20:34:02'),
(245, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 20:34:41', '{\"clientName\": \"Lexian83\"}', '2025-11-07 20:35:49'),
(246, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 20:46:10', '{\"clientName\": \"Lexian83\"}', '2025-11-07 20:47:06'),
(247, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 20:48:55', '{\"clientName\": \"Lexian83\"}', '2025-11-07 20:52:25'),
(248, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 20:54:16', '{\"clientName\": \"Lexian83\"}', '2025-11-07 20:57:36'),
(249, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 20:58:09', '{\"clientName\": \"Lexian83\"}', '2025-11-07 20:58:27'),
(250, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 20:58:55', '{\"clientName\": \"Lexian83\"}', '2025-11-07 21:00:14'),
(251, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 21:02:37', '{\"clientName\": \"Lexian83\"}', '2025-11-07 21:04:36'),
(252, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 21:09:16', '{\"clientName\": \"Lexian83\"}', '2025-11-07 21:20:06'),
(253, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 21:20:37', '{\"clientName\": \"Lexian83\"}', '2025-11-07 23:00:58'),
(254, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 23:01:37', '{\"clientName\": \"Lexian83\"}', '2025-11-07 23:01:57'),
(255, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 23:02:28', '{\"clientName\": \"Lexian83\"}', NULL),
(256, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 23:02:56', '{\"clientName\": \"Lexian83\"}', NULL),
(257, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 23:03:13', '{\"clientName\": \"Lexian83\"}', NULL),
(258, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 23:03:54', '{\"clientName\": \"Lexian83\"}', '2025-11-07 23:05:24'),
(259, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-07 23:39:17', '{\"clientName\": \"Lexian83\"}', '2025-11-08 00:08:58'),
(260, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 00:12:16', '{\"clientName\": \"Lexian83\"}', '2025-11-08 00:13:14'),
(261, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 00:18:09', '{\"clientName\": \"Lexian83\"}', '2025-11-08 00:35:23'),
(262, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 00:38:33', '{\"clientName\": \"Lexian83\"}', '2025-11-08 01:05:20'),
(263, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 01:12:47', '{\"clientName\": \"Lexian83\"}', '2025-11-08 02:40:24'),
(264, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 02:48:36', '{\"clientName\": \"Lexian83\"}', '2025-11-08 03:35:03'),
(265, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 03:36:32', '{\"clientName\": \"Lexian83\"}', '2025-11-08 03:45:02'),
(266, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 03:45:42', '{\"clientName\": \"Lexian83\"}', '2025-11-08 04:12:49'),
(267, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 04:16:52', '{\"clientName\": \"Lexian83\"}', '2025-11-08 04:21:34'),
(268, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 11:28:34', '{\"clientName\": \"Lexian83\"}', '2025-11-08 11:37:20'),
(269, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 11:54:19', '{\"clientName\": \"Lexian83\"}', '2025-11-08 11:55:26'),
(270, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 13:37:58', '{\"clientName\": \"Lexian83\"}', '2025-11-08 15:33:39'),
(271, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 15:53:16', '{\"clientName\": \"Lexian83\"}', '2025-11-08 16:02:44'),
(272, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 16:06:23', '{\"clientName\": \"Lexian83\"}', '2025-11-08 16:17:18'),
(273, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 16:18:43', '{\"clientName\": \"Lexian83\"}', '2025-11-08 16:23:35'),
(274, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 16:24:04', '{\"clientName\": \"Lexian83\"}', '2025-11-08 16:38:42'),
(275, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 16:40:08', '{\"clientName\": \"Lexian83\"}', '2025-11-08 16:44:26'),
(276, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 16:45:12', '{\"clientName\": \"Lexian83\"}', NULL),
(277, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 16:45:54', '{\"clientName\": \"Lexian83\"}', NULL),
(278, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 16:46:26', '{\"clientName\": \"Lexian83\"}', NULL),
(279, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 16:46:59', '{\"clientName\": \"Lexian83\"}', '2025-11-08 16:55:18'),
(280, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 17:00:27', '{\"clientName\": \"Lexian83\"}', '2025-11-08 17:06:11'),
(281, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 17:06:54', '{\"clientName\": \"Lexian83\"}', '2025-11-08 17:14:09'),
(282, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 17:15:27', '{\"clientName\": \"Lexian83\"}', '2025-11-08 17:19:30'),
(283, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 17:23:47', '{\"clientName\": \"Lexian83\"}', '2025-11-08 17:34:00'),
(284, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 17:37:41', '{\"clientName\": \"Lexian83\"}', '2025-11-08 17:38:53'),
(285, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 17:39:15', '{\"clientName\": \"Lexian83\"}', '2025-11-08 17:39:57'),
(286, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 17:52:12', '{\"clientName\": \"Lexian83\"}', '2025-11-08 17:54:07'),
(287, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:12:27', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:14:48'),
(288, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:20:25', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:23:27'),
(289, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:25:01', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:25:39'),
(290, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:28:58', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:33:01'),
(291, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:35:43', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:36:27'),
(292, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:37:19', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:38:32'),
(293, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:41:37', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:43:23'),
(294, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:46:46', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:52:43'),
(295, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:53:17', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:53:55'),
(296, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:54:35', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:55:39'),
(297, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:56:05', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:56:38'),
(298, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:57:33', '{\"clientName\": \"Lexian83\"}', '2025-11-08 18:58:22'),
(299, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 18:58:57', '{\"clientName\": \"Lexian83\"}', '2025-11-08 19:06:00'),
(300, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 19:06:42', '{\"clientName\": \"Lexian83\"}', '2025-11-08 19:12:05'),
(301, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 19:13:45', '{\"clientName\": \"Lexian83\"}', '2025-11-08 19:15:20'),
(302, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 19:17:15', '{\"clientName\": \"Lexian83\"}', '2025-11-08 19:17:57'),
(303, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 19:18:39', '{\"clientName\": \"Lexian83\"}', '2025-11-08 20:03:58'),
(304, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 20:11:27', '{\"clientName\": \"Lexian83\"}', '2025-11-08 21:04:53'),
(305, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 21:14:11', '{\"clientName\": \"Lexian83\"}', '2025-11-08 21:18:04'),
(306, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 21:18:31', '{\"clientName\": \"Lexian83\"}', '2025-11-08 21:29:51'),
(307, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 21:31:33', '{\"clientName\": \"Lexian83\"}', '2025-11-08 21:42:02'),
(308, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 21:43:03', '{\"clientName\": \"Lexian83\"}', '2025-11-08 21:43:53'),
(309, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 21:50:43', '{\"clientName\": \"Lexian83\"}', '2025-11-08 21:58:20'),
(310, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-08 22:20:46', '{\"clientName\": \"Lexian83\"}', '2025-11-09 00:25:23'),
(311, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 00:27:34', '{\"clientName\": \"Lexian83\"}', NULL),
(312, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 00:28:20', '{\"clientName\": \"Lexian83\"}', NULL),
(313, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 00:28:44', '{\"clientName\": \"Lexian83\"}', '2025-11-09 00:47:08'),
(314, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 00:47:37', '{\"clientName\": \"Lexian83\"}', '2025-11-09 01:33:26'),
(315, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 01:33:59', '{\"clientName\": \"Lexian83\"}', '2025-11-09 01:55:51'),
(316, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 01:57:55', '{\"clientName\": \"Lexian83\"}', '2025-11-09 02:06:50'),
(317, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 02:08:58', '{\"clientName\": \"Lexian83\"}', '2025-11-09 02:11:14'),
(318, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 02:20:22', '{\"clientName\": \"Lexian83\"}', '2025-11-09 02:31:38'),
(319, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 02:35:57', '{\"clientName\": \"Lexian83\"}', '2025-11-09 02:38:18'),
(320, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 02:38:55', '{\"clientName\": \"Lexian83\"}', '2025-11-09 03:32:35'),
(321, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 03:37:54', '{\"clientName\": \"Lexian83\"}', '2025-11-09 03:43:24'),
(322, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 13:43:06', '{\"clientName\": \"Lexian83\"}', '2025-11-09 14:21:06'),
(323, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 14:29:48', '{\"clientName\": \"Lexian83\"}', '2025-11-09 14:40:07'),
(324, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, NULL, '192.168.178.71', 'Lexian83', '2025-11-09 18:57:12', '{\"clientName\": \"Lexian83\"}', NULL),
(325, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 18:57:32', '{\"clientName\": \"Lexian83\"}', '2025-11-09 20:03:29'),
(326, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 20:09:56', '{\"clientName\": \"Lexian83\"}', '2025-11-09 20:40:14'),
(327, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 20:43:42', '{\"clientName\": \"Lexian83\"}', '2025-11-09 20:58:17'),
(328, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 21:08:40', '{\"clientName\": \"Lexian83\"}', '2025-11-09 21:18:52'),
(329, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 21:20:01', '{\"clientName\": \"Lexian83\"}', '2025-11-09 21:33:49'),
(330, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 22:09:05', '{\"clientName\": \"Lexian83\"}', '2025-11-09 22:34:24'),
(331, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 22:35:04', '{\"clientName\": \"Lexian83\"}', '2025-11-09 22:46:59'),
(332, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 22:49:12', '{\"clientName\": \"Lexian83\"}', '2025-11-09 23:05:03'),
(333, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-09 23:09:22', '{\"clientName\": \"Lexian83\"}', '2025-11-10 00:20:28'),
(334, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 00:21:27', '{\"clientName\": \"Lexian83\"}', '2025-11-10 01:27:23'),
(335, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 09:05:39', '{\"clientName\": \"Lexian83\"}', '2025-11-10 09:18:40'),
(336, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 09:19:16', '{\"clientName\": \"Lexian83\"}', '2025-11-10 09:32:03'),
(337, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 09:34:49', '{\"clientName\": \"Lexian83\"}', '2025-11-10 10:11:40'),
(338, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 10:58:08', '{\"clientName\": \"Lexian83\"}', '2025-11-10 11:13:09'),
(339, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 11:13:46', '{\"clientName\": \"Lexian83\"}', '2025-11-10 11:18:04'),
(340, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 11:23:24', '{\"clientName\": \"Lexian83\"}', '2025-11-10 12:22:57'),
(341, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, NULL, '192.168.178.71', 'Lexian83', '2025-11-10 12:24:08', '{\"clientName\": \"Lexian83\"}', NULL),
(342, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, NULL, '192.168.178.71', 'Lexian83', '2025-11-10 12:24:31', '{\"clientName\": \"Lexian83\"}', NULL),
(343, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 12:24:43', '{\"clientName\": \"Lexian83\"}', '2025-11-10 12:32:32'),
(344, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 12:45:07', '{\"clientName\": \"Lexian83\"}', '2025-11-10 13:00:54'),
(345, 'license:324864cc65849e68e11dd4c83839b9ac0cd89042', NULL, 'discord:487762720263766019', '192.168.178.71', 'Lexian83', '2025-11-10 13:01:52', '{\"clientName\": \"Lexian83\"}', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `death_logs`
--

CREATE TABLE `death_logs` (
  `id` int UNSIGNED NOT NULL,
  `character_id` int UNSIGNED DEFAULT NULL,
  `killer_identifier` varchar(128) DEFAULT NULL,
  `reason` varchar(128) DEFAULT NULL,
  `pos_x` double DEFAULT NULL,
  `pos_y` double DEFAULT NULL,
  `pos_z` double DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `death_logs`
--

INSERT INTO `death_logs` (`id`, `character_id`, `killer_identifier`, `reason`, `pos_x`, `pos_y`, `pos_z`, `created_at`) VALUES
(1, 7, NULL, '-842959696', -1042.16162109375, -2874.018310546875, 13.457662582397461, '2025-11-02 21:03:57'),
(2, 6, NULL, '-842959696', -1043.44140625, -2873.700439453125, 12.871079444885254, '2025-11-06 12:10:53'),
(3, 6, NULL, '-842959696', -1042.13134765625, -2875.34326171875, 13.732193946838379, '2025-11-06 12:15:39'),
(4, 6, NULL, '-842959696', -1040.374755859375, -2873.907470703125, 13.346997261047363, '2025-11-06 12:32:47'),
(5, 6, NULL, '-842959696', 307.7260437011719, -22.454776763916016, 75.28256225585938, '2025-11-07 00:12:09'),
(6, 6, NULL, '-842959696', 16.58625602722168, -952.76708984375, 28.000717163085938, '2025-11-07 00:37:27'),
(7, 6, NULL, '-842959696', -1041.71484375, -2873.031982421875, 12.805549621582031, '2025-11-07 00:41:01'),
(8, 6, NULL, '-842959696', -1043.091064453125, -2873.071044921875, 13.206705093383789, '2025-11-07 00:57:55'),
(9, 6, NULL, '-842959696', -1040.950927734375, -2873.662841796875, 13.321052551269531, '2025-11-07 01:07:43'),
(10, 6, NULL, '-842959696', -1122.3775634765625, -2780.887939453125, -9.046943664550781, '2025-11-07 02:15:57'),
(11, 6, NULL, '-842959696', 158.66441345214844, -720.28515625, 46.44097137451172, '2025-11-07 09:52:25'),
(12, 6, NULL, '-842959696', -57.88996124267578, -835.2860717773438, 293.0829772949219, '2025-11-07 15:06:22'),
(13, 6, NULL, '-842959696', -1041.1419677734375, -2872.472412109375, 18.493921279907227, '2025-11-07 15:58:58'),
(14, 6, NULL, '-842959696', -1042.520263671875, -2872.3193359375, 12.850855827331543, '2025-11-07 16:19:57'),
(15, 6, NULL, '-842959696', -1042.5570068359375, -2874.37744140625, 13.375020980834961, '2025-11-07 16:33:48'),
(16, 6, NULL, '-842959696', -1041.11376953125, -2872.254150390625, 12.914368629455566, '2025-11-07 16:41:24'),
(17, 6, NULL, '-842959696', -1040.9150390625, -2872.860595703125, 13.093072891235352, '2025-11-07 16:47:34'),
(18, 6, NULL, '-842959696', -1043.63818359375, -2875.173095703125, 13.445707321166992, '2025-11-07 17:01:26'),
(19, 6, NULL, '-842959696', -934.46435546875, -2704.614990234375, 13.67658519744873, '2025-11-07 18:37:23'),
(20, 6, NULL, '-10959621', -1154.8865966796875, -1854.01513671875, -3.3091113567352295, '2025-11-08 01:32:42'),
(21, 6, NULL, '-842959696', -321.3864440917969, 6074.56005859375, 30.48169708251953, '2025-11-08 20:12:25'),
(22, 6, NULL, '0', -1092.9105224609375, 2685.4921875, 19.069246292114258, '2025-11-08 20:23:54');

-- --------------------------------------------------------

--
-- Table structure for table `factions`
--

CREATE TABLE `factions` (
  `id` int NOT NULL,
  `name` varchar(32) COLLATE utf8mb4_general_ci NOT NULL,
  `label` varchar(64) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `leader_char_id` int DEFAULT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `created_by` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `duty_required` tinyint(1) NOT NULL DEFAULT '0',
  `is_gang` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `factions`
--

INSERT INTO `factions` (`id`, `name`, `label`, `leader_char_id`, `description`, `created_by`, `created_at`, `duty_required`, `is_gang`) VALUES
(2, 'LSPD', 'Los Santos Police Department', 6, 'Polizei halt', 6, '2025-11-09 21:37:43', 1, 0),
(4, 'LSMD', 'Los Santos Medical Department', 6, 'EMS/MD', 6, '2025-11-09 21:45:21', 1, 0),
(6, 'LSFD', 'Los Santos Fire Department', 6, 'Feuerwehr', 6, '2025-11-09 21:52:08', 1, 0),
(8, 'DOJ', 'Department of Justice', 6, 'Richterleins und Anwältileins', 6, '2025-11-09 22:01:50', 1, 0),
(10, 'GOV', 'Goverment', 6, 'Regierung', 6, '2025-11-09 22:10:32', 1, 0),
(12, 'VAN', 'Vangelico Gem Store', 6, 'Juwelier in der Stadt', 6, '2025-11-09 22:57:36', 1, 0);

-- --------------------------------------------------------

--
-- Table structure for table `faction_logs`
--

CREATE TABLE `faction_logs` (
  `id` int NOT NULL,
  `faction_id` int NOT NULL,
  `actor_char_id` int DEFAULT NULL,
  `target_char_id` int DEFAULT NULL,
  `action` varchar(64) COLLATE utf8mb4_general_ci NOT NULL,
  `details` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `faction_logs`
--

INSERT INTO `faction_logs` (`id`, `faction_id`, `actor_char_id`, `target_char_id`, `action`, `details`, `created_at`) VALUES
(2, 2, 6, NULL, 'create_faction', '{\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\"}', '2025-11-09 21:37:43'),
(3, 4, 6, NULL, 'create_faction', '{\"name\": \"LSMD\", \"label\": \"Los Santos Medical Department\"}', '2025-11-09 21:45:21'),
(4, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"description\": \"Polizei halt\", \"leader_char_id\": 6}}', '2025-11-09 21:46:21'),
(5, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"description\": \"Polizei halt\", \"leader_char_id\": 6}}', '2025-11-09 21:46:21'),
(6, 6, 6, NULL, 'create_faction', '{\"name\": \"LSFD\", \"label\": \"Los Santos Fire Department\"}', '2025-11-09 21:52:08'),
(7, 8, 6, NULL, 'create_faction', '{\"name\": \"DOJ\", \"label\": \"Department of Justice\"}', '2025-11-09 22:01:50'),
(8, 10, 6, NULL, 'create_faction', '{\"name\": \"GOV\", \"label\": \"Goverment\"}', '2025-11-09 22:10:32'),
(9, 2, 6, 7, 'add_member', '{\"rank_id\": 27}', '2025-11-09 22:19:49'),
(10, 4, 6, 5, 'add_member', '{\"rank_id\": 10}', '2025-11-09 22:33:11'),
(11, 4, 6, 5, 'set_member_rank', '{\"rank_id\": 11}', '2025-11-09 22:33:15'),
(12, 6, 6, 5, 'add_member', '{\"rank_id\": 16}', '2025-11-09 22:36:40'),
(13, 2, 6, 5, 'add_member', '{\"rank_id\": 8}', '2025-11-09 22:36:55'),
(14, 12, 6, NULL, 'create_faction', '{\"name\": \"VAN\", \"label\": \"Vangelico Gem Store\"}', '2025-11-09 22:57:36'),
(15, 12, 6, 7, 'add_member', '{\"rank_id\": 29}', '2025-11-09 22:58:21'),
(16, 2, 6, 5, 'remove_member', '[]', '2025-11-09 23:09:28'),
(17, 2, 6, 5, 'add_member', '{\"rank_id\": 7}', '2025-11-09 23:09:48'),
(18, 2, 6, 7, 'set_member_rank', '{\"rank_id\": 6}', '2025-11-09 23:22:27'),
(19, 2, 6, 7, 'set_member_rank', '{\"rank_id\": 32}', '2025-11-09 23:23:48'),
(20, 6, 6, 5, 'set_member_rank', '{\"rank_id\": 15}', '2025-11-10 00:03:01'),
(21, 6, 6, 5, 'set_member_rank', '{\"rank_id\": 16}', '2025-11-10 00:03:06'),
(22, 4, 6, 5, 'set_member_rank', '{\"rank_id\": 9}', '2025-11-10 00:27:08'),
(23, 4, 6, 5, 'set_member_rank', '{\"rank_id\": 10}', '2025-11-10 00:27:12'),
(24, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"is_gang\": 0, \"description\": \"Polizei halt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:05:29'),
(25, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"is_gang\": 0, \"description\": \"Polizei halt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:05:29'),
(26, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"is_gang\": 0, \"description\": \"Polizei halt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:06:09'),
(27, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"is_gang\": 0, \"description\": \"Polizei halt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:06:09'),
(28, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"is_gang\": 0, \"description\": \"Polizei halt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:12:44'),
(29, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"is_gang\": 0, \"description\": \"Polizei halt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:12:44'),
(30, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"is_gang\": 0, \"description\": \"Polizei halt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:14:19'),
(31, 2, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSPD\", \"label\": \"Los Santos Police Department\", \"is_gang\": 0, \"description\": \"Polizei halt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:14:19'),
(32, 4, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSMD\", \"label\": \"Los Santos Medical Department\", \"is_gang\": 0, \"description\": \"EMS/MD\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:14:49'),
(33, 4, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSMD\", \"label\": \"Los Santos Medical Department\", \"is_gang\": 0, \"description\": \"EMS/MD\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:14:49'),
(34, 6, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSFD\", \"label\": \"Los Santos Fire Department\", \"is_gang\": 0, \"description\": \"Feuerwehr\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:14:55'),
(35, 6, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"LSFD\", \"label\": \"Los Santos Fire Department\", \"is_gang\": 0, \"description\": \"Feuerwehr\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:14:55'),
(36, 8, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"DOJ\", \"label\": \"Department of Justice\", \"is_gang\": 0, \"description\": \"Richterleins und Anwältileins\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:15:06'),
(37, 8, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"DOJ\", \"label\": \"Department of Justice\", \"is_gang\": 0, \"description\": \"Richterleins und Anwältileins\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:15:06'),
(38, 10, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"GOV\", \"label\": \"Goverment\", \"is_gang\": 0, \"description\": \"Regierung\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:15:12'),
(39, 10, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"GOV\", \"label\": \"Goverment\", \"is_gang\": 0, \"description\": \"Regierung\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:15:12'),
(40, 12, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"VAN\", \"label\": \"Vangelico Gem Store\", \"is_gang\": 0, \"description\": \"Juwelier in der Stadt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:15:17'),
(41, 12, 6, NULL, 'update_faction', '{\"fields\": {\"name\": \"VAN\", \"label\": \"Vangelico Gem Store\", \"is_gang\": 0, \"description\": \"Juwelier in der Stadt\", \"duty_required\": 1, \"leader_char_id\": 6}}', '2025-11-10 10:15:17');

-- --------------------------------------------------------

--
-- Table structure for table `faction_members`
--

CREATE TABLE `faction_members` (
  `id` int NOT NULL,
  `faction_id` int NOT NULL,
  `char_id` int NOT NULL,
  `rank_id` int NOT NULL,
  `joined_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `active` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `faction_members`
--

INSERT INTO `faction_members` (`id`, `faction_id`, `char_id`, `rank_id`, `joined_at`, `active`) VALUES
(2, 2, 6, 5, '2025-11-09 21:37:43', 1),
(3, 4, 6, 9, '2025-11-09 21:45:21', 1),
(4, 6, 6, 13, '2025-11-09 21:52:08', 1),
(5, 8, 6, 18, '2025-11-09 22:01:50', 1),
(6, 10, 6, 22, '2025-11-09 22:10:32', 1),
(7, 2, 7, 32, '2025-11-09 22:19:49', 1),
(8, 4, 5, 10, '2025-11-09 22:33:11', 1),
(9, 6, 5, 16, '2025-11-09 22:36:40', 1),
(10, 2, 5, 7, '2025-11-09 22:36:55', 1),
(11, 12, 6, 28, '2025-11-09 22:57:36', 1),
(12, 12, 7, 29, '2025-11-09 22:58:21', 1);

-- --------------------------------------------------------

--
-- Table structure for table `faction_permission_schema`
--

CREATE TABLE `faction_permission_schema` (
  `id` int UNSIGNED NOT NULL,
  `perm_key` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `label` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `allowed_factions` text COLLATE utf8mb4_unicode_ci,
  `sort_index` int NOT NULL DEFAULT '100',
  `is_active` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `faction_permission_schema`
--

INSERT INTO `faction_permission_schema` (`id`, `perm_key`, `label`, `allowed_factions`, `sort_index`, `is_active`) VALUES
(1, 'manage_faction', 'Fraktion bearbeiten', NULL, 10, 1),
(2, 'manage_ranks', 'Ränge verwalten', NULL, 20, 1),
(3, 'invite', 'Mitglieder einladen', NULL, 30, 1),
(4, 'kick', 'Mitglieder entfernen', NULL, 40, 1),
(5, 'set_rank', 'Rang zuweisen', NULL, 50, 1),
(6, 'view_logs', 'Logs einsehen', NULL, 60, 1),
(7, 'lspd_armory', 'LSPD: Waffenkammer', '[\"LSPD\"]', 100, 1),
(8, 'lsmd_pharmacy', 'LSMD: Medikamentenlager', '[\"LSMD\"]', 110, 1),
(9, 'lspd_evidence_open', 'LSPD: Asservatenkammer Öffnen', '[\"LSPD\"]', 100, 1),
(11, 'lspd_evidence_take', 'LSPD: Asservatenkammer nehmen', '[\"LSPD\"]', 100, 1);

-- --------------------------------------------------------

--
-- Table structure for table `faction_ranks`
--

CREATE TABLE `faction_ranks` (
  `id` int NOT NULL,
  `faction_id` int NOT NULL,
  `name` varchar(64) COLLATE utf8mb4_general_ci NOT NULL,
  `level` tinyint UNSIGNED NOT NULL,
  `permissions` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `faction_ranks`
--

INSERT INTO `faction_ranks` (`id`, `faction_id`, `name`, `level`, `permissions`) VALUES
(5, 2, 'Chief of Police', 100, '{\"kick\": true, \"invite\": true, \"set_rank\": true, \"view_logs\": true, \"lspd_armory\": true, \"manage_ranks\": true, \"manage_faction\": true, \"lspd_evidence_open\": true, \"lspd_evidence_take\": true}'),
(6, 2, 'Officer', 50, '{\"kick\": false, \"invite\": false, \"set_rank\": false, \"view_logs\": false}'),
(7, 2, 'Member', 10, '{\"kick\": false, \"invite\": false, \"view_logs\": false}'),
(8, 2, 'Recruit', 1, '[]'),
(9, 4, 'Secretary of Health and Human Services', 100, '{\"kick\": true, \"invite\": true, \"set_rank\": true, \"view_logs\": true, \"manage_ranks\": true, \"manage_faction\": true}'),
(10, 4, 'Officer', 50, '{\"kick\": true, \"invite\": true, \"set_rank\": false, \"view_logs\": true}'),
(11, 4, 'Member', 10, '{\"kick\": false, \"invite\": false, \"view_logs\": false}'),
(12, 4, 'Recruit', 1, '[]'),
(13, 6, 'LSFA(Fire Administrator)', 100, '{\"kick\": true, \"invite\": true, \"set_rank\": true, \"view_logs\": true, \"manage_ranks\": true, \"manage_faction\": true}'),
(14, 6, 'Officer', 50, '{\"kick\": true, \"invite\": true, \"set_rank\": false, \"view_logs\": true}'),
(15, 6, 'Member', 10, '{\"kick\": false, \"invite\": false, \"view_logs\": false}'),
(16, 6, 'Recruit', 1, '[]'),
(18, 8, 'Leader', 100, '{\"kick\": true, \"invite\": true, \"set_rank\": true, \"view_logs\": true, \"manage_ranks\": true, \"manage_faction\": true}'),
(19, 8, 'Officer', 50, '{\"kick\": true, \"invite\": true, \"set_rank\": false, \"view_logs\": true}'),
(20, 8, 'Member', 10, '{\"kick\": false, \"invite\": false, \"view_logs\": false}'),
(21, 8, 'Recruit', 1, '[]'),
(22, 10, 'Bürgermeister', 100, '{\"kick\": true, \"invite\": true, \"set_rank\": true, \"view_logs\": true, \"manage_ranks\": true, \"manage_faction\": true}'),
(23, 10, 'Assistenz', 90, '{\"kick\": true, \"invite\": true, \"set_rank\": false, \"view_logs\": true}'),
(24, 10, 'Member', 10, '{\"kick\": false, \"invite\": false, \"view_logs\": false}'),
(25, 10, 'Recruit', 1, '[]'),
(28, 12, 'Owner', 100, '{\"kick\": true, \"invite\": true, \"set_rank\": true, \"view_logs\": true, \"manage_ranks\": true, \"manage_faction\": true}'),
(29, 12, 'Manager', 99, '{\"kick\": true, \"invite\": true, \"set_rank\": true, \"view_logs\": true}'),
(30, 12, 'Member', 10, '{\"kick\": false, \"invite\": false, \"view_logs\": false}'),
(31, 12, 'Recruit', 1, '[]'),
(32, 2, 'Commander', 90, '{\"kick\": true, \"invite\": true, \"set_rank\": true}');

-- --------------------------------------------------------

--
-- Table structure for table `interaction_points`
--

CREATE TABLE `interaction_points` (
  `id` int UNSIGNED NOT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `x` double NOT NULL,
  `y` double NOT NULL,
  `z` double NOT NULL,
  `radius` float NOT NULL DEFAULT '1.5',
  `enabled` tinyint(1) NOT NULL DEFAULT '1',
  `data` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `interaction_points`
--

INSERT INTO `interaction_points` (`id`, `name`, `description`, `type`, `x`, `y`, `z`, `radius`, `enabled`, `data`, `created_at`, `updated_at`) VALUES
(2, 'EZ-Platz1', 'Einreisezentrum Platz 1 (ganz links)', 'pc', -1119.25, -2786.13, 16.59, 1.2, 1, '{\"faction\": \"EZ\"}', '2025-11-07 16:49:25', '2025-11-07 18:21:25'),
(3, 'EZ-Platz2', 'Einreisezentrum Platz 2', 'pc', -1119.730712890625, -2787.074462890625, 16.590669631958008, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-07 23:41:19', '2025-11-07 23:41:33'),
(5, 'EZ-Platz3', 'EZ-Platz3', 'pc', -1121.8389892578125, -2790.9970703125, 16.590652465820312, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-07 23:47:11', NULL),
(6, 'EZ-Platz4', 'EZ-Platz4', 'pc', -1122.307861328125, -2791.9423828125, 16.590652465820312, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-07 23:50:55', NULL),
(7, 'EZ-Platz5', 'EZ-Platz5', 'pc', -1124.7613525390625, -2795.755615234375, 16.590652465820312, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-07 23:52:26', NULL),
(8, 'EZ-Platz6', 'EZ-Platz6', 'pc', -1125.3201904296875, -2796.634033203125, 16.590652465820312, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-07 23:53:11', NULL),
(9, 'EZ-Platz7', 'EZ-Platz7', 'pc', -1127.517333984375, -2800.696533203125, 16.59061622619629, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-08 00:14:42', NULL),
(10, 'EZ-Platz8', 'EZ-Platz8', 'pc', -1128.02294921875, -2801.59765625, 16.59061622619629, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-08 00:15:37', '2025-11-08 00:19:41'),
(11, 'EZ-Platz9', 'EZ-Platz9', 'pc', -1130.813232421875, -2806.125, 16.59061622619629, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-08 00:16:33', '2025-11-08 00:20:08'),
(12, 'EZ-Platz10', 'EZ-Platz10', 'pc', -1131.3355712890625, -2807.0263671875, 16.59061622619629, 1, 1, '{\"faction\": \"EZ\"}', '2025-11-08 00:17:26', '2025-11-08 00:20:33'),
(13, 'LSMD Frontdesk 3', 'LSMD Frontdesk 3', 'pc', 312.96124267578125, -594.5108032226562, 43.28401565551758, 1.6, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:37:47', '2025-11-10 00:17:44'),
(14, 'EMS Frontdesk 2', 'EMS Frontdesk 2', 'pc', 310.718505859375, -593.852294921875, 43.75876235961914, 1.6, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:39:09', '2025-11-09 19:20:36'),
(15, 'EMS Frontdesk 1', 'EMS Frontdesk 1', 'pc', 308.9218139648437, -594.1857299804688, 43.28412628173828, 1.6, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:40:10', '2025-11-09 19:20:45'),
(16, 'EMS Lab 1', 'EMS Labor Laptop 1', 'pc', 308.3110656738281, -563.7174072265625, 43.28402328491211, 1.5, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:43:26', '2025-11-09 19:20:51'),
(17, 'EMS Lab 2', 'EMS Labor Laptop 2', 'pc', 310.6715087890625, -561.4457397460938, 43.28402328491211, 1.6, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:45:09', '2025-11-09 19:20:57'),
(18, 'EMS Lab 3', 'EMS Labor Laptop 3', 'pc', 312.1790466308594, -562.6845703125, 43.28402328491211, 1.6, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:45:58', '2025-11-09 19:21:04'),
(19, 'EMS MRI PC', 'EMS MRI PC', 'pc', 341.8148193359375, -576.7725830078125, 43.28413009643555, 1.2, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:48:13', '2025-11-09 19:21:09'),
(20, 'EMS XRAY PC', 'EMS XRAY PC', 'pc', 343.7541809082031, -578.3242797851562, 43.28412628173828, 1.2, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:49:50', '2025-11-09 19:21:15'),
(21, 'EMS Administration', 'EMS Administration', 'pc', 340.33282470703125, -591.2398071289062, 43.28412628173828, 1, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:51:11', '2025-11-09 19:21:22'),
(22, 'EMS Director', 'EMS Director', 'pc', 334.7312927246094, -594.415771484375, 43.28412628173828, 1, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:52:12', '2025-11-09 19:21:26'),
(23, 'EMS DR Room 1', 'EMS DR Room 1', 'pc', 359.6673583984375, -599.8276977539062, 43.28412628173828, 1, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:58:20', '2025-11-09 19:21:31'),
(24, 'EMS DR Room 2', 'EMS DR Room 2', 'pc', 355.22235107421875, -596.2536010742188, 43.28412628173828, 1, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 00:59:35', '2025-11-09 19:21:35'),
(25, 'EMS Treatment 1', 'EMS Treatment 1', 'pc', 342.4532775878906, -591.8458862304688, 43.28412628173828, 1, 1, '{\"faction\": \"LSMD\", \"location\": \"Pillbox Hospital\"}', '2025-11-08 01:00:42', '2025-11-09 19:21:40'),
(26, 'LSPD Servicedesk PC 1', 'LSPD Servicedesk PC 1', 'pc', 441.77435302734375, -978.9266967773438, 30.689626693725582, 1.5, 1, '{\"faction\": \"LSPD\", \"location\": \"Mission Row\"}', '2025-11-08 01:05:55', '2025-11-09 19:18:51'),
(27, 'LSPD Servicedesk PC 2', 'LSPD Servicedesk PC 2', 'pc', 440.0955200195313, -978.7337036132812, 30.689558029174805, 1.5, 1, '{\"faction\": \"LSPD\", \"location\": \"Mission Row\"}', '2025-11-08 01:07:19', '2025-11-09 19:19:10'),
(28, 'LSPD Servicedesk PC 3', 'LSPD Servicedesk PC 3', 'pc', 440.1292419433594, -975.7241821289062, 30.68963050842285, 1, 1, '{\"faction\": \"LSPD\", \"location\": \"Mission Row - X\"}', '2025-11-08 01:08:12', '2025-11-09 19:32:29'),
(29, 'LSPD Captain PC', 'LSPD Captain PC', 'pc', 447.9679870605469, -973.4151000976562, 30.68955421447754, 1.5, 1, '{\"faction\": \"LSPD\", \"location\": \"Mission Row\"}', '2025-11-08 01:10:06', '2025-11-09 19:19:27'),
(30, 'LSPD Jailroom', 'LSPD Jailroom', 'pc', 459.7464294433594, -988.759765625, 24.91489791870117, 1.3, 1, '{\"faction\": \"LSPD\", \"location\": \"Mission Row\"}', '2025-11-08 01:15:04', '2025-11-09 19:19:42'),
(31, 'Townhall Frontdesk DOJ 1', 'DOJ Frontdesk 1', 'pc', -551.5264892578125, -191.23187255859372, 38.21927261352539, 1, 1, '{\"faction\": \"DOJ\"}', '2025-11-09 01:49:13', '2025-11-09 01:51:34'),
(32, 'Townhall Frontdesk DOJ 2', 'DOJ Frontdesk 2', 'pc', -552.9807739257812, -192.1352996826172, 38.21927261352539, 1, 1, '{\"faction\": \"DOJ\"}', '2025-11-09 01:50:13', '2025-11-09 01:51:44'),
(33, 'Townhall GOV', 'Townhall GOV', 'pc', -568.4884033203125, -193.9127197265625, 38.21844100952149, 1, 1, '{\"faction\": \"GOV\"}', '2025-11-09 01:54:27', '2025-11-09 01:54:55'),
(34, 'Townhall GOV 2', 'Townhall GOV 2', 'pc', -568.9318237304688, -199.06883239746097, 38.21893310546875, 1, 1, '{\"faction\": \"GOV\"}', '2025-11-09 01:55:58', NULL),
(35, 'DOJ Saal Anwalt 1', 'DOJ Saal Anwalt 1', 'pc', -525.6023559570312, -178.63433837890625, 38.219120025634766, 1, 1, '{\"faction\": \"DOJ\"}', '2025-11-09 01:57:41', NULL),
(36, 'DOJ Saal Anwalt 2', 'DOJ Saal Anwalt 2', 'pc', -524.2313232421875, -180.8265380859375, 38.219181060791016, 1, 1, '{\"faction\": \"DOJ\"}', '2025-11-09 01:58:51', NULL),
(37, 'DOJ Saal Richter', 'DOJ Saal Richter', 'pc', -518.111572265625, -175.94790649414062, 38.55299377441406, 1, 1, '{\"faction\": \"DOJ\"}', '2025-11-09 01:59:57', NULL),
(38, 'DOJ Saal Richter Helfer', 'DOJ Saal Richter Helfer', 'pc', -516.1865234375, -178.3909912109375, 38.403099060058594, 1, 1, '{\"faction\": \"DOJ\"}', '2025-11-09 02:00:44', NULL),
(39, 'Vangelico', 'Manager Büro', 'pc', -631.4028930664062, -230.13150024414065, 38.057395935058594, 1, 1, '{\"faction\": \"TRADER\", \"shopTyp\": \"juwelier\"}', '2025-11-09 22:56:08', '2025-11-09 22:56:28');

-- --------------------------------------------------------

--
-- Table structure for table `inventories`
--

CREATE TABLE `inventories` (
  `id` varchar(100) NOT NULL,
  `data` json NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `npcs`
--

CREATE TABLE `npcs` (
  `id` int UNSIGNED NOT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `x` double NOT NULL,
  `y` double NOT NULL,
  `z` double NOT NULL,
  `heading` float NOT NULL DEFAULT '0',
  `scenario` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `interactionType` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `interactable` tinyint(1) NOT NULL DEFAULT '1',
  `autoGround` tinyint(1) NOT NULL DEFAULT '0',
  `groundOffset` float NOT NULL DEFAULT '0',
  `zOffset` float NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `npcs`
--

INSERT INTO `npcs` (`id`, `name`, `model`, `x`, `y`, `z`, `heading`, `scenario`, `interactionType`, `interactable`, `autoGround`, `groundOffset`, `zOffset`, `created_at`, `updated_at`) VALUES
(1, 'Sandra Wiesel', 'S_F_Y_AirHostess_01', -1116.18, -2781.21, 16.59, 244.31, 'WORLD_HUMAN_CLIPBOARD', 'airport', 1, 0, 0.1, 0, '2025-11-07 13:57:39', NULL),
(2, 'Hermann Grunzbacher', 'A_M_M_ProlHost_01', -1116.68, -2782.07, 16.59, 246.78, 'WORLD_HUMAN_CLIPBOARD', 'airport', 1, 0, 0.1, 0, '2025-11-07 13:57:39', NULL),
(3, 'Schwester Kendra', 's_f_y_scrubs_01', 308.2, -595.49, 43.28, 82.39, 'WORLD_HUMAN_CLIPBOARD', 'nurse', 1, 0, 0.1, 0, '2025-11-07 13:57:39', NULL),
(4, 'Officer Hudson', 'S_M_Y_Cop_01', 454.15, -980.16, 30.69, 95.78, 'WORLD_HUMAN_CLIPBOARD', 'cop', 1, 0, 0.1, 0, '2025-11-07 13:57:39', NULL),
(5, 'Suburban Seller 1', 'A_F_Y_SouCent_01', 126.642578125, -224.9669647216797, 54.557769775390625, 71.7415, 'WORLD_HUMAN_STAND_MOBILE_UPRIGHT', 'suburban', 1, 0, 0.1, 0, '2025-11-08 02:02:17', '2025-11-08 12:42:24'),
(6, 'Test Hannes', 'A_M_Y_Business_01', 242.7471466064453, 226.66375732421875, 106.2873764038086, 157.276, NULL, 'mainbank', 1, 0, 0.1, 0, '2025-11-08 02:26:48', '2025-11-08 12:40:16'),
(7, 'Test Hannes 2', 'A_F_Y_Business_01', 247.97882080078125, 224.6533203125, 106.28740692138672, 166.921, NULL, 'mainbank', 1, 0, 0.1, 0, '2025-11-08 02:40:16', '2025-11-08 12:40:55'),
(8, 'Test Hannes 3', 'A_M_Y_Business_02', 253.1121826171875, 222.79129028320312, 106.28694152832033, 159.886, NULL, 'mainbank', 1, 0, 0.1, 0, '2025-11-08 02:41:28', '2025-11-08 12:41:27'),
(9, '24/7 Verkäufer', 'S_F_Y_SweatShop_01', 373.0040588378906, 328.0457458496094, 103.56641387939452, 261.692, NULL, '247', 1, 0, 0.1, 0, '2025-11-08 02:44:49', '2025-11-08 12:42:46'),
(10, 'Binco Seller 1', 'S_F_Y_Shop_MID', 426.96917724609375, -806.267822265625, 29.491134643554688, 90.9133, NULL, 'binco', 1, 0, 0.1, 0, '2025-11-08 02:54:26', '2025-11-08 12:43:22'),
(11, 'JOB:BUS', 'MP_M_BoatStaff_01', 453.9884033203125, -607.3679809570312, 28.561479568481445, 261.424, 'WORLD_HUMAN_TOURIST_MAP', 'JOB:BUS', 1, 1, 0.1, 0, '2025-11-08 03:00:14', '2025-11-08 12:39:28'),
(12, 'Ammunation', 'IG_SubCrewHead', 22.590904235839844, -1105.4732666015625, 29.79704475402832, 158.151, 'WORLD_HUMAN_COP_IDLES', 'ammunation', 1, 0, 0.1, 0, '2025-11-08 13:18:07', '2025-11-08 13:57:19'),
(13, 'Ammunation 2', 'IG_SubCrewHead', -661.8543701171875, -933.5322265625, 21.8292179107666, 165.03, 'WORLD_HUMAN_AA_SMOKE', 'ammunation', 1, 0, 0.1, 0, '2025-11-08 13:57:52', NULL),
(14, 'LTD', 'S_F_Y_Shop_MID', -706.1234741210938, -914.4379272460938, 19.215574264526367, 87.3963, 'WORLD_HUMAN_STAND_MOBILE_UPRIGHT', 'ltd', 1, 0, 0.1, 0, '2025-11-08 14:02:58', NULL),
(15, 'Rob\'s Liquor Store 1', 'S_F_Y_Shop_LOW', -1486.8016357421875, -377.3836975097656, 40.16346740722656, 143.587, 'WORLD_HUMAN_STAND_MOBILE', 'liquor', 1, 0, 0.1, 0, '2025-11-08 14:19:16', NULL),
(16, 'Cityhall', 'S_F_M_Shop_HIGH', -540.908447265625, -192.766845703125, 38.21927261352539, 143.014, 'WORLD_HUMAN_STAND_IMPATIENT', 'townhall', 1, 0, 0.1, 0, '2025-11-08 16:33:42', '2025-11-09 01:52:35'),
(17, 'Ammunation 3', 'IG_SubCrewHead', -331.6467590332031, 6085.01025390625, 31.45480155944824, 219.984, 'WORLD_HUMAN_COP_IDLES', 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:14:57', NULL),
(18, 'Ammunation 4', 'IG_SubCrewHead', 1692.4056396484375, 3761.110595703125, 34.70539474487305, 230.969, 'WORLD_HUMAN_AA_COFFEE', 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:20:16', NULL),
(19, 'Ammunation 5', 'IG_SubCrewHead', -1119.1214599609375, 2699.715576171875, 18.55417251586914, 211.429, 'WORLD_HUMAN_STAND_MOBILE', 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:26:02', NULL),
(20, 'Ammunation 6', 'IG_SubCrewHead', -3173.581787109375, 1088.386474609375, 20.838743209838867, 244.521, NULL, 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:28:00', NULL),
(21, 'Ammunation 7', 'IG_SubCrewHead', 2568.2470703125, 292.6273193359375, 108.7348175048828, 2.30463, NULL, 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:31:44', NULL),
(22, '24/7 Verkäufer 2', 'S_F_Y_SweatShop_01', 2555.549072265625, 380.912841796875, 108.62288665771484, 3.73792, 'WORLD_HUMAN_AA_COFFEE', NULL, 1, 0, 0.1, 0, '2025-11-08 19:32:41', '2025-11-08 19:33:01'),
(23, 'Ammunation 8', 'IG_SubCrewHead', 253.78155517578125, -50.55192184448242, 69.94098663330078, 74.6523, NULL, 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:35:12', '2025-11-08 19:35:34'),
(24, 'Ammunation 9', 'IG_SubCrewHead', -1304.078857421875, -394.4883117675781, 36.69574737548828, 71.1362, NULL, 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:37:37', NULL),
(25, 'Ammunation 10', 'IG_SubCrewHead', 842.468505859375, -1035.31591796875, 28.19487571716309, 2.69636, 'WORLD_HUMAN_CLIPBOARD', 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:41:12', NULL),
(26, 'Ammunation 11', 'IG_SubCrewHead', 810.10302734375, -2159.053955078125, 29.61903953552246, 357.193, 'WORLD_HUMAN_DRINKING', 'ammunation', 1, 0, 0.1, 0, '2025-11-08 19:43:39', NULL),
(27, '24/7 Verkäufer', 'S_F_Y_SweatShop_01', 1728.5557861328125, 6416.6318359375, 35.03718948364258, 246.825, NULL, '247', 1, 0, 0.1, 0, '2025-11-08 19:48:29', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `pc_logs`
--

CREATE TABLE `pc_logs` (
  `id` int UNSIGNED NOT NULL,
  `faction` varchar(16) NOT NULL DEFAULT 'LSPD',
  `timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `officer_src` int UNSIGNED NOT NULL,
  `officer_char_id` int UNSIGNED DEFAULT '0',
  `officer_name` varchar(128) DEFAULT NULL,
  `action` varchar(64) NOT NULL,
  `target_person_id` int UNSIGNED DEFAULT NULL,
  `meta` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `pc_logs`
--

INSERT INTO `pc_logs` (`id`, `faction`, `timestamp`, `officer_src`, `officer_char_id`, `officer_name`, `action`, `target_person_id`, `meta`) VALUES
(51, 'LSPD', '2025-11-09 13:12:11', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(52, 'LSPD', '2025-11-09 13:13:48', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(53, 'LSPD', '2025-11-09 13:14:31', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(54, 'LSPD', '2025-11-09 13:16:03', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(55, 'LSPD', '2025-11-09 13:33:26', 2, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(56, 'LSPD', '2025-11-09 13:35:31', 2, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(57, 'LSPD', '2025-11-09 13:36:31', 2, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(58, 'LSPD', '2025-11-09 13:38:29', 2, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=kat, hits=1'),
(59, 'LSPD', '2025-11-09 13:38:46', 2, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(60, 'LSPD', '2025-11-09 18:05:00', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(61, 'LSPD', '2025-11-09 18:18:41', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(62, 'LSPD', '2025-11-09 18:20:38', 1, 6, 'Colemann,Kendra ', 'update_person', 5, 'Tanja Eisenberger (02.08.1983)'),
(63, 'LSPD', '2025-11-09 19:31:43', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(64, 'LSPD', '2025-11-09 19:36:08', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(65, 'LSPD', '2025-11-09 19:44:30', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(66, 'LSPD', '2025-11-09 19:46:06', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(67, 'LSPD', '2025-11-09 19:56:48', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(68, 'LSPD', '2025-11-09 19:56:55', 1, 6, 'Colemann,Kendra ', 'update_person', 6, 'Carl Dosenfurz (13.05.1985)'),
(69, 'LSPD', '2025-11-09 20:10:13', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(70, 'LSPD', '2025-11-09 20:10:26', 1, 6, 'Colemann,Kendra ', 'update_person', 6, 'Carl Dosenfurz (13.05.1985)'),
(71, 'LSPD', '2025-11-09 20:10:40', 1, 6, 'Colemann,Kendra ', 'update_person', 6, 'Carl Dosenfurz (13.05.1985)'),
(72, 'LSPD', '2025-11-09 20:17:53', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(73, 'LSPD', '2025-11-09 20:20:47', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(74, 'LSPD', '2025-11-09 20:27:10', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(75, 'LSPD', '2025-11-09 20:28:07', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=6'),
(76, 'LSPD', '2025-11-09 20:28:45', 1, 6, 'Colemann,Kendra ', 'create_person', 7, 'Lyra Superbrain (unbekannt)'),
(77, 'LSPD', '2025-11-09 23:48:29', 1, 6, 'Colemann,Kendra ', 'search_person', NULL, 'query=ALL, hits=7');

-- --------------------------------------------------------

--
-- Table structure for table `pc_persons`
--

CREATE TABLE `pc_persons` (
  `id` int UNSIGNED NOT NULL,
  `faction` varchar(16) NOT NULL DEFAULT 'LSPD',
  `created_from` int UNSIGNED NOT NULL,
  `first_name` varchar(64) NOT NULL,
  `last_name` varchar(64) NOT NULL,
  `date_of_birth` date NOT NULL,
  `gender` enum('m','f','d') DEFAULT NULL,
  `phone_number` varchar(32) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `driver_license` tinyint(1) DEFAULT '0',
  `weapon_license` tinyint(1) DEFAULT '0',
  `pilot_license` tinyint(1) DEFAULT '0',
  `boat_license` tinyint(1) DEFAULT '0',
  `is_dead` tinyint(1) DEFAULT '0',
  `is_wanted` tinyint(1) DEFAULT '0',
  `is_exited` tinyint(1) DEFAULT '0',
  `status` varchar(32) GENERATED ALWAYS AS ((case when (`is_dead` = 1) then _utf8mb4'Verstorben' when (`is_wanted` = 1) then _utf8mb4'Gesucht' when (`is_exited` = 1) then _utf8mb4'Ausgereist' else _utf8mb4'Normal' end)) STORED,
  `danger_level` tinyint UNSIGNED DEFAULT '0',
  `notes` text,
  `mugshot_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `pc_persons`
--

INSERT INTO `pc_persons` (`id`, `faction`, `created_from`, `first_name`, `last_name`, `date_of_birth`, `gender`, `phone_number`, `address`, `driver_license`, `weapon_license`, `pilot_license`, `boat_license`, `is_dead`, `is_wanted`, `is_exited`, `danger_level`, `notes`, `mugshot_url`, `created_at`, `updated_at`) VALUES
(1, 'LSPD', 6, 'test', 'test', '1999-02-05', 'd', '65465465465465456', 'Keine', 1, 1, 1, 1, 0, 1, 0, 4, 'Test', NULL, '2025-11-08 23:30:32', '2025-11-09 02:40:47'),
(2, 'LSPD', 6, 'Hans', 'Kohlenberg', '1985-07-11', 'm', '5445481878477481', 'Keine Adresse', 1, 1, 0, 0, 0, 0, 0, 3, 'Eine Notiz', NULL, '2025-11-08 23:49:37', '2025-11-09 02:40:45'),
(3, 'LSPD', 6, 'Katharina', 'Freiherz', '2020-02-11', 'f', '5552556455565655', NULL, 0, 0, 1, 0, 0, 1, 0, 2, 'Ufbasse', NULL, '2025-11-09 00:00:01', '2025-11-09 12:50:09'),
(4, 'LSPD', 6, 'Kim', 'Kokser', '1996-12-12', 'm', NULL, NULL, 0, 0, 0, 0, 1, 0, 0, 0, NULL, NULL, '2025-11-09 00:00:29', '2025-11-09 02:40:39'),
(5, 'LSPD', 6, 'Tanja', 'Eisenberger', '1983-08-02', 'f', '68417541787851785', 'kjhmjkjkhjk j k', 1, 1, 0, 1, 0, 0, 1, 3, 'Hat das land verlassen', NULL, '2025-11-09 00:01:40', '2025-11-09 18:20:38'),
(6, 'LSPD', 6, 'Carl', 'Dosenfurz', '1985-05-13', 'm', '546546546546556', 'Keine', 1, 0, 1, 0, 0, 0, 0, 2, 'Blaue Jacke', NULL, '2025-11-09 02:40:04', '2025-11-09 20:10:40'),
(7, 'LSPD', 6, 'Lyra', 'Superbrain', '1970-01-01', 'f', '0123456789', 'Bei OpenAI', 0, 0, 0, 0, 0, 0, 0, 0, 'Besti', NULL, '2025-11-09 20:28:45', '2025-11-09 20:28:45');

-- --------------------------------------------------------

--
-- Table structure for table `player_inventory`
--

CREATE TABLE `player_inventory` (
  `identifier` varchar(255) NOT NULL,
  `inventory` json NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `player_inventory`
--

INSERT INTO `player_inventory` (`identifier`, `inventory`) VALUES
('license:324864cc65849e68e11dd4c83839b9ac0cd89042', '{\"20\": {\"info\": {\"quality\": 0, \"startdate\": 1762020872}, \"name\": \"water\", \"slot\": 20, \"label\": \"Water\", \"amount\": 1}, \"21\": {\"info\": {\"quality\": 0, \"startdate\": 1762020872}, \"name\": \"water\", \"slot\": 21, \"label\": \"Water\", \"amount\": 4}}');

-- --------------------------------------------------------

--
-- Table structure for table `wallets`
--

CREATE TABLE `wallets` (
  `owner` int NOT NULL,
  `cash` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `wallets`
--

INSERT INTO `wallets` (`owner`, `cash`) VALUES
(6, 100),
(7, 10000);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `uq_accounts_discord` (`discord_id`);

--
-- Indexes for table `bank_accounts`
--
ALTER TABLE `bank_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_account_number` (`account_number`),
  ADD KEY `idx_owner` (`owner`);

--
-- Indexes for table `bank_log`
--
ALTER TABLE `bank_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_account_number` (`account_number`);

--
-- Indexes for table `blips`
--
ALTER TABLE `blips`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `characters`
--
ALTER TABLE `characters`
  ADD PRIMARY KEY (`id`),
  ADD KEY `account_id` (`account_id`);

--
-- Indexes for table `connection_logs`
--
ALTER TABLE `connection_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_license` (`identifier_license`),
  ADD KEY `idx_steam` (`identifier_steam`),
  ADD KEY `idx_discord` (`identifier_discord`);

--
-- Indexes for table `death_logs`
--
ALTER TABLE `death_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `factions`
--
ALTER TABLE `factions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_faction_name` (`name`),
  ADD KEY `idx_leader_char` (`leader_char_id`),
  ADD KEY `idx_created_by` (`created_by`);

--
-- Indexes for table `faction_logs`
--
ALTER TABLE `faction_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_faction_time` (`faction_id`,`created_at`),
  ADD KEY `idx_actor_char` (`actor_char_id`),
  ADD KEY `idx_target_char` (`target_char_id`);

--
-- Indexes for table `faction_members`
--
ALTER TABLE `faction_members`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_member_per_faction` (`faction_id`,`char_id`),
  ADD KEY `idx_member_char` (`char_id`),
  ADD KEY `idx_member_rank` (`rank_id`);

--
-- Indexes for table `faction_permission_schema`
--
ALTER TABLE `faction_permission_schema`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_perm_key` (`perm_key`);

--
-- Indexes for table `faction_ranks`
--
ALTER TABLE `faction_ranks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_rank_name` (`faction_id`,`name`),
  ADD UNIQUE KEY `uniq_rank_level` (`faction_id`,`level`),
  ADD KEY `idx_rank_faction` (`faction_id`);

--
-- Indexes for table `interaction_points`
--
ALTER TABLE `interaction_points`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `inventories`
--
ALTER TABLE `inventories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `npcs`
--
ALTER TABLE `npcs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pc_logs`
--
ALTER TABLE `pc_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_officer` (`officer_char_id`),
  ADD KEY `idx_target` (`target_person_id`),
  ADD KEY `idx_faction_time` (`faction`,`timestamp`);

--
-- Indexes for table `pc_persons`
--
ALTER TABLE `pc_persons`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_name` (`last_name`,`first_name`),
  ADD KEY `idx_status` (`is_dead`,`is_wanted`,`is_exited`),
  ADD KEY `idx_faction_name` (`faction`,`last_name`,`first_name`);

--
-- Indexes for table `player_inventory`
--
ALTER TABLE `player_inventory`
  ADD PRIMARY KEY (`identifier`);

--
-- Indexes for table `wallets`
--
ALTER TABLE `wallets`
  ADD PRIMARY KEY (`owner`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `bank_accounts`
--
ALTER TABLE `bank_accounts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `bank_log`
--
ALTER TABLE `bank_log`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `blips`
--
ALTER TABLE `blips`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `characters`
--
ALTER TABLE `characters`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `connection_logs`
--
ALTER TABLE `connection_logs`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=346;

--
-- AUTO_INCREMENT for table `death_logs`
--
ALTER TABLE `death_logs`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `factions`
--
ALTER TABLE `factions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `faction_logs`
--
ALTER TABLE `faction_logs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `faction_members`
--
ALTER TABLE `faction_members`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `faction_permission_schema`
--
ALTER TABLE `faction_permission_schema`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `faction_ranks`
--
ALTER TABLE `faction_ranks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `interaction_points`
--
ALTER TABLE `interaction_points`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `npcs`
--
ALTER TABLE `npcs`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `pc_logs`
--
ALTER TABLE `pc_logs`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=78;

--
-- AUTO_INCREMENT for table `pc_persons`
--
ALTER TABLE `pc_persons`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bank_log`
--
ALTER TABLE `bank_log`
  ADD CONSTRAINT `fk_log_account` FOREIGN KEY (`account_number`) REFERENCES `bank_accounts` (`account_number`) ON DELETE CASCADE;

--
-- Constraints for table `characters`
--
ALTER TABLE `characters`
  ADD CONSTRAINT `characters_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `factions`
--
ALTER TABLE `factions`
  ADD CONSTRAINT `fk_factions_created_by` FOREIGN KEY (`created_by`) REFERENCES `characters` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_factions_leader_char` FOREIGN KEY (`leader_char_id`) REFERENCES `characters` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `faction_logs`
--
ALTER TABLE `faction_logs`
  ADD CONSTRAINT `fk_logs_actor_char` FOREIGN KEY (`actor_char_id`) REFERENCES `characters` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_logs_faction` FOREIGN KEY (`faction_id`) REFERENCES `factions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_logs_target_char` FOREIGN KEY (`target_char_id`) REFERENCES `characters` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `faction_members`
--
ALTER TABLE `faction_members`
  ADD CONSTRAINT `fk_members_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_members_faction` FOREIGN KEY (`faction_id`) REFERENCES `factions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_members_rank` FOREIGN KEY (`rank_id`) REFERENCES `faction_ranks` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `faction_ranks`
--
ALTER TABLE `faction_ranks`
  ADD CONSTRAINT `fk_ranks_faction` FOREIGN KEY (`faction_id`) REFERENCES `factions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
