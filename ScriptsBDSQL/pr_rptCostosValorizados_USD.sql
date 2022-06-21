/*
exec pr_rptCostosValorizados_USD @PERIODO='202003',@EMPRESA=N'H2501'


--se ejecuta en la BD principal, debe tener todas las cuentas contables.
*/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_rptCostosValorizados_USD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].pr_rptCostosValorizados_USD
 go
CREATE  PROCEDURE pr_rptCostosValorizados_USD 
(@PERIODO	CHAR(8)
,@EMPRESA   VARCHAR(100)
,@ITEMNMBR	CHAR(15)='')
AS
BEGIN

	DECLARE @SQLSTR    NVARCHAR(MAX)='',@Parametro nvarchar(500)

		--select @XEMP	
			SET @SQLSTR=@SQLSTR+'SELECT E.PERIODO,E.FECHAINI,E.FECHAFIN,E.ITEMNMBR,I.ITEMDESC,E.VALORIZACION
			                           ,E.VALORIZACIONUSD,E.COSTOFINAL,E.COSTOFINALUSD,E.STOCK,USER2ENT,E.NUMOFTRX
								       ,D.DOCDATE,D.DOCNUMBR,D.QUANTITY,D.TRXAMNT MONTO,D.ORTRXAMT MONTOUSD,D.COSTOFINAL COSTO,D.COSTOFINALUSD COSTOUSD
									   ,D.STOCK STOCKLINEA,D.VALORIZACION VALORLINEA,D.VALORIZACIONUSD VALORLINEAUSD,D.TASADIA,D.ROWNMBR
									   ,D.COST COSTTRX,D.COSTUSD COTSUSDTRX
										   ,CASE 
											WHEN DOCTYPE in (0)			THEN ''Inventario Inicial'' 
											WHEN DOCTYPE in (4,11,12)	THEN ''Compras al costo'' 
											WHEN DOCTYPE in (1,101,8)	THEN ''Costos Varios y Ajustes en Compras''
											ELSE '''' END TIPO
										   ,CASE 
											WHEN DOCTYPE in (0)			THEN 1
											WHEN DOCTYPE in (4,11,12)	THEN 2
											WHEN DOCTYPE in (1,101,8)	THEN 3
											ELSE '''' END ORDEN
								 FROM ' + @EMPRESA +'.dbo.BEF01000 E
								 inner join ' + @EMPRESA +'.dbo.IV00101 I ON I.ITEMNMBR=E.ITEMNMBR
								  left join ' + @EMPRESA +'.dbo.BEF01010 D on E.PERIODO=D.PERIODO 
													and E.ITEMNMBR=D.ITEMNMBR
								WHERE E.PERIODO=@PERIODO AND (E.ITEMNMBR=@ITEMNMBR or @ITEMNMBR='''');'			


	SET @Parametro = N'@PERIODO CHAR(8),@ITEMNMBR CHAR(15)';  
 PRINT @SQLSTR 
EXECUTE sp_executesql @SQLSTR, @Parametro,@PERIODO = @PERIODO,@ITEMNMBR=@ITEMNMBR; 

--SELECT E.PERIODO,E.FECHAINI,E.FECHAFIN,E.ITEMNMBR,I.ITEMDESC,E.VALORIZACION
--			                           ,E.VALORIZACIONUSD,E.COSTOFINAL,E.COSTOFINALUSD,E.STOCK,USER2ENT,E.NUMOFTRX
--								       ,D.DOCDATE,D.DOCNUMBR,D.QUANTITY,D.TRXAMNT MONTO,D.ORTRXAMT MONTOUSD,D.COSTOFINAL COSTO,D.COSTOFINALUSD COSTOUSD
--									   ,D.STOCK STOCKLINEA,D.VALORIZACION VALORLINEA,D.VALORIZACIONUSD VALORLINEAUSD,D.TASADIA,D.ROWNMBR
--									   ,D.COST COSTTRX,D.COSTUSD COTSUSDTRX
--										   ,CASE 
--											WHEN DOCTYPE in (0)			THEN 'Inventario Inicial' 
--											WHEN DOCTYPE in (4,11,12)	THEN 'Compras al costo' 
--											WHEN DOCTYPE in (1,101,8)	THEN 'Costos Varios y Ajustes en Compras'
--											ELSE '' END TIPO
--										   ,CASE 
--											WHEN DOCTYPE in (0)			THEN 1
--											WHEN DOCTYPE in (4,11,12)	THEN 2
--											WHEN DOCTYPE in (1,101,8)	THEN 3
--											ELSE '' END ORDEN
--								 FROM dbo.BEF01000 E
--								 inner join dbo.IV00101 I ON I.ITEMNMBR=E.ITEMNMBR
--								  left join dbo.BEF01010 D on E.PERIODO=D.PERIODO 
--													and E.ITEMNMBR=D.ITEMNMBR
--								WHERE E.PERIODO=@PERIODO AND (E.ITEMNMBR=@ITEMNMBR or @ITEMNMBR='');


END