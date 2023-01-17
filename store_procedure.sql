-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         8.0.30 - MySQL Community Server - GPL
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.1.0.6537
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Volcando estructura de base de datos para pdb
CREATE DATABASE IF NOT EXISTS `pdb` /*!40100 DEFAULT CHARACTER SET armscii8 COLLATE armscii8_bin */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `pdb`;

-- Volcando estructura para función pdb.CurrentDateTime
DELIMITER //
CREATE FUNCTION `CurrentDateTime`() RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE cDateTime DATETIME;
    SET cDateTime = NOW();
    RETURN cDateTime;
END//
DELIMITER ;

-- Volcando estructura para procedimiento pdb.db_insert
DELIMITER //
CREATE PROCEDURE `db_insert`(
	IN `IDEstacion` VARCHAR(50),
	IN `Arrive` DATETIME,
	IN `Tiempo` DATETIME,
	IN `pH` VARCHAR(50),
	IN `Conductividad` VARCHAR(50),
	IN `Temperatura` VARCHAR(50),
	IN `Caudal` VARCHAR(50),
	IN `Nivel` VARCHAR(50),
	IN `Volumen` VARCHAR(50)
)
IF((SELECT COUNT(*) AS CUENTA FROM mediciones_continuas  WHERE estacion=IDEstacion AND TIMESTAMP =Tiempo) < 1) THEN

 INSERT IGNORE INTO mediciones_continuas  (estacion,Timestamp_arrive,TIMESTAMP,ph,conductividad,temperatura,caudal, nivel,volumen) VALUES 
 (IDEstacion,Arrive,Tiempo,pH,Conductividad,Temperatura,Caudal,Nivel, Volumen); 

  IF((SELECT COUNT(*) FROM ultimas_lecturas WHERE estacion=IDEstacion  > 0)) THEN
  
  UPDATE ultimas_lecturas SET TIMESTAMP=tiempo WHERE estacion =IDEstacion;  
  
  ELSE
  
  INSERT INTO ultimas_lecturas (estacion,TIMESTAMP) VALUES (IDEstacion,Tiempo);    
    
  END IF;

 
END IF//
DELIMITER ;

-- Volcando estructura para procedimiento pdb.estaciones_habilitadas
DELIMITER //
CREATE PROCEDURE `estaciones_habilitadas`()
BEGIN
SELECT e.nombre_estacion FROM estaciones e WHERE e.`enable`='1';
END//
DELIMITER ;

-- Volcando estructura para procedimiento pdb.lecturas_ordenadas
DELIMITER //
CREATE PROCEDURE `lecturas_ordenadas`()
BEGIN
SELECT * FROM ultimas_lecturas m ORDER BY m.timestamp;   
END//
DELIMITER ;

-- Volcando estructura para función pdb.UltimaLectura
DELIMITER //
CREATE FUNCTION `UltimaLectura`(
	`Device` VARCHAR(50)
) RETURNS datetime
    DETERMINISTIC
BEGIN
     DECLARE cDateTime DATETIME;
     SET cDateTime = (SELECT MAX(m.Timestamp) FROM mediciones_continuas m WHERE m.estacion = Device);
     RETURN cDateTime;

END//
DELIMITER ;

-- Volcando estructura para procedimiento pdb.ultimas_lecturas
DELIMITER //
CREATE PROCEDURE `ultimas_lecturas`()
BEGIN
SELECT * FROM ultimas_lecturas;
END//
DELIMITER ;

-- Volcando estructura para procedimiento pdb.UpdateTimestampST
DELIMITER //
CREATE PROCEDURE `UpdateTimestampST`(
	IN `device` VARCHAR(50)
)
BEGIN
  UPDATE ultimas_lecturas  m SET m.time_transfer = NOW() WHERE  m.estacion=device;
END//
DELIMITER ;

-- Volcando estructura para procedimiento pdb.update_ultimas_lecturas
DELIMITER //
CREATE PROCEDURE `update_ultimas_lecturas`()
BEGIN
  -- Crear un cursor para obtener la lista de elementos
DECLARE elemento VARCHAR(255);
DECLARE tiempo VARCHAR(255);
DECLARE done INT DEFAULT 0;
DECLARE cursor_elementos CURSOR FOR
SELECT e.nombre_estacion FROM estaciones e WHERE e.`enable`='1';
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    -- Abrir el cursor
    OPEN cursor_elementos;
    -- Iterar sobre cada elemento en la lista
    read_loop: LOOP
        FETCH cursor_elementos INTO elemento;            
         UPDATE ultimas_lecturas  m SET  m.timestamp=UltimaLectura(elemento) WHERE m.estacion=elemento;        
         CALL UpdateTimestampST(elemento);
        IF done THEN
          LEAVE read_loop;
        END IF;      
    END LOOP;
    -- Cerrar y liberar el cursor
    CLOSE cursor_elementos;
    CALL lecturas_ordenadas();
    
END//
DELIMITER ;

-- Volcando estructura para disparador pdb.med_continuas
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `med_continuas` BEFORE INSERT ON `mediciones_continuas` FOR EACH ROW BEGIN
SET NEW.Timestamp_arrive=NOW();
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador pdb.perfilajes_before_insert
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `perfilajes_before_insert` BEFORE INSERT ON `perfilajes` FOR EACH ROW SET NEW.upload=NOW()//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador pdb.puntuales_updt
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `puntuales_updt` BEFORE INSERT ON `mediciones_puntuales` FOR EACH ROW BEGIN
SET NEW.date_up=NOW();
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
