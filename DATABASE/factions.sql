-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20251020.3eab4de5d8
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 10, 2025 at 01:25 PM
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

--
-- Indexes for dumped tables
--

--
-- Indexes for table `factions`
--
ALTER TABLE `factions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_faction_name` (`name`),
  ADD KEY `idx_leader_char` (`leader_char_id`),
  ADD KEY `idx_created_by` (`created_by`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `factions`
--
ALTER TABLE `factions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `factions`
--
ALTER TABLE `factions`
  ADD CONSTRAINT `fk_factions_created_by` FOREIGN KEY (`created_by`) REFERENCES `characters` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_factions_leader_char` FOREIGN KEY (`leader_char_id`) REFERENCES `characters` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
