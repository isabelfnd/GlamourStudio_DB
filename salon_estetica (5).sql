-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 22-05-2026 a las 18:36:36
-- Versión del servidor: 9.4.0
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `salon_estetica`
--
CREATE DATABASE IF NOT EXISTS `salon_estetica` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `salon_estetica`;

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `sp_cancelar_cita`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_cita` (IN `p_id_cita` INT)   BEGIN

    UPDATE cita
    SET estado = 'Cancelada'
    WHERE id_cita = p_id_cita;

END$$

DROP PROCEDURE IF EXISTS `sp_completar_cita`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_completar_cita` (IN `p_id_cita` INT)   BEGIN

    UPDATE cita
    SET estado = 'Completada'
    WHERE id_cita = p_id_cita;

END$$

DROP PROCEDURE IF EXISTS `sp_historial_cliente`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_historial_cliente` (IN `p_id_cliente` INT)   BEGIN
    SELECT 
        ci.id_cita,
        ci.fecha,
        s.nombre AS servicio,
        e.nombre AS estilista,
        ci.estado
    FROM cita ci
    INNER JOIN detalle_cita dc ON ci.id_cita = dc.id_cita
    INNER JOIN servicio s ON dc.id_servicio = s.id_servicio
    INNER JOIN estilista e ON dc.id_estilista = e.id_estilista
    WHERE ci.id_cliente = p_id_cliente
    ORDER BY ci.fecha DESC;
END$$

DROP PROCEDURE IF EXISTS `sp_registrar_cita`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_cita` (IN `p_id_cliente` INT, IN `p_fecha` DATETIME)   BEGIN

    INSERT INTO cita(id_cliente, fecha)
    VALUES(p_id_cliente, p_fecha);

END$$

DROP PROCEDURE IF EXISTS `sp_reporte_ingresos_periodo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reporte_ingresos_periodo` (IN `p_fecha_inicio` DATETIME, IN `p_fecha_fin` DATETIME)   BEGIN
    SELECT 
        COUNT(id_cita) AS total_citas_atendidas,
        SUM(fn_total_cita(id_cita)) AS ingresos_netos_recaudados
    FROM cita
    WHERE fecha BETWEEN p_fecha_inicio AND p_fecha_fin
      AND estado = 'Completada';
END$$

--
-- Funciones
--
DROP FUNCTION IF EXISTS `fn_total_cita`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_total_cita` (`p_id_cita` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_descuento_porcentaje DECIMAL(5,2);
    DECLARE v_total_con_descuento DECIMAL(10,2);

    SELECT SUM(s.precio)
    INTO v_subtotal
    FROM detalle_cita dc
    INNER JOIN servicio s ON dc.id_servicio = s.id_servicio
    WHERE dc.id_cita = p_id_cita;


    IF v_subtotal IS NULL THEN
        RETURN 0.00;
    END IF;

    SELECT cc.descuento
    INTO v_descuento_porcentaje
    FROM cita ci
    INNER JOIN cliente cl ON ci.id_cliente = cl.id_cliente
    INNER JOIN categoria_cliente cc ON cl.id_categoria = cc.id_categoria
    WHERE ci.id_cita = p_id_cita;

    IF v_descuento_porcentaje IS NULL THEN
        SET v_descuento_porcentaje = 0.00;
    END IF;

    SET v_total_con_descuento = v_subtotal - (v_subtotal * (v_descuento_porcentaje / 100));

    RETURN v_total_con_descuento;
END$$

DROP FUNCTION IF EXISTS `fn_total_citas_cliente`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_total_citas_cliente` (`p_id_cliente` INT) RETURNS INT DETERMINISTIC BEGIN

    DECLARE cantidad INT;

    SELECT COUNT(*)
    INTO cantidad
    FROM cita
    WHERE id_cliente = p_id_cliente;

    RETURN cantidad;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria_cliente`
--

DROP TABLE IF EXISTS `categoria_cliente`;
CREATE TABLE `categoria_cliente` (
  `id_categoria` int NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `min_citas` int DEFAULT '0',
  `descuento` decimal(5,2) DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `categoria_cliente`
--

INSERT INTO `categoria_cliente` (`id_categoria`, `nombre`, `min_citas`, `descuento`) VALUES
(1, 'Normal', 0, 0.00),
(2, 'Frecuente', 5, 5.00),
(3, 'Preferencial', 15, 10.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria_servicio`
--

DROP TABLE IF EXISTS `categoria_servicio`;
CREATE TABLE `categoria_servicio` (
  `id_categoria_servicio` int NOT NULL,
  `id_especialidad` int NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categoria_servicio`
--

INSERT INTO `categoria_servicio` (`id_categoria_servicio`, `id_especialidad`, `nombre`) VALUES
(1, 1, 'Fade'),
(2, 1, 'Bob'),
(3, 2, 'Balayage'),
(4, 2, 'Mechas'),
(5, 3, 'Perfilado'),
(6, 4, 'Semipermanente'),
(7, 5, 'Spa');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cita`
--

DROP TABLE IF EXISTS `cita`;
CREATE TABLE `cita` (
  `id_cita` int NOT NULL,
  `id_cliente` int DEFAULT NULL,
  `id_estilista` int DEFAULT NULL,
  `fecha` datetime NOT NULL,
  `estado` varchar(20) DEFAULT NULL,
  `duracion_total` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Disparadores `cita`
--
DROP TRIGGER IF EXISTS `trg_actualizar_categoria`;
DELIMITER $$
CREATE TRIGGER `trg_actualizar_categoria` AFTER INSERT ON `cita` FOR EACH ROW BEGIN
    DECLARE total_citas INT;
    DECLARE v_id_categoria INT;

    SELECT COUNT(*)
    INTO total_citas
    FROM cita
    WHERE id_cliente = NEW.id_cliente;

    SELECT id_categoria
    INTO v_id_categoria
    FROM categoria_cliente
    WHERE total_citas >= min_citas
    ORDER BY min_citas DESC
    LIMIT 1;

    UPDATE cliente
    SET id_categoria = v_id_categoria
    WHERE id_cliente = NEW.id_cliente;

END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `trg_validar_cita`;
DELIMITER $$
CREATE TRIGGER `trg_validar_cita` BEFORE INSERT ON `cita` FOR EACH ROW BEGIN
    DECLARE existe INT;

    -- Validamos si el MISMO estilista ya tiene una cita ocupada en esa misma fecha y hora
    SELECT COUNT(*)
    INTO existe
    FROM cita
    WHERE fecha = NEW.fecha 
      AND id_estilista = NEW.id_estilista
      AND estado != 'Cancelada'; -- Una cita cancelada libera el horario

    IF existe > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El estilista seleccionado ya tiene una cita agendada en esa fecha y hora';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

DROP TABLE IF EXISTS `cliente`;
CREATE TABLE `cliente` (
  `id_cliente` int NOT NULL,
  `id_categoria` int DEFAULT NULL,
  `nombre1` varchar(50) NOT NULL,
  `nombre2` varchar(50) DEFAULT NULL,
  `apellido1` varchar(50) NOT NULL,
  `apellido2` varchar(50) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `fecha_registro` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Disparadores `cliente`
--
DROP TRIGGER IF EXISTS `trg_no_eliminar_cliente`;
DELIMITER $$
CREATE TRIGGER `trg_no_eliminar_cliente` BEFORE DELETE ON `cliente` FOR EACH ROW BEGIN

    DECLARE total INT;

    SELECT COUNT(*)
    INTO total
    FROM cita
    WHERE id_cliente = OLD.id_cliente;

    IF total > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar un cliente con historial';

    END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_cita`
--

DROP TABLE IF EXISTS `detalle_cita`;
CREATE TABLE `detalle_cita` (
  `id_detalle` int NOT NULL,
  `id_cita` int DEFAULT NULL,
  `id_servicio` int DEFAULT NULL,
  `id_estilista` int DEFAULT NULL,
  `fecha` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `especialidad`
--

DROP TABLE IF EXISTS `especialidad`;
CREATE TABLE `especialidad` (
  `id_especialidad` int NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `especialidad`
--

INSERT INTO `especialidad` (`id_especialidad`, `nombre`) VALUES
(1, 'Corte de Cabello'),
(2, 'Colorimetria'),
(3, 'Barberia'),
(4, 'Manicure'),
(5, 'Pedicure');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estilista`
--

DROP TABLE IF EXISTS `estilista`;
CREATE TABLE `estilista` (
  `id_estilista` int NOT NULL,
  `id_especialidad` int DEFAULT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `estilista`
--

INSERT INTO `estilista` (`id_estilista`, `id_especialidad`, `nombre`) VALUES
(1, 1, 'Laura Gomez'),
(2, 2, 'Camila Ruiz'),
(3, 3, 'Andres Perez'),
(4, 4, 'Sofia Martinez'),
(5, 5, 'Valentina Castro');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estilista_servicio`
--

DROP TABLE IF EXISTS `estilista_servicio`;
CREATE TABLE `estilista_servicio` (
  `id_estilista` int NOT NULL,
  `id_servicio` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `estilista_servicio`
--

INSERT INTO `estilista_servicio` (`id_estilista`, `id_servicio`) VALUES
(1, 1),
(1, 2),
(1, 3),
(2, 4),
(2, 5),
(3, 6),
(4, 7),
(5, 8);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `servicio`
--

DROP TABLE IF EXISTS `servicio`;
CREATE TABLE `servicio` (
  `id_servicio` int NOT NULL,
  `id_especialidad` int DEFAULT NULL,
  `nombre` varchar(100) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `duracion` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_clientes_frecuentes`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vw_clientes_frecuentes`;
CREATE TABLE `vw_clientes_frecuentes` (
`id_cliente` int
,`cliente` varchar(101)
,`total_citas` bigint
,`categoria` varchar(50)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vw_servicios_populares`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vw_servicios_populares`;
CREATE TABLE `vw_servicios_populares` (
`servicio` varchar(100)
,`cantidad` bigint
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_clientes_frecuentes`
--
DROP TABLE IF EXISTS `vw_clientes_frecuentes`;

DROP VIEW IF EXISTS `vw_clientes_frecuentes`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_clientes_frecuentes`  AS SELECT `cl`.`id_cliente` AS `id_cliente`, concat(`cl`.`nombre1`,' ',`cl`.`apellido1`) AS `cliente`, count(`ci`.`id_cita`) AS `total_citas`, `cc`.`nombre` AS `categoria` FROM ((`cliente` `cl` left join `cita` `ci` on((`cl`.`id_cliente` = `ci`.`id_cliente`))) left join `categoria_cliente` `cc` on((`cl`.`id_categoria` = `cc`.`id_categoria`))) GROUP BY `cl`.`id_cliente` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vw_servicios_populares`
--
DROP TABLE IF EXISTS `vw_servicios_populares`;

DROP VIEW IF EXISTS `vw_servicios_populares`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_servicios_populares`  AS SELECT `s`.`nombre` AS `servicio`, count(`dc`.`id_servicio`) AS `cantidad` FROM (`detalle_cita` `dc` join `servicio` `s` on((`dc`.`id_servicio` = `s`.`id_servicio`))) GROUP BY `s`.`id_servicio` ORDER BY count(`dc`.`id_servicio`) DESC ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categoria_cliente`
--
ALTER TABLE `categoria_cliente`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `categoria_servicio`
--
ALTER TABLE `categoria_servicio`
  ADD PRIMARY KEY (`id_categoria_servicio`),
  ADD KEY `fk_categoria_servicio_especialidad` (`id_especialidad`);

--
-- Indices de la tabla `cita`
--
ALTER TABLE `cita`
  ADD PRIMARY KEY (`id_cita`),
  ADD KEY `fk_cita_cliente` (`id_cliente`),
  ADD KEY `fk_cita_estilista` (`id_estilista`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`id_cliente`),
  ADD KEY `fk_cliente_categoria` (`id_categoria`);

--
-- Indices de la tabla `detalle_cita`
--
ALTER TABLE `detalle_cita`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `fk_detalle_cita` (`id_cita`),
  ADD KEY `fk_detalle_servicio` (`id_servicio`),
  ADD KEY `fk_detalle_estilista` (`id_estilista`);

--
-- Indices de la tabla `especialidad`
--
ALTER TABLE `especialidad`
  ADD PRIMARY KEY (`id_especialidad`);

--
-- Indices de la tabla `estilista`
--
ALTER TABLE `estilista`
  ADD PRIMARY KEY (`id_estilista`),
  ADD KEY `fk_estilista_especialidad` (`id_especialidad`);

--
-- Indices de la tabla `servicio`
--
ALTER TABLE `servicio`
  ADD PRIMARY KEY (`id_servicio`),
  ADD KEY `fk_servicio_especialidad` (`id_especialidad`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categoria_cliente`
--
ALTER TABLE `categoria_cliente`
  MODIFY `id_categoria` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `cita`
--
ALTER TABLE `cita`
  MODIFY `id_cita` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `id_cliente` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalle_cita`
--
ALTER TABLE `detalle_cita`
  MODIFY `id_detalle` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `especialidad`
--
ALTER TABLE `especialidad`
  MODIFY `id_especialidad` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `estilista`
--
ALTER TABLE `estilista`
  MODIFY `id_estilista` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `servicio`
--
ALTER TABLE `servicio`
  MODIFY `id_servicio` int NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cita`
--
ALTER TABLE `cita`
  ADD CONSTRAINT `fk_cita_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`),
  ADD CONSTRAINT `fk_cita_estilista` FOREIGN KEY (`id_estilista`) REFERENCES `estilista` (`id_estilista`);

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `fk_cliente_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categoria_cliente` (`id_categoria`);

--
-- Filtros para la tabla `detalle_cita`
--
ALTER TABLE `detalle_cita`
  ADD CONSTRAINT `fk_detalle_cita` FOREIGN KEY (`id_cita`) REFERENCES `cita` (`id_cita`),
  ADD CONSTRAINT `fk_detalle_estilista` FOREIGN KEY (`id_estilista`) REFERENCES `estilista` (`id_estilista`),
  ADD CONSTRAINT `fk_detalle_servicio` FOREIGN KEY (`id_servicio`) REFERENCES `servicio` (`id_servicio`);

--
-- Filtros para la tabla `estilista`
--
ALTER TABLE `estilista`
  ADD CONSTRAINT `fk_estilista_especialidad` FOREIGN KEY (`id_especialidad`) REFERENCES `especialidad` (`id_especialidad`);

--
-- Filtros para la tabla `servicio`
--
ALTER TABLE `servicio`
  ADD CONSTRAINT `fk_servicio_especialidad` FOREIGN KEY (`id_especialidad`) REFERENCES `especialidad` (`id_especialidad`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
