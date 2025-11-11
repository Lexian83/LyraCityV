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
(39, 'Vangelico', 'Manager Büro', 'pc', -631.4028930664062, -230.13150024414065, 38.057395935058594, 1, 1, '{\"faction\": \"TRADER\", \"shopTyp\": \"juwelier\"}', '2025-11-09 22:56:08', '2025-11-09 22:56:28'),
(40, 'HOUSE', 'Test', 'house', 268.99090576171875, -1706.2708740234375, 29.63964080810547, 1, 1, '{\"houseid\": 1}', '2025-11-11 01:19:44', NULL),
(41, 'HOUSE_GARAGE', 'Test', 'garage', 270.29376220703125, -1706.2640380859375, 29.30772590637207, 1, 1, '{\"houseid\": 1}', '2025-11-11 01:19:44', NULL),
(42, 'EXIT_HOUSE', 'Test', 'house', 266.2860412597656, -1007.3653564453124, -101.00879669189452, 1, 1, '{\"houseid\": 1}', '2025-11-11 01:19:44', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `interaction_points`
--
ALTER TABLE `interaction_points`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `interaction_points`
--
ALTER TABLE `interaction_points`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
