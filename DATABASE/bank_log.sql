-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20251020.3eab4de5d8
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 10, 2025 at 11:16 PM
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
-- Indexes for dumped tables
--

--
-- Indexes for table `bank_log`
--
ALTER TABLE `bank_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_account_number` (`account_number`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bank_log`
--
ALTER TABLE `bank_log`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bank_log`
--
ALTER TABLE `bank_log`
  ADD CONSTRAINT `fk_log_account` FOREIGN KEY (`account_number`) REFERENCES `bank_accounts` (`account_number`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
