-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20251020.3eab4de5d8
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 11, 2025 at 07:46 AM
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
-- Table structure for table `houses`
--

CREATE TABLE `houses` (
  `id` int NOT NULL,
  `name` varchar(128) NOT NULL,
  `ownerid` int DEFAULT NULL,
  `entry_x` double NOT NULL,
  `entry_y` double NOT NULL,
  `entry_z` double NOT NULL,
  `garage_trigger_x` double DEFAULT NULL,
  `garage_trigger_y` double DEFAULT NULL,
  `garage_trigger_z` double DEFAULT NULL,
  `garage_x` double DEFAULT NULL,
  `garage_y` double DEFAULT NULL,
  `garage_z` double DEFAULT NULL,
  `price` int NOT NULL DEFAULT '0',
  `buyed_at` datetime DEFAULT NULL,
  `rent` int DEFAULT NULL,
  `rent_start` datetime DEFAULT NULL,
  `data` json DEFAULT NULL,
  `lock_state` tinyint(1) NOT NULL DEFAULT '1',
  `inside_x` double DEFAULT NULL,
  `inside_y` double DEFAULT NULL,
  `inside_z` double DEFAULT NULL,
  `ipl` int DEFAULT NULL,
  `fridgeid` int DEFAULT NULL,
  `storeid` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `houses`
--

INSERT INTO `houses` (`id`, `name`, `ownerid`, `entry_x`, `entry_y`, `entry_z`, `garage_trigger_x`, `garage_trigger_y`, `garage_trigger_z`, `garage_x`, `garage_y`, `garage_z`, `price`, `buyed_at`, `rent`, `rent_start`, `data`, `lock_state`, `inside_x`, `inside_y`, `inside_z`, `ipl`, `fridgeid`, `storeid`) VALUES
(1, 'Test', NULL, 268.99090576171875, -1706.2708740234375, 29.63964080810547, 270.29376220703125, -1706.2640380859375, 29.30772590637207, 267.7109680175781, -1702.60009765625, 29.279462814331055, 20000, NULL, 90, NULL, NULL, 1, NULL, NULL, NULL, 1, NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `houses`
--
ALTER TABLE `houses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ownerid` (`ownerid`),
  ADD KEY `idx_ipl` (`ipl`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `houses`
--
ALTER TABLE `houses`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
