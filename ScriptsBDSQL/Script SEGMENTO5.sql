--UPDATE BEF00100 SET SGMNTID=REPLACE(SGMNTID,'.','')
--RN-02-06-2022 prueba
ALTER TABLE BEF00100 ALTER COLUMN DSCRIPTN CHAR(40) 
INSERT INTO BEF00100 (SGMNTID,DSCRIPTN)
VALUES 
('11101','Caja'),
('11102','Bancos del Pa?s'),
('11103','Bancos del Exterior'),
('11104','Fondos en Tr?nsito'),
('11105','Inversiones a Plazo'),
('11201','Efectos por Cobrar'),
('11301','Deudores por Ventas de Mercac?as'),
('11302','Deudores por Aduanas'),
('11303','Deudores L?neas Navieras'),
('11304','Deudores por Servicios'),
('11305','Deudores por Giros'),
('11306','Costos No Facturados'),
('11309','Cuenta de Garant?a - Deudores por Venta'),
('11401','Deudores Varios'),
('11402','Deudores Empleados'),
('11403','Cuentas de Viajes'),
('11404','Deudores Fiscales'),
('11405','Adelantos a Proveedores'),
('11407','Ctas. Ctes. Comerciales'),
('11408','Ctas. Ctes. Comerciales No Consolidadas'),
('11409','Cuenta de Garant?a'),
('11501','Inventario para la Venta'),
('11503','Productos Terminados'),
('11504','Productos en Proceso'),
('11505','Materias Primas'),
('11507','Envios en Tr?nsito'),
('11509','Reserva para Inventario'),
('12101','Gastos Anticipados'),
('13101','Activo Fijo'),
('13201','Activo Fijo - Revalorizaci?n'),
('13301','Construcciones en Proceso'),
('13501','Depreciaci?n - Amortizaci?n Acumulada'),
('15101','Acciones y Cuotas - Consolidadas'),
('15102','Primas, Sobre Precio, Menor Precio, Rein'),
('15103','Reservas Sobre Acciones'),
('15199','AxI Inversiones Consolidadas'),
('15201','Acciones y Cuotas'),
('15202','Primas, Sobre Precio, Menor Precio, Rein'),
('15203','Reservas Sobre Acciones'),
('17101','Activos Intangibles'),
('18101','Cargos Diferidos'),
('18102','Impuesto Diferido - Activo'),
('19101','Otros Activos'),
('21101','Efectos por Pagar'),
('21201','Bancos'),
('21202','Giros Descontados'),
('21203','Cuentas Facilitadoras'),
('21204','Dividendos Decretados'),
('21205','Acreedores Varios'),
('21206','Acreedores por Despachos y Buques'),
('21207','Proveedores de Mercanc?a para la Venta'),
('21208','Ctas. Ctes. Comerciales'),
('21209','Gastos Causados por Pagar'),
('21301','Impuesto Sobre la Renta'),
('21302','Acreedores Fiscales'),
('21303','Acreedores Fiscales - Operaciones de Adu'),
('21304','Impuesto al Valor Agregado - IVA'),
('21305','Impuesto al Valor Agregado - IVA Retenid'),
('23201','Garantia Prestaciones Sociales'),
('23202','Anticipos Garantia PS'),
('24101','Pr?stamos a Largo Plazo'),
('27101','Cr?ditos Diferidos'),
('27102','Impuesto Diferido - Pasivo'),
('28101','Otros Pasivos'),
('29101','Reservas Monetarias'),
('29102','Reservas No Monetarias'),
('29501','Interes Minoritario'),
('31101','Capital Social'),
('31102','Fondo Legal de Reserva y Garant?a'),
('31103','Primas p/Emisi?n y Suscripci?n de Accion'),
('31104','Super?vit ? (D?ficit)'),
('31105','Reserva Voluntaria de Accionistas'),
('31108','Ganancias y P?rdidas en Proceso Distrib'),
('31109','Ganancias y P?rdidas'),
('41101','Ventas al Contado (Mayor o Detal)'),
('41102','Ventas a Cr?ditos'),
('41103','Ventas de Unidades Usadas Recibidas'),
('41121','Devoluciones y Rebajas'),
('41122','Descuentos Sobre Ventas'),
('41131','Ventas Carteras de Giros'),
('41132','Ventas de Acciones'),
('51101','Inventario Inicial al Costo'),
('51102','Inventario Inicial al Precio de Venta'),
('51103','Margen por Ganar Inicial'),
('51104','Compras al Costo'),
('51105','Compras al Precio de Ventas'),
('51106','Margen Sobre Compras (Haber)'),
('51107','Aumento en Etiquetas (Debe)'),
('51108','Rebajas en Etiquetas  (Haber)'),
('51109','Margen Aumentado en Etiquetas (Haber)'),
('51110','Margen Rebajado en Etiquetas (Debe)'),
('51112','Productos Elaborados'),
('51113','Costo de Proyectos'),
('51114','Costos Varios y Ajustes en Compras'),
('51115','Devoluciones y Descuentos en Compras'),
('51116','P?rdida por Aver?as'),
('51117','Gastos de Compras'),
('51119','Acondicionamiento de Unidades'),
('51131','Costo Cartera de Giros'),
('51132','Costo de Valores Vendidos'),
('51133','Costo de Repuestos y Veh?culos'),
('51191','Inventario Final al Costo'),
('51192','Inventario Final al Precio de Venta'),
('51193','Margen por Ganar Final'),
('51194','Cambio de Inventario'),
('51201','Inventario Inicial de Productos en Proce'),
('51202','Materia Primas Aplicadas'),
('51203','Mano de Obra Directa'),
('51204','Sueldos y Salarios Indirectos'),
('51205','Otros Gastos de Producci?n'),
('51209','Productos Terminados'),
('51210','Inventario Final de Productos en Proceso'),
('51211','Cambio de Inventario en Proceso'),
('51221','Inventario Inicial de Materia Prima'),
('51222','Compras de Materia Prima'),
('51223','Materia Prima Apliacada - Haber'),
('51224','Inventario Final de Materia Prima'),
('61101','Ingresos por Operaciones'),
('61102','Comisi?n Ganada Sobre Operaciones'),
('61103','Comisi?n Ganada Sobre Ventas'),
('61104','Comisi?n Ganada por Seguros'),
('61105','Comisi?n Ganada - Varios'),
('61106','Alquileres de Bienes Muebles'),
('61107','Almacenaje Ganado'),
('61109','Acarreos y Fletes Ganados'),
('61111','Ingresos por Estacionamiento'),
('61112','Cuenta Cambio'),
('61113','Descuentos Ganados'),
('61114','Arrendamientos Ganados'),
('61115','Intereses Ganados'),
('61116','Dividendos y Partic. - No Consolidadas'),
('61117','Beneficio por Venta de Activo Fijo'),
('61118','Deudores Incobrables Recuperados'),
('61119','Ingresos Varios'),
('61120','Ingresos por Servicios'),
('61121','Ingreso Cuentas en Participaci?n'),
('61201','Liberaciones de Reservas'),
('71101','N?mina'),
('71102','Apartado para Utilidades Legales'),
('71103','Garantia Prestaciones Sociales'),
('71104','Contribuci?n INCE'),
('71105','Seguro Social Obligatorio'),
('71106','Ahorro Habitacional'),
('71108','Gastos por Personal Distribuidos'),
('71109','Otros Gastos por Personal'),
('71110','Otros Gtos p/Personal - Distribuidos'),
('71201','Intereses Gastados'),
('71202','Perdida por Venta de Bonos'),
('71203','Comisi?n por Compra de Bonos'),
('71301','Deudores Incobrables'),
('71302','Liberalidades (Contribuciones Ben?ficas)'),
('71303','Publicidad y Propaganda'),
('71304','Contribuciones Gubernamentales'),
('71305','Apartado para Depreciaci?n/Amortizaci?n'),
('71306','P?rdida por Venta o Retiro de Activo'),
('71307','Gastos de Traslado de Nuevos Empleados'),
('71308','Gtos Administraci?n Inmuebles Arrendados'),
('71309','Gtos Conservaci?n Inmuebles Arrendados'),
('71310','Alquileres Gastados'),
('71311','Reparaciones Bienes Muebles e Inmuebles'),
('71314','Primas de Seguro Sobre Existencias'),
('71318','Consultas, Asesor?as y Gastos Legales'),
('71319','Gastos de Ventas'),
('71320','Estudios Comerciales y Promociones'),
('71321','Honorarios'),
('71322','Comisiones Varias'),
('71323','Gastos de Decoraci?n'),
('71324','Contribuciones C?maras y Otros'),
('71325','Avisos en Prensa e Internet'),
('71326','Atenciones a Relacionados'),
('71327','Atenciones y Obsequios al Personal'),
('71328','Aguinaldos y D?divas'),
('71329','Portes y Encomiendas'),
('71330','Tel?fonos y Gastos de Conexiones'),
('71331','Gastos de Transporte'),
('71332','Fotocopias'),
('71333','Art?culos y Material de Oficina'),
('71334','Peri?dicos, Revistas, Libros'),
('71335','Corriente y Combustible'),
('71336','Material para Montaje'),
('71337','Material y Servicios Internos'),
('71338','Gastos de Vigilancia'),
('71339','Material de Empaque'),
('71340','Suministros y Accesorios'),
('71341','Gastos Equipo de Computaci?n'),
('71342','Arrendamiento Veh?culos'),
('71343','Gastos de Viajes'),
('71344','Gastos de Veh?culos'),
('71345','Accarreos y Fletes'),
('71347','Arrendamiento Equipos y M?quinas'),
('71348','Gastos de Carga y Descarga'),
('71349','Transporte de Valores'),
('71350','Gastos Bancarios'),
('71351','Gastos Divulgaci?n Principios de la Comp'),
('71352','Gastos Ocasionales para Trabajadores'),
('71353','Gastos de Aprendizaje'),
('71354','Primas y Gastos Sobre Fianzas'),
('71355','Diferencias en Saldos y Caja'),
('71356','Cargos de Otras Empresas'),
('71357','Ley Org?nica Ciencia, Tecnolog?a e Innov'),
('71358','Ley Org?nica de Drogas'),
('71359','Salud y Seguridad Laboral'),
('71360','Aporte Ley Org?nica de Deporte'),
('71390','Cargos Fijos Internos - Distribuci?n'),
('71398','Mano de Obra Aplicada a Proceso (haber)'),
('71399','Gastos Aplicados a Proceso (haber)'),
('71401','Apartados y Reservas'),
('81101','Cobranza por Cuenta de Terceros'),
('81102','Mercanc?as Dadas en Consignaci?n'),
('81103','Equipos Dados en Pr?stamo'),
('81104','Litigios Pendientes'),
('81105','Reclamos al Seguro'),
('81106','Fletes Mar?timos al Cobro'),
('81107','Intereses por Recibir'),
('81108','Cuentas Incobrables'),
('81109','Plan Capitalizaci?n General Motors'),
('81299','Contra-Cuentas de 91201 al 91299'),
('81399','Contracuentas'),
('81401','Impuesto a los Activos Empresariales(Deb'),
('81402','Plan Capitalizaci?n General Motors'),
('81403','Solicitud de Divisas Cadivi'),
('81404','Marcas y Denominaciones Comerciales'),
('81501','Fianzas Anuales (Debe)'),
('81502','Fianzas Anuales - Parte Utilizada (Haber'),
('81503','Fianzas Ocasionales (Haber)'),
('81504','Obligaciones de Clientes (Debe)'),
('81505','Obligaciones Propias (Debe)'),
('91199','Contra-Cuenta de 81101 AL 81199'),
('91201','Fianzas Dadas en Respaldo'),
('91202','Contrafianzas Dadas en Respaldo - Despa'),
('91203','Contrafianzas Dadas en Respaldo - Otras'),
('91301','Fianzas Dadas a  Personas, No Consolidad'),
('91302','Fianzas Dadas en Respaldo Nuestro'),
('91303','Fianzas por Contratos de Arrendamientos'),
('91304','Impuestos en Discusi?n'),
('91305','Mercanc?as Recibidas en Consignaci?n'),
('91306','Opciones Concedidas'),
('91307','Cartas de Cr?dito Solicitadas'),
('91308','Custodia y Mandato'),
('91309','Mobiliario y Equipos Recib.Consignaci?n'),
('91499','Contra-Cuentas de 814021 al 811499'),
('91501','Contra-Cuenta')

