/*
exec pr_rptDR_USDT2 @ANIO=2021,@MONEDA=N'USD',@EMPRESA=N'BALBS'
exec pr_rptDR_USD @ANIO=2020,@MONEDA=N'BSF',@EMPRESA=N'REFERVZLA'

exec pr_rptDR_USD @ANIO=2021,@MONEDA=N'USD',@EMPRESA=N'refer'

--se ejecuta en la BD principal, debe tener todas las cuentas contables.
*/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_rptDR_USDT2_Resumen]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].pr_rptDR_USDT2_Resumen
 go
CREATE  PROCEDURE pr_rptDR_USDT2_Resumen 
(@ANIO		INT
,@MONEDA	VARCHAR(6)='USD' --1:GUARDA EN TABLAS,2: TABLAS TEMP PARA REPORTE
,@EMPRESA   VARCHAR(100)
,@MESPERIODO INT=12
,@FLGCTACAMBIO INT=1)
AS
BEGIN

	DECLARE @TASA	   CHAR(15)=(SELECT TOP 1 TAXSCHID FROM BEF00200); --TASA DE CONVERSION 'USD REPORTE' 
		DECLARE @TASA2	   CHAR(15)='USD VENTAS'; --TASA DE CONVERSION BCV ''USD VENTAS''    
	DECLARE @PER1 CHAR(6)

--EJECUTA SP PARA ARMAR PERIODOS
	exec pr_periodosEEFF_USD @ANIO=@ANIO,@EMPRESA=@EMPRESA	
--EJECUTA SP, PARA LLENAR TABLA CON SALDOS y aplicar filtros
	exec pr_rptCuentasEmpresa_USD @ANIO=@ANIO,@MES=@MESPERIODO,@EMPRESA=@EMPRESA,@IDREPORTE='RPTDR';
--EJECUTA SP, PARA LLENAR TABLA CON costos y aplicar filtros
	exec pr_rptCostosEmpresa_USD  @ANIO=@ANIO,@MES=@MESPERIODO,@EMPRESA=@EMPRESA,@IDREPORTE='RPTDR';
	--select * from TEMPSALDOS;

	 --AGRUPA LAS CUENTAS POR MES
	 --WITH CTE_SALDOS AS ( --SALDO CTAS
		--			 SELECT ANIO,MONTH(TRXDATE) MES,YEAR(TRXDATE) ANIOTRX,ACTNUMST
		--		   ,IIF(@MONEDA='USD',SUM(IIF(SALDOUSD=0,SALDOBSF/dbo.f_buscatasadia(TRXDATE,@TASA),SALDOUSD))
		--							 ,SUM(SALDOBSF)) * -1 SALDO --segun tasa del dia
		--					  --,IIF(@MONEDA='USD'					  
		--					  --,(SUM(DEBITAMT/dbo.f_buscatasadia(TRXDATE,IIF(CURNCYID='USD VENTAS',@TASA2,@TASA)))
		--					  -- -SUM(CRDTAMNT/dbo.f_buscatasadia(TRXDATE,IIF(CURNCYID='USD VENTAS',@TASA2,@TASA))))
		--					  --,SUM(DEBITAMT-CRDTAMNT))* -1 SALDO --segun tasa del dia
		--					  ,MAX(ACTDESCR) ACTDESCR
		--			   FROM TEMPSALDOS
		--			  WHERE 
		--			  --ACTNUMST NOT IN ('611-12-1900') AND --EXCLUYE CUENTA DETALLE
		--			    (LEFT(ACTNUMST,3)<>'511' OR LEFT(ACTNUMST,6) IN ('511-31','511-32')) -- EXCLUYE SEGMENTO 5

		--			  GROUP BY ANIO,YEAR(TRXDATE),MONTH(TRXDATE),ACTNUMST ),
	 WITH CTE_AGRUPO AS (	--para las cuentas que se acumulan anual
			 SELECT ANIO,MES,MAX(YEAR(TRXDATE)) ANIOTRX
				   ,MAX(ACTDESCR) ACTDESCR
				   ,RTRIM(ACTNUMST) ACTNUMST
				   ,MAX(TRXDATE) TRXDATE
				   ,(SUM(SUM(SALDOBSF)) OVER (PARTITION BY ANIO,ACTNUMST ORDER BY ANIO,MES)) ACUMBSF
			   FROM TEMPSALDOS
			  WHERE (LEFT(REPLACE(ACTNUMST,'-',''),5)='71103' OR  LEFT(REPLACE(ACTNUMST,'-',''),3)='714' OR LEFT(REPLACE(ACTNUMST,'-',''),3)='612') 
			  and REPLACE(ACTNUMST,'-','') NOT IN ('714013001','714013004','714011047')
			  GROUP BY ANIO,MES,ACTNUMST),
	  CTE_ACUMULADO AS(
		SELECT *
		,ACUMBSF/dbo.f_buscatasadia(EOMONTH(TRXDATE),@TASA) -
		        ISNULL((LAG(ACUMBSF/dbo.f_buscatasadia(EOMONTH(TRXDATE),@TASA))
				       OVER (PARTITION BY ANIO,ACTNUMST ORDER BY ANIO,MES)),0)	 SALDOUSD
		,ACUMBSF -
		        ISNULL((LAG(ACUMBSF)
				       OVER (PARTITION BY ANIO,ACTNUMST ORDER BY ANIO,MES)),0)	SALDOBSF
		 FROM CTE_AGRUPO
	  ),	  
	  CTE_INICIAL AS ( --SALDO CTAS por mes
					 SELECT ANIO,MONTH(TRXDATE) MES,YEAR(TRXDATE) ANIOTRX,ACTNUMST
				   ,IIF(@MONEDA='USD',SUM(IIF(SALDOUSD=0,SALDOBSF/dbo.f_buscatasadia(TRXDATE,@TASA),SALDOUSD))
									 ,SUM(SALDOBSF)) * -1 SALDO --segun tasa del dia
							  ,MAX(ACTDESCR) ACTDESCR
					   FROM TEMPSALDOS
					  WHERE (LEFT(ACTNUMST,3)<>'511' OR LEFT(ACTNUMST,6) IN ('511-31','511-32')) -- EXCLUYE SEGMENTO 5
					    and NOT(LEFT(REPLACE(ACTNUMST,'-',''),5)='71103' OR  LEFT(REPLACE(ACTNUMST,'-',''),3)='714' OR LEFT(REPLACE(ACTNUMST,'-',''),3)='612')
					  GROUP BY ANIO,YEAR(TRXDATE),MONTH(TRXDATE),ACTNUMST ),
		CTE_SALDOS AS  ( --union de cuentas por mes y acumuladas anual
					  SELECT ANIO,MES,ANIOTRX,ACTNUMST,ACTDESCR
					  --,SALDO
					  --CAMBIO SOLICITADO POR ROBERTO DA SILVA 14-01-2022
					  ,IIF(@FLGCTACAMBIO=0 AND LEFT(ACTNUMST,6)='611-12',0,SALDO) SALDO
					   FROM CTE_INICIAL 
					  UNION ALL 
					  SELECT ANIO,MES,ANIOTRX,ACTNUMST,ACTDESCR
					  ,IIF(@MONEDA='USD',SALDOUSD,SALDOBSF) * -1 SALDO --segun tasa del dia
					   FROM CTE_ACUMULADO ),
		   CTE_COSTOS AS ( --COSTOS
					 SELECT ANIO,ANIO ANIOTRX,MES,TIPO ACTDESCR,ORDEN ACTNUMST,VALOR
							  ,IIF(@MONEDA='USD'					  
								  ,IIF(ORDEN IN (1,2,3),(VALORUSD *-1),VALORUSD)
								  ,IIF(ORDEN IN (1,2,3),(VALOR *-1),VALOR)) SALDO --segun tasa del dia
					   FROM TEMPCOSTOS),
		  CTE_SEGMENTO AS ( --PARA USAR COMO GRUPO
					 SELECT DSCRIPTN GRUPO,SGMNTID SEGMENTO FROM GL40200 WHERE SGMTNUMB=1
		  ),
		  CTE_SUBGRUPO AS ( --DESCRIPCION CTA 5.
					 SELECT SGMNTID,RTRIM(DSCRIPTN) DSCRIPTN FROM BEF00100
					  WHERE LEFT(SGMNTID,3)IN ('411','511','611','612','711','712','713','714')
		  ),
		  CTE_CTADETALLE AS ( --PARA SUBAGRUPAR POR CTAS DE DETALLE
			  SELECT '611-12-1900' DETALLE UNION ALL
			  SELECT '714-01-1047' DETALLE UNION ALL
			  SELECT '714-01-3004' DETALLE UNION ALL
			  SELECT '714-01-3006' DETALLE ),

		 CTE_DATOS as( --SACA MESES ANTES DE AGRUPAR
		 --el nivel de agropamiento es, NIVELGRUPO, GRUPO Y SUBGRUPO 
				SELECT   LEFT(ACTNUMST,CHARINDEX('-',ACTNUMST)-1) SEGMENTO
						,ACTNUMST
						,IIF(DETALLE IS NULL,ISNULL(DSCRIPTN,ACTDESCR),ACTDESCR) ACTDESCR 
						--SI ES CUENTA DETALLE TRAE DESCRIPCION, SINO ES CTA DET, EVALUA SI EXISTE EL SEGMENTO
						,ANIO,MES
						,SALDO 
						,CASE WHEN LEFT(ACTNUMST,6)<='411-09' THEN ' VENTAS'
							  WHEN LEFT(ACTNUMST,6)<='411-99' THEN 'VENTAS BRUTAS'
							  ELSE UPPER(GRUPO) END GRUPO --PARA SUBAGRUPAR LAS VENTAS
						,CASE 
							WHEN DETALLE IS NOT NULL THEN DETALLE
							WHEN LEFT(ACTNUMST,3) IN ('612','711','712','713','714') THEN LEFT(ACTNUMST,3)
							ELSE LEFT(ACTNUMST,6) END  SUBGRUPO --AGRUPA 3 NIVEL
						,CASE 
							 WHEN LEFT(ACTNUMST,3) IN ('411')		THEN '1-VENTAS' 
							 WHEN LEFT(ACTNUMST,3) IN ('511')		THEN '2-COSTOS VENTAS' 
							 WHEN LEFT(ACTNUMST,3) IN ('711','713') THEN '4-GASTOS OPERATIVOS' 
						 
							 WHEN REPLACE(S.ACTNUMST,'-','') IN ('714011047','714013004','714013006') THEN '7-IMPUESTOS'

							 WHEN LEFT(ACTNUMST,3) IN ('612','714')			  THEN '6-DIFERENCIA EN CAMBIO NR Y RESERVAS' 
							 WHEN REPLACE(S.ACTNUMST,'-','') IN ('611121900') THEN '6-DIFERENCIA EN CAMBIO NR Y RESERVAS'		 						

							 WHEN LEFT(ACTNUMST,3) IN ('712')			  THEN '5-GASTOS DE FINANCIAMIENTO'
							 WHEN LEFT(ACTNUMST,6) IN ('611-12')		  THEN '5-GASTOS DE FINANCIAMIENTO' 

							 WHEN LEFT(ACTNUMST,3) IN ('611')			  THEN '3-INGRESOS MERCANTILES' 		  
						 ELSE 'ZZZ' END NIVELGRUPO
			  				,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=1 ),(SALDO),0)  ENE
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=2 ),(SALDO),0)  FEB
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=3 ),(SALDO),0)  MAR
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=4 ),(SALDO),0)  ABR
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=5 ),(SALDO),0)  MAY
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=6 ),(SALDO),0)  JUN
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=7 ),(SALDO),0)  JUL
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=8 ),(SALDO),0)  AGO
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=9 ),(SALDO),0)  SEP
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=10),(SALDO),0)  OCT
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=11),(SALDO),0)  NOV
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=12),(SALDO),0)  DIC
							,ANIOTRX
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=1 )	PER01
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=2 )	PER02
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=3 )	PER03
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=4 )	PER04
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=5 )	PER05
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=6 )	PER06
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=7 )	PER07
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=8 )	PER08
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=9 )	PER09
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=10)	PER10
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=11)	PER11
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=12)	PER12
				FROM CTE_SALDOS S
				LEFT JOIN CTE_SEGMENTO Z ON Z.SEGMENTO=LEFT(ACTNUMST,3) 
				LEFT JOIN CTE_CTADETALLE T ON S.ACTNUMST=T.DETALLE
				LEFT JOIN CTE_SUBGRUPO Y ON Y.SGMNTID=LEFT(REPLACE(ACTNUMST,'-',''),5) --SI NO CONSIGUE EL SEGMENTO TRAE LA DESCRIPCION DE CUENTA.
				UNION ALL 
				SELECT '511' SEGMENTO,ACTNUMST,ACTDESCR,ANIO,MES
					   ,SALDO
					   ,'' GRUPO,CONVERT(NVARCHAR(1),ACTNUMST) SUBGRUPO,'2-COSTOS VENTAS' NIVELGRUPO
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=1 ),(SALDO),0)  ENE
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=2 ),(SALDO),0)  FEB
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=3 ),(SALDO),0)  MAR
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=4 ),(SALDO),0)  ABR
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=5 ),(SALDO),0)  MAY
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=6 ),(SALDO),0)  JUN
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=7 ),(SALDO),0)  JUL
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=8 ),(SALDO),0)  AGO
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=9 ),(SALDO),0)  SEP
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=10),(SALDO),0)  OCT
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=11),(SALDO),0)  NOV
							,IIF(MES=(SELECT RIGHT(PERIODO,2) FROM TEMPPERIODO WHERE ID=12),(SALDO),0)  DIC
							,ANIOTRX
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=1 )	PER01
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=2 )	PER02
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=3 )	PER03
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=4 )	PER04
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=5 )	PER05
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=6 )	PER06
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=7 )	PER07
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=8 )	PER08
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=9 )	PER09
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=10)	PER10
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=11)	PER11
							,(SELECT MONTH(PERIODDT) FROM TEMPPERIODO WHERE ID=12)	PER12
				  FROM CTE_COSTOS
	   )

	   SELECT NIVELGRUPO,GRUPO,SUBGRUPO,SEGMENTO,ANIO
	    ,MAX(ACTDESCR) ACTDESCR
	    ,SUM(SALDO) SALDO
		,SUM(ENE)   ENE
		,SUM(FEB)   FEB
		,SUM(MAR)   MAR
		,SUM(ABR)   ABR
		,SUM(MAY)   MAY
		,SUM(JUN)   JUN
		,SUM(JUL)   JUL
		,SUM(AGO)   AGO
		,SUM(SEP)   SEP
		,SUM(OCT)   OCT
		,SUM(NOV)   NOV
		,SUM(DIC)   DIC
		,MAX(ANIOTRX) ANIOTRX
		,MAX(PER01	) PER01
		,MAX(PER02	) PER02
		,MAX(PER03	) PER03
		,MAX(PER04	) PER04
		,MAX(PER05	) PER05
		,MAX(PER06	) PER06
		,MAX(PER07	) PER07
		,MAX(PER08	) PER08
		,MAX(PER09	) PER09
		,MAX(PER10	) PER10
		,MAX(PER11	) PER11
		,MAX(PER12	) PER12
	    from CTE_DATOS
		GROUP BY GRUPO,NIVELGRUPO,SEGMENTO,SUBGRUPO,ANIO
		UNION ALL
		SELECT V.NIVELGRUPO,V.GRUPO,V.SUBGRUPO,V.SEGMENTO,@ANIO ANIO
	    ,V.ACTDESCR
	    ,0 SALDO
		,0 ENE
		,0 FEB
		,0 MAR
		,0 ABR
		,0 MAY
		,0 JUN
		,0 JUL
		,0 AGO
		,0 SEP
		,0 OCT
		,0 NOV
		,0 DIC
		,@ANIO  ANIOTRX
		,''  PER01
		,''  PER02
		,''  PER03
		,''  PER04
		,''  PER05
		,''  PER06
		,''  PER07
		,''  PER08
		,''  PER09
		,''  PER10
		,''  PER11
		,''  PER12
	FROM vw_rptDR_USD V
	left join CTE_DATOS C ON C.NIVELGRUPO=V.NIVELGRUPO AND C.GRUPO=V.GRUPO
	      AND C.SUBGRUPO=V.SUBGRUPO AND C.SEGMENTO=V.SEGMENTO
	WHERE V.NIVELGRUPO IS NULL
		order by NIVELGRUPO,GRUPO,SUBGRUPO,ANIO
		 

END