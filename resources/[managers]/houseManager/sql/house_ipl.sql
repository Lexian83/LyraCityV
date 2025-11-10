CREATE TABLE `house_ipl` (
  `id` int NOT NULL AUTO_INCREMENT,
  `ipl_name` varchar(128) NOT NULL,
  `posx` double NOT NULL,
  `posy` double NOT NULL,
  `posz` double NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_ipl_name` (`ipl_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
