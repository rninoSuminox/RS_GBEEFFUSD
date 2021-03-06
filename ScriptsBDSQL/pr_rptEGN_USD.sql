/*
exec pr_rptEGN_USD @ANIO=2020,@MONEDA=N'USD',@EMPRESA=N'REFERVZLA'
exec pr_rptEGN_USD @ANIO=2020,@MONEDA=N'BSF',@EMPRESA=N'REFERVZLA'

exec pr_rptEGN_USD @ANIO=2020,@MONEDA=N'USD',@EMPRESA=N'sxper'

--se ejecuta en la BD principal, debe tener todas las cuentas contables.
*/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_rptEGN_USD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].pr_rptEGN_USD
 go
CREATE  PROCEDURE pr_rptEGN_USD 
(@ANIO		INT
,@MONEDA	VARCHAR(6)='USD' --1:GUARDA EN TABLAS,2: TABLAS TEMP PARA REPORTE
,@EMPRESA   VARCHAR(100)
,@MESPERIODO	INT=12)
AS
BEGIN

	DECLARE @TASA	   CHAR(15)=(SELECT TOP 1 TAXSCHID FROM BEF00200); --TASA DE CONVERSION 'USD REPORTE'    


--EJECUTA SP, PARA LLENAR TABLA CON SALDOS y aplicar filtros
	exec pr_rptCuentasEmpresa_USD @ANIO=@ANIO,@MES=@MESPERIODO,@EMPRESA=@EMPRESA,@IDREPORTE='RPTEGN';
	--select * from TEMPSALDOS;

	 --AGRUPA LAS CUENTAS POR MES
	 WITH CTE_SALDOS AS (
	 SELECT ANIO,MONTH(TRXDATE) MES,YEAR(TRXDATE) ANIOTRX,ACTNUMST
			,SUM(SALDOBSF) SALDOBSF
			,IIF(@MONEDA='USD',SUM(IIF(SALDOUSD=0,SALDOBSF/dbo.f_buscatasadia(TRXDATE,@TASA),SALDOUSD)),0) SALDOUSD --segun tasa del dia
		   --   ,SUM(DEBITAMT) DEBITAMT
			  --,SUM(CRDTAMNT) CRDTAMNT
			  --,SUM((DEBITAMT)/dbo.f_buscatasadia(TRXDATE,@TASA)) DEBITUSD --convierte a USD
		   --   ,SUM((CRDTAMNT)/dbo.f_buscatasadia(TRXDATE,@TASA)) CRDITUSD --segun tasa del dia
			  ,MAX(ACTDESCR) ACTDESCR
	   FROM TEMPSALDOS
	  GROUP BY ANIO,MONTH(TRXDATE),YEAR(TRXDATE),ACTNUMST),
	  CTE_CONFIG AS (
		SELECT 'GASTOS DEL NEGOCIO' GRUPO,'713' SEGMENTO
	  ),
	  CTE_SUBGRUPO AS (
		SELECT SGMNTID,RTRIM(DSCRIPTN) DSCRIPTN FROM BEF00100 WHERE LEFT(SGMNTID,3)='713'
	  )
	  --SELECT * FROM CTE_SALDOS 
	   SELECT LEFT(ACTNUMST,3) SEGMENTO,ACTNUMST
	         ,ISNULL(DSCRIPTN,ACTDESCR) ACTDESCR
			 ,ANIO,MES
			 ,IIF(@MONEDA='USD',SALDOUSD,SALDOBSF)* -1 SALDO
			 ,GRUPO
			 ,LEFT(ACTNUMST,6) SUBGRUPO
			 ,ANIOTRX
	   FROM CTE_SALDOS S
	  INNER JOIN CTE_CONFIG Z ON Z.SEGMENTO=LEFT(ACTNUMST,3)
	   LEFT JOIN CTE_SUBGRUPO Y ON Y.SGMNTID=LEFT(REPLACE(ACTNUMST,'-',''),5)  

END