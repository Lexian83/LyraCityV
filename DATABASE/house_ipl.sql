-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20251020.3eab4de5d8
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 11, 2025 at 07:47 AM
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
-- Table structure for table `house_ipl`
--

CREATE TABLE `house_ipl` (
  `id` int NOT NULL,
  `ipl_name` varchar(128) NOT NULL,
  `ipl` varchar(128) DEFAULT NULL,
  `posx` double NOT NULL,
  `posy` double NOT NULL,
  `posz` double NOT NULL,
  `exit_x` double DEFAULT NULL,
  `exit_y` double DEFAULT NULL,
  `exit_z` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `house_ipl`
--

INSERT INTO `house_ipl` (`id`, `ipl_name`, `ipl`, `posx`, `posy`, `posz`, `exit_x`, `exit_y`, `exit_z`) VALUES
(1, 'Low End Apartment', '', 265.6478271484375, -1003.2529296875, -99.00875854492188, 266.2860412597656, -1007.3653564453124, -101.00879669189452),
(2, 'Medium End Apartment', '', 346.724853515625, -1009.2567749023438, -99.19637298583984, 346.4737854003906, -1013.0563354492188, -99.19637298583984),
(3, '4 Integrity Way, Apt 28', '', -30.70490837097168, -588.7861938476562, 78.83039855957031, -30.870908737182617, -589.4641723632812, 78.83039855957031),
(4, '4 Integrity Way, Apt 30', '', -17.055646896362305, -587.291015625, 90.11473846435548, -17.87248992919922, -589.7589111328125, 90.11473846435548),
(5, 'Dell Perro Heights, Apt 4', '', -1456.9715576171875, -545.7459106445312, 72.84383392333984, -1455.975830078125, -544.8741455078125, 72.84383392333984);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `house_ipl`
--
ALTER TABLE `house_ipl`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_ipl_name` (`ipl_name`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `house_ipl`
--
ALTER TABLE `house_ipl`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
