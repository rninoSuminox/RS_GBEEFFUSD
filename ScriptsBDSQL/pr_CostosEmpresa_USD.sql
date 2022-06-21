/*
exec pr_rptCostosEmpresa_USD @ANIO=2021,@EMPRESA=N'BALBS',@IDREPORTE='RPTDR',@MES=12
SELECT * FROM TEMPCOSTOS ORDER BY 1,2,ORDEN
*/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_rptCostosEmpresa_USD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].pr_rptCostosEmpresa_USD
 go
CREATE  PROCEDURE pr_rptCostosEmpresa_USD 
(@ANIO		INT
,@EMPRESA   VARCHAR(100)
,@IDREPORTE VARCHAR(15)=''
,@MES	INT=12)
AS
BEGIN

	DECLARE @SQLSTR    NVARCHAR(MAX)='',@Parametro nvarchar(500)
	DECLARE @XEMP VARCHAR(15)
	DECLARE @FILTRO NVARCHAR(MAX)=' AND 1=1'

	DECLARE @ANIOANT INT=@ANIO-1
	DECLARE @PERIODO CHAR(7)
	SET @PERIODO=CONCAT(CONVERT(VARCHAR(4),@ANIO),RIGHT(CONCAT('00',CONVERT(VARCHAR(2),@MES)),2))
	--tabla para llenar datos principales
	if exists(select 1 from sys.tables where name='TEMPCOSTOS')
		drop table TEMPCOSTOS;
		CREATE TABLE TEMPCOSTOS (ANIO		INT
								,MES		INT
								,TIPO	CHAR(40)
								,VALOR	NUMERIC(19,5)
								,VALORUSD	NUMERIC(19,5)
								,ORDEN      INT)
		CREATE INDEX idx_FECHA ON TEMPCOSTOS (ANIO,MES)

	--cargar filtros tabla configuracion debo crear esta tabla 
	--FALTA MEJORAR ESTA SECCION
	IF (@IDREPORTE='RPTDR')   SET @FILTRO=' AND DOCTYPE in (0,1,4,11,12,101,8)'
	IF (@IDREPORTE='RPTGPR')  SET @FILTRO=' AND DOCTYPE in (0,1,4,11,12,101,8)'	
	IF (@IDREPORTE='RPTBGRAL')  SET @FILTRO=' AND DOCTYPE in (0,1,4,11,12,101,8)'
	print  @FILTRO
	--cursor para poder consolidar las empresas
	DECLARE EMPRESAS CURSOR FOR   
	SELECT Value FROM dbo.Split(@EMPRESA,',')  WHERE VALUE<>''

    --BUSCAR E INSERTAR DE CADA EMPRESA
	OPEN EMPRESAS  
	FETCH NEXT FROM EMPRESAS INTO @XEMP   
	WHILE @@FETCH_STATUS = 0  
		BEGIN  
		--select @XEMP	
			SET @SQLSTR=@SQLSTR+'INSERT INTO TEMPCOSTOS (ANIO,MES,TIPO,ORDEN,VALOR,VALORUSD)
									 SELECT YEAR(FECHAFIN) ANIO,MONTH(FECHAFIN) MES,''Inventario para la Venta'' TIPO,4 ORDEN
										   ,SUM(VALORIZACION   )  VALOR
										   ,SUM(VALORIZACIONUSD)  VALORUSD
									   FROM ' + @XEMP +'.dbo.BEF01000 
									  WHERE YEAR(FECHAFIN) IN (@ANIO,@ANIOX) AND PERIODO<=@PERIODO
									  GROUP BY YEAR(FECHAFIN),MONTH(FECHAFIN)
									UNION ALL
									SELECT ANIO,MES,TIPO,ORDEN,SUM(VALOR) VALOR,SUM(VALORUSD) VALORUSD 
									 FROM (
									 SELECT left(periodo,4)  ANIO,right(RTRIM(periodo),2)  MES
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
											,SUM(TRXAMNT)	   VALOR
											,SUM(ORTRXAMT)     VALORUSD
									  FROM ' + @XEMP +'.dbo.BEF01010 
									 WHERE convert(integer, left(periodo,4)) IN (@ANIO,@ANIOX) AND PERIODO<=@PERIODO'
									    + @FILTRO +	
									 'GROUP BY left(periodo,4),right(RTRIM(periodo),2),DOCTYPE
									 ) DATOS GROUP BY ANIO,MES,TIPO,ORDEN;'			
			FETCH NEXT FROM EMPRESAS INTO @XEMP  
		END   
	CLOSE EMPRESAS;  
	DEALLOCATE EMPRESAS;

	SET @Parametro = N'@ANIO int,@ANIOX INT, @PERIODO CHAR(7)';  
 PRINT @SQLSTR 
EXECUTE sp_executesql @SQLSTR, @Parametro,  
                      @ANIO = @ANIO,@ANIOX=@ANIOANT,@PERIODO=@PERIODO; 

END