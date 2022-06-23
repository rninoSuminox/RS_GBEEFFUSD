/* REPORTE DEMOSTRACION DE RESULTADOS
exec pr_rptBalanceGeneral_USD @ANIO=2022,@MONEDA=N'USD',@EMPRESA=N'BALBS',@MESPERIODO=12

--se ejecuta en la BD principal, debe tener todas las cuentas contables.
exec pr_rptCuentasEmpresa_USD @ANIO=2021,@EMPRESA='BALBS',@IDREPORTE='RPTBGRAL';
*/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_rptBalanceGeneral_USD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].pr_rptBalanceGeneral_USD
 go
CREATE  PROCEDURE pr_rptBalanceGeneral_USD 
(@ANIO		INT
,@MONEDA	VARCHAR(6)='USD' 
,@EMPRESA   VARCHAR(100)
,@MESPERIODO	INT=12)
AS
BEGIN

	DECLARE @TASA	   CHAR(15)=(SELECT TOP 1 TAXSCHID FROM BEF00200); --TASA DE CONVERSION 'USD REPORTE'
	DECLARE @TASABCV	   CHAR(15)=(SELECT TOP 1 TAXDTLID FROM BEF00200); --TASA DE CONVERSION 'USD REPORTE'      
	DECLARE @PER1 CHAR(6)
	DECLARE @MES INT=@MESPERIODO -- TODO EL A�O
	DECLARE @ANIOANT INT=@ANIO-1
--LLENA TABLA PARA EL EDO RESULTADOS
BEGIN 
		DECLARE @RPTRESULTADOS AS TABLE (
							[NIVELGRUPO] [varchar](36) NOT NULL,
							[GRUPO] [varchar](31) NULL,
							[SUBGRUPO] [nvarchar](11) NULL,
							[SEGMENTO] [varchar](20) NULL,
							[ANIO] [int] NULL,
							[ACTDESCR] [varchar](50) NULL,
							[SALDO] [numeric](38, 5) NULL,
							[ENE] [numeric](38, 5) NULL,
							[FEB] [numeric](38, 5) NULL,
							[MAR] [numeric](38, 5) NULL,
							[ABR] [numeric](38, 5) NULL,
							[MAY] [numeric](38, 5) NULL,
							[JUN] [numeric](38, 5) NULL,
							[JUL] [numeric](38, 5) NULL,
							[AGO] [numeric](38, 5) NULL,
							[SEP] [numeric](38, 5) NULL,
							[OCT] [numeric](38, 5) NULL,
							[NOV] [numeric](38, 5) NULL,
							[DIC] [numeric](38, 5) NULL,
							[ANIOTRX] [int] NULL,
							[PER01] [nvarchar](2) NULL,
							[PER02] [nvarchar](2) NULL,
							[PER03] [nvarchar](2) NULL,
							[PER04] [nvarchar](2) NULL,
							[PER05] [nvarchar](2) NULL,
							[PER06] [nvarchar](2) NULL,
							[PER07] [nvarchar](2) NULL,
							[PER08] [nvarchar](2) NULL,
							[PER09] [nvarchar](2) NULL,
							[PER10] [nvarchar](2) NULL,
							[PER11] [nvarchar](2) NULL,
							[PER12] [nvarchar](2) NULL)
		INSERT INTO @RPTRESULTADOS
		exec pr_rptDR_USDT2 @ANIO=@ANIO,@MESPERIODO=@MESPERIODO,@EMPRESA=@EMPRESA,@MONEDA=@MONEDA,@FLGCTACAMBIO=0
END;


--EJECUTA SP PARA ARMAR PERIODOS
	exec pr_periodosEEFF_USD @ANIO=@ANIO,@EMPRESA=@EMPRESA	
--EJECUTA SP, PARA LLENAR TABLA CON SALDOS y aplicar filtros
	exec pr_CuentasFinancieroEmpresa_BSF @ANIO=@ANIO,@MES=@MES,@EMPRESA=@EMPRESA,@IDREPORTE='RPTBGRAL';
--	exec pr_rptCuentasEmpresa_USD @ANIO=@ANIO,@EMPRESA=@EMPRESA,@IDREPORTE='RPTBGRAL';
--EJECUTA SP, PARA LLENAR TABLA CON costos y aplicar filtros
	exec pr_rptCostosEmpresa_USD  @ANIO=@ANIO,@MES=@MES,@EMPRESA=@EMPRESA,@IDREPORTE='RPTBGRAL';

	DECLARE @MONFUNC VARCHAR(6) = (SELECT TOP 1 RTRIM(CURNCYID) CURNCYID FROM TEMPSALDOSF WHERE CURNCYID<>'USD'); --MONEDA BSF

	 --DATOS PARA ARMAR LOS PERIODOS
	WITH CTE_ANIOS AS (
					SELECT @ANIO ANIO,CONVERT(INT,RIGHT(RTRIM(PERIODO),2)) PERIODO
					  FROM TEMPPERIODO P
				UNION ALL
					SELECT @ANIOANT ANIO,CONVERT(INT,RIGHT(RTRIM(PERIODO),2)) PERIODO
					 FROM TEMPPERIODO P ),
	CTE_CTASFULL AS ( --completa periodos y cuentas
	           SELECT A.ANIO,A.PERIODO,A.PERIODO MES,CONVERT(DATE,CONCAT(A.ANIO,RIGHT(CONCAT('00',A.PERIODO),2),'01')) TRXDATE
				     ,C.ACTNUMST
					 ,RTRIM(CURNCYID) CURNCYID
				 ,0.00 DEBITAMT,0.00 CRDTAMNT,0.00 ORDBTAMT,0.00 ORCRDAMT,NULL NOTA,0 PSTNGTYP				
				 FROM (
				SELECT DISTINCT ACTNUMST FROM TEMPSALDOSF)  C
				INNER JOIN (SELECT DISTINCT CURNCYID FROM TEMPSALDOSF) M ON 1=1
				INNER JOIN CTE_ANIOS A ON 1=1
				--EXCLUYE ALGUNAS CUENTAS
				WHERE NOT((LEFT(C.ACTNUMST,1)='3' AND CURNCYID='USD') OR (SUBSTRING(C.ACTNUMST,8,1) IN ('6','7','8') AND CURNCYID<>'USD'))
				),
	CTE_CUENTAS AS (
				SELECT ANIO,PERIODID,PERIODID MES,TRXDATE,ACTNUMST						
						,CASE WHEN SUBSTRING(ACTNUMST,8,1) IN ('6','7','8') THEN 'USD'
							 -- WHEN LEFT(ACTNUMST,1)='3' THEN @MONFUNC
						 ELSE @MONFUNC END CURNCYID --forzamos la moneda
						,DEBITAMT,CRDTAMNT,ORDBTAMT,ORCRDAMT,NOTA,PSTNGTYP
						,CURNCYID  MONEDAORG
						  FROM TEMPSALDOSF
				UNION ALL --para completar periodos y cuentas faltantes
					SELECT A.*,A.CURNCYID  MONEDAORG 
					  FROM CTE_CTASFULL A
					  LEFT JOIN TEMPSALDOSF T ON T.ANIO=A.ANIO AND T.PERIODID=A.MES AND A.ACTNUMST=T.ACTNUMST AND T.CURNCYID=A.CURNCYID
					 WHERE T.CURNCYID IS NULL ),--C3				
	 --datos principales del reporte
	 	 CTE_AGRUPA AS (
	 		SELECT ANIO,MES,MAX(YEAR(TRXDATE)) ANIOTRX,ACTNUMST						
						,CURNCYID
						--TODO SE MANEJA COMO BSF AL CAMBIO SEGUN LA TASA
				,SUM(sum(iif(CURNCYID<>'USD',DEBITAMT-CRDTAMNT,0))) 
							OVER(PARTITION BY actnumst,CURNCYID ORDER BY ANIO,MES,CURNCYID) SALDOBSF
				,SUM(sum(iif(CURNCYID='USD',DEBITAMT-CRDTAMNT,0))) 
							OVER(PARTITION BY actnumst,CURNCYID ORDER BY ANIO,MES,CURNCYID) SALDOUSD
						,EOMONTH(MAX(TRXDATE)) TRXDATE
						--,IIF(LEFT(ACTNUMST,1) IN ('1','2') AND SUBSTRING(ACTNUMST,8,1) IN ('6','7','8'),@TASABCV,@TASA) TASA
						,IIF(SUBSTRING(ACTNUMST,8,1) IN ('6','7','8'),@TASABCV,@TASA) TASA
					FROM CTE_CUENTAS 
					GROUP BY ANIO,MES,ACTNUMST,CURNCYID),
		CTE_FILTRA  AS (SELECT * FROM CTE_AGRUPA WHERE ANIO IN (@ANIO,@ANIOANT)),--para quitar a�os que no se necesitan
		CTE_INICIAL AS (SELECT ANIO,MES,ANIOTRX,ACTNUMST,CURNCYID
								,CASE WHEN @MONEDA= 'USD' and CURNCYID= 'USD' then 'Moneda Extranjera'
									  WHEN @MONEDA= 'USD' and CURNCYID<>'USD' then 'Bolivares al Cambio'
									  WHEN @MONEDA<>'USD' and CURNCYID= 'USD' then 'Dolares al Cambio'
									  WHEN @MONEDA<>'USD' and CURNCYID<>'USD' then 'Moneda Nacional'
								 END  TXTMONEDA
										,IIF(SALDOBSF=0,0,SALDOBSF/dbo.f_buscatasadia(TRXDATE,TASA)) SALDOBSF	--,iif(CURNCYID<>'USD',SALDOBSF,0)					
										,IIF(SALDOUSD=0,0,SALDOUSD/dbo.f_buscatasadia(TRXDATE,TASA)) SALDOUSD
						 FROM CTE_FILTRA),
		 CTE_SALDOS AS ( --SALDO CTAS por mes
						 SELECT ANIO,MES,ANIOTRX,ACTNUMST
								,IIF(LEFT(ACTNUMST,1) IN ('3','2'),
									(ISNULL(SALDOBSF,0)+ISNULL(SALDOUSD,0)) * -1 --CAMBIO 20220610 ROBERTO
									,ISNULL(SALDOBSF,0)+ISNULL(SALDOUSD,0)) SALDO
								,CURNCYID
								,TXTMONEDA
						   FROM CTE_INICIAL
						   WHERE ANIO IN (@ANIO,@ANIOANT)), --C1
		   CTE_COSTOS AS ( --COSTOS
					 SELECT ANIO,ANIO ANIOTRX,MES,TIPO ACTDESCR,'11501' ACTNUMST --PARA DARLE FORMATO
					          ,VALOR
							  ,IIF(@MONEDA='USD'					  
								  ,IIF(ORDEN IN (1,2,3),(VALORUSD *-1),VALORUSD)
								  ,IIF(ORDEN IN (1,2,3),(VALOR *-1),VALOR)) SALDO
					   FROM TEMPCOSTOS WHERE ORDEN=4 ),--SOLO INVENTARIO FINAL
		--para el dise�o del reporte.
			  CTE_NIVEL1 AS (SELECT RTRIM([ACTNUMST]) IDXNVL1,
									   [ACTDESCR] TXTNVL1,
									   [Visible] VISNVL1
								 FROM BEF00500 WHERE LVL=1 AND RPRTNAME='RPTBGRAL'),
			  CTE_NIVEL2 AS (SELECT RTRIM([ACTNUMST]) INDICE,
									   [ACTDESCR] TITULO,
									   [Visible] VISIBLE,
									   [DecimalDigits] DIGITOS
								 FROM BEF00500 WHERE LVL=2 AND RPRTNAME='RPTBGRAL'),
			  CTE_SEGMENTO AS ( --PARA USAR COMO GRUPO --3 digitos NIVEL2
							 SELECT NV2.INDICE SEGMENTO
							 ,IIF(ISNULL(NV2.TITULO,'')='',G.DSCRIPTN,NV2.TITULO) TXTNVL2
							 ,NV2.DIGITOS,VISIBLE VISNVL2
							   FROM CTE_NIVEL2 NV2
							  LEFT JOIN GL40200 G ON NV2.INDICE=G.SGMNTID),
							  --INNER JOIN GL40200 G ON NV2.INDICE=LEFT(G.SGMNTID,NV2.DIGITOS)),
			  CTE_SUBGRUPO AS (SELECT RTRIM([ACTNUMST]) SGMNTID,
									   [ACTDESCR] DSCRIPTN,
									   [Visible] VISIBLE,
									   [DecimalDigits] DIGITOS,
									   CURRNIDX  MONEDA
								 FROM BEF00500 WHERE LVL=3 AND RPRTNAME='RPTBGRAL'),
		 CTE_DATOS as( --SACA MESES ANTES DE AGRUPAR
		 --el nivel de agrUpamiento es, NIVELGRUPO,SEGMENTO GRUPO Y SUBGRUPO 
				SELECT   ANIO,MES,ACTNUMST
						,ISNULL(N3.DSCRIPTN,N2.TXTNVL2) ACTDESCR
						,CURNCYID,TXTMONEDA
						,SALDO 
					--DATOS DE ORDEN O FORMA REPORTE
						,N1.IDXNVL1 ,N1.TXTNVL1 NIVELGRUPO  ,N1.VISNVL1
						,N2.SEGMENTO,N2.TXTNVL2 GRUPO,N2.VISNVL2
						,N3.SGMNTID ,N3.DSCRIPTN SUBGRUPO   ,N3.MONEDA --SIEMPRE ES VISIBLE
						--DATOS $$$ DEL REPORTE
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
						--PERIODOS DEL REPORTE
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
			   INNER JOIN CTE_NIVEL1   N1 ON N1.IDXNVL1=LEFT(S.ACTNUMST,1) 
				LEFT JOIN CTE_SEGMENTO N2 ON N2.SEGMENTO=LEFT(S.ACTNUMST,N2.DIGITOS) 
				LEFT JOIN CTE_SUBGRUPO N3 ON N3.SGMNTID=LEFT(REPLACE(S.ACTNUMST,'-',''),N3.DIGITOS) --SI NO CONSIGUE EL SEGMENTO TRAE LA DESCRIPCION DE CUENTA.
				WHERE S.ANIO IN (@ANIO,@ANIOANT)
				UNION ALL 
				--COSTOS USD
				SELECT ANIO,MES,S.ACTNUMST
				       ,ACTDESCR
				       ,'USD' CURNCYID,'Moneda Extranjera' TXTMONEDA
					   ,SALDO
					  --DATOS DE ORDEN O FORMA REPORTE
						,N1.IDXNVL1 ,N1.TXTNVL1 NIVELGRUPO  ,N1.VISNVL1
						,N2.SEGMENTO,N2.TXTNVL2 GRUPO,N2.VISNVL2
						,N3.SGMNTID ,N3.DSCRIPTN SUBGRUPO   ,N3.MONEDA --SIEMPRE ES VISIBLE
					--datos reporte
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
				  FROM CTE_COSTOS S
			   INNER JOIN CTE_NIVEL1   N1 ON N1.IDXNVL1=LEFT(S.ACTNUMST,1) 
				LEFT JOIN CTE_SEGMENTO N2 ON N2.SEGMENTO=LEFT(S.ACTNUMST,3) 
				LEFT JOIN CTE_SUBGRUPO N3 ON N3.SGMNTID=LEFT(REPLACE(S.ACTNUMST,'-',''),5)
	   ),
CTE_FINAL AS (--SE CREA PARA CALCULAR DIFERENCIA EN CONVERSION
SELECT   IDXNVL1,MAX(NIVELGRUPO) NIVELGRUPO,MAX(VISNVL1) VISNVL1
	    ,SEGMENTO,MAX(GRUPO) GRUPO,MAX(VISNVL2) VISNVL2
		,SGMNTID,MAX(SUBGRUPO) SUBGRUPO ,MAX(MONEDA) MONEDA
		,ANIO
		,MAX(ACTDESCR) ACTDESCR
		,CURNCYID
		,MAX(TXTMONEDA) TXTMONEDA		
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
		GROUP BY IDXNVL1,SEGMENTO,SGMNTID,ANIO,CURNCYID),
		--TOTALIZA EL EDO RESULTADOS SUMANDO EL MES ANTERIOR
	CTE_EDORESULTADOS AS (SELECT ANIO
							,SUM(SALDO) SALDO
							,SUM(ENE  )   ENE
							,SUM(ENE+FEB  )   FEB
							,SUM(ENE+FEB+MAR  )   MAR
							,SUM(ENE+FEB+MAR+ABR  )   ABR
							,SUM(ENE+FEB+MAR+ABR+MAY  )   MAY
							,SUM(ENE+FEB+MAR+ABR+MAY+JUN  )   JUN
							,SUM(ENE+FEB+MAR+ABR+MAY+JUN+JUL  )   JUL
							,SUM(ENE+FEB+MAR+ABR+MAY+JUN+JUL+AGO  )   AGO
							,SUM(ENE+FEB+MAR+ABR+MAY+JUN+JUL+AGO+SEP  )   SEP
							,SUM(ENE+FEB+MAR+ABR+MAY+JUN+JUL+AGO+SEP+OCT  )   OCT
							,SUM(ENE+FEB+MAR+ABR+MAY+JUN+JUL+AGO+SEP+OCT+NOV  )   NOV
							,SUM(ENE+FEB+MAR+ABR+MAY+JUN+JUL+AGO+SEP+OCT+NOV+DIC  )   DIC
						FROM @RPTRESULTADOS GROUP BY ANIO),
CTE_REPORTE AS(
SELECT * FROM CTE_FINAL WHERE SGMNTID!='31109' --SE EXCLUYE PARA LLENAR CON EL EDO RESULTADOS
UNION ALL
--PARA AGREGAR CUENTA 31109 CON LOS VALORES DEL REPORTE DE RESULTADOS
	SELECT   B.IDXNVL1,B.NIVELGRUPO,B.VISNVL1,B.SEGMENTO,B.GRUPO,B.VISNVL2
			,B.SGMNTID,B.SUBGRUPO,B.MONEDA,B.ANIO,B.ACTDESCR,B.CURNCYID,B.TXTMONEDA
			,R.SALDO,R.ENE,R.FEB,R.MAR,R.ABR,R.MAY,R.JUN,R.JUL,R.AGO,R.SEP,R.OCT,R.NOV,R.DIC
			,B.ANIOTRX,B.PER01,B.PER02,B.PER03,B.PER04,B.PER05,B.PER06,B.PER07,B.PER08,B.PER09,B.PER10,B.PER11,B.PER12
	  FROM CTE_FINAL B
		INNER JOIN CTE_EDORESULTADOS  R ON B.ANIO=R.ANIO
	 WHERE B.SGMNTID='31109' --AND B.CURNCYID=@MONEDA --se quitan los dolares
),
CTE_CALCULODF AS ( --calculo por nivel para sacar diferencia en cambio
SELECT   IDXNVL1,MAX(GRUPO) GRUPO,MAX(VISNVL2) VISNVL2,ANIO		
	    ,SUM(SALDO)SALDO 
		,SUM(ENE  )  ENE
		,SUM(FEB  )  FEB
		,SUM(MAR  )  MAR
		,SUM(ABR  )  ABR
		,SUM(MAY  )  MAY
		,SUM(JUN  )  JUN
		,SUM(JUL  )  JUL
		,SUM(AGO  )  AGO
		,SUM(SEP  )  SEP
		,SUM(OCT  )  OCT
		,SUM(NOV  )  NOV
		,SUM(DIC  )  DIC
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
		FROM  CTE_REPORTE
		GROUP BY ANIO,IDXNVL1)


--PARA AGREGAR LA DIFERENCIA DE CONVERSION	
SELECT * FROM CTE_REPORTE 
	UNION ALL	
SELECT  '3' IDXNVL1,'PATRIMONIO' NIVELGRUPO,0 VISNVL1
	    ,'311' SEGMENTO,MAX(GRUPO) GRUPO,MAX(VISNVL2) VISNVL2
		,'99999' SGMNTID,'Diferencia en Conversi�n' SUBGRUPO ,0 MONEDA
		,ANIO
		,'Diferencia en Conversi�n' ACTDESCR
		,@MONEDA CURNCYID
		,'' TXTMONEDA
	  --PQC Roberto 16-06-2022		
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (SALDO)*-1 ELSE SALDO END ) SALDO
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (ENE  )*-1 ELSE ENE   END ) ENE  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (FEB  )*-1 ELSE FEB   END ) FEB  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (MAR  )*-1 ELSE MAR   END ) MAR  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (ABR  )*-1 ELSE ABR   END ) ABR  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (MAY  )*-1 ELSE MAY   END ) MAY  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (JUN  )*-1 ELSE JUN   END ) JUN  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (JUL  )*-1 ELSE JUL   END ) JUL  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (AGO  )*-1 ELSE AGO   END ) AGO  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (SEP  )*-1 ELSE SEP   END ) SEP  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (OCT  )*-1 ELSE OCT   END ) OCT  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (NOV  )*-1 ELSE NOV   END ) NOV  
	  ,SUM(CASE WHEN idxnvl1 in (2,3) then (DIC  )*-1 ELSE DIC   END ) DIC
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
		FROM  CTE_CALCULODF
	   GROUP BY ANIO 


END

/*
C1:
		--CTE_SALDOS AS (SELECT ANIO,MES,ANIOTRX,ACTNUMST
		--					,iif(SALDO=0,LAG(SALDO,1,0) OVER (PARTITION BY ACTNUMST,CURNCYID ORDER BY ANIO,MES),SALDO)		SALDO
		--					,SALDO
		--						,ACTDESCR
		--						,CURNCYID
		--						,TXTMONEDA
		--				   FROM CTE_INISALDOS),

		C2:
				--SELECT DISTINCT A.ANIO,A.PERIODO,A.PERIODO MES,CONVERT(DATE,CONCAT(A.ANIO,RIGHT(CONCAT('00',A.PERIODO),2),'01')) TRXDATE
				--     ,ACTDESCR,C.ACTNUMST,RTRIM(C.CURNCYID) CURNCYID,0.00 DEBITAMT,0.00 CRDTAMNT,0.00 ORDBTAMT,0.00 ORCRDAMT,NULL NOTA,0 PSTNGTYP
				-- FROM TEMPSALDOSF C
				-- INNER JOIN CTE_ANIOS A ON A.ANIO=C.ANIO
				-- LEFT JOIN (SELECT DISTINCT ANIO,PERIODID PERIODO,ACTNUMST,CURNCYID FROM   TEMPSALDOSF) V
				--  ON C.ANIO=V.ANIO AND A.PERIODO=V.PERIODO AND C.ACTNUMST=V.ACTNUMST AND V.CURNCYID=C.CURNCYID
				-- WHERE C.ANIO IN (@ANIO,@ANIOANT) --AND C.ACTNUMST='212-01-1002'
				-- AND V.ANIO IS NULL

C3: SE CAMBIA PARA QUE TOME LOS VALORES COMPLETOS
				SELECT DISTINCT A.ANIO,A.PERIODO,A.PERIODO MES,CONVERT(DATE,CONCAT(A.ANIO,RIGHT(CONCAT('00',A.PERIODO),2),'01')) TRXDATE
				     ,ACTDESCR,C.ACTNUMST
					 				,CASE WHEN SUBSTRING(C.ACTNUMST,8,1) IN ('6','7','8') THEN 'USD'
					  WHEN LEFT(C.ACTNUMST,1)='3' THEN 'BS.S'
				 ELSE 'BS.S' END CURNCYID --PARA QUE AGRUPE LAS CUENTAS COMO DOLARES 
				 ,0.00 DEBITAMT,0.00 CRDTAMNT,0.00 ORDBTAMT,0.00 ORCRDAMT,NULL NOTA,0 PSTNGTYP
				 FROM TEMPSALDOSF C
				 INNER JOIN CTE_ANIOS A ON A.ANIO=C.ANIO
				 LEFT JOIN (SELECT DISTINCT ANIO,PERIODID PERIODO,ACTNUMST,CURNCYID FROM   TEMPSALDOSF) V
				  ON C.ANIO=V.ANIO AND A.PERIODO=V.PERIODO AND C.ACTNUMST=V.ACTNUMST AND V.CURNCYID=C.CURNCYID
				 WHERE C.ANIO IN (@ANIO,@ANIOANT) --AND C.ACTNUMST='212-01-1002'
				 AND V.ANIO IS NULL
-------------------------------------------------------------

 		SELECT ANIO,MES,MAX(YEAR(TRXDATE)) ANIOTRX,ACTNUMST
						,MAX(ACTDESCR) ACTDESCR
						,CURNCYID
						,CASE WHEN @MONEDA='USD'  and CURNCYID='USD'  then 'Moneda Extranjera'
							WHEN @MONEDA='USD'  and CURNCYID<>'USD' then 'Bolivares al Cambio'
							WHEN @MONEDA<>'USD' and CURNCYID='USD'  then 'Dolares al Cambio'
							WHEN @MONEDA<>'USD' and CURNCYID<>'USD' then 'Moneda Nacional'
						END  TXTMONEDA
				,SUM(sum(iif(CURNCYID<>'USD',DEBITAMT-CRDTAMNT,0))) 
							OVER(PARTITION BY actnumst,CURNCYID ORDER BY ANIO,MES,CURNCYID) SALDOBSF
					,
					IIF(LEFT(ACTNUMST,1) IN ('1','2') AND SUBSTRING(ACTNUMST,8,1) IN ('6','7','8'),@TASABCV
					,@TASA) TASA
					,EOMONTH(max(TRXDATE)) TRXDATE
				--,SUM(sum(iif(CURNCYID<>'USD',DEBITAMT-CRDTAMNT,0))) 
				--			OVER(PARTITION BY actnumst,CURNCYID ORDER BY ANIO,MES,CURNCYID)
				--	/dbo.f_buscatasadia(EOMONTH(max(TRXDATE)),
				--	IIF(LEFT(ACTNUMST,1) IN ('1','2') AND SUBSTRING(ACTNUMST,8,1) IN ('6','7','8'),@TASABCV
				--	,@TASA)) SALDOBSF
				,SUM(sum(ORDBTAMT-ORCRDAMT)) 
							OVER(PARTITION BY actnumst,CURNCYID ORDER BY ANIO,MES,CURNCYID) SALDOUSD
					FROM CTE_CUENTAS
					WHERE RIGHT(RTRIM(ACTNUMST),3)<>'995'
					GROUP BY ANIO,MES,ACTNUMST,CURNCYID

c4:
--SELECT   max(IDXNVL1) IDXNVL1,MAX(NIVELGRUPO) NIVELGRUPO,MAX(VISNVL1) VISNVL1
--	    ,'311' SEGMENTO,MAX(GRUPO) GRUPO,MAX(VISNVL2) VISNVL2
--		,'99999' SGMNTID,'Diferencia en Conversi�n' SUBGRUPO ,0 MONEDA
--		,ANIO
--		,'Diferencia en Conversi�n' ACTDESCR
--		,@MONEDA CURNCYID
--		,'' TXTMONEDA		
--	    ,SUM(iif(IDXNVL1=1,(SALDO),SALDO ))*-1 SALDO --VALIDAR CALCULO CON ROBERTO PARA VER SI ES NECESARIO
--		--,SUM(iif(IDXNVL1=1,(ENE  ),ENE   ))*-1   ENE
--		,-61852 ENE
--		,SUM(iif(IDXNVL1=1,(FEB  ),FEB   ))*-1   FEB
--		,SUM(iif(IDXNVL1=1,(MAR  ),MAR   ))*-1   MAR
--		,SUM(iif(IDXNVL1=1,(ABR  ),ABR   ))*-1   ABR
--		,SUM(iif(IDXNVL1=1,(MAY  ),MAY   ))*-1   MAY
--		,SUM(iif(IDXNVL1=1,(JUN  ),JUN   ))*-1   JUN
--		,SUM(iif(IDXNVL1=1,(JUL  ),JUL   ))*-1   JUL
--		,SUM(iif(IDXNVL1=1,(AGO  ),AGO   ))*-1   AGO
--		,SUM(iif(IDXNVL1=1,(SEP  ),SEP   ))*-1   SEP
--		,SUM(iif(IDXNVL1=1,(OCT  ),OCT   ))*-1   OCT
--		,SUM(iif(IDXNVL1=1,(NOV  ),NOV   ))*-1   NOV
--		,SUM(iif(IDXNVL1=1,(DIC  ),DIC   ))*-1   DIC
--		,MAX(ANIOTRX) ANIOTRX
--		,MAX(PER01	) PER01
--		,MAX(PER02	) PER02
--		,MAX(PER03	) PER03
--		,MAX(PER04	) PER04
--		,MAX(PER05	) PER05
--		,MAX(PER06	) PER06
--		,MAX(PER07	) PER07
--		,MAX(PER08	) PER08
--		,MAX(PER09	) PER09
--		,MAX(PER10	) PER10
--		,MAX(PER11	) PER11
--		,MAX(PER12	) PER12
--		from  CTE_REPORTE
--		GROUP BY ANIO
--		order by IDXNVL1,SEGMENTO,SGMNTID,ANIO,CURNCYID
C5:
	CTE_CTASFULL AS (SELECT A.ANIO,A.PERIODO,A.PERIODO MES,CONVERT(DATE,CONCAT(A.ANIO,RIGHT(CONCAT('00',A.PERIODO),2),'01')) TRXDATE
				     ,C.ACTDESCR,C.ACTNUMST
					 ,CASE WHEN SUBSTRING(C.ACTNUMST,8,1) IN ('6','7','8') THEN 'USD'
					  WHEN LEFT(C.ACTNUMST,1)='3' THEN @MONFUNC
				      ELSE CURNCYID END CURNCYID --PARA QUE AGRUPE LAS CUENTAS COMO DOLARES 
				 ,0.00 DEBITAMT,0.00 CRDTAMNT,0.00 ORDBTAMT,0.00 ORCRDAMT,NULL NOTA,0 PSTNGTYP				
				 FROM (
				SELECT DISTINCT ACTNUMST,ACTDESCR FROM TEMPSALDOSF)  C
				INNER JOIN (SELECT DISTINCT CURNCYID FROM TEMPSALDOSF) M ON 1=1
				INNER JOIN CTE_ANIOS A ON 1=1),

c6:
	,SUM(sum(iif(MONEDAORG<>'USD' AND SUBSTRING(ACTNUMST,8,1) NOT IN ('6','7','8'),DEBITAMT-CRDTAMNT,0))) 
				OVER(PARTITION BY ACTNUMST,CURNCYID ORDER BY ANIO,MES,CURNCYID) SALDOBSF
	,SUM(sum(iif(SUBSTRING(ACTNUMST,8,1) IN ('6','7','8'),DEBITAMT-CRDTAMNT,0))) 
				OVER(PARTITION BY ACTNUMST,CURNCYID ORDER BY ANIO,MES,CURNCYID) SALDOBU
	,SUM(sum(iif(MONEDAORG='USD' AND SUBSTRING(ACTNUMST,8,1) NOT IN ('6','7','8'),ORDBTAMT-ORCRDAMT,0))) 
				OVER(PARTITION BY ACTNUMST,CURNCYID ORDER BY ANIO,MES,CURNCYID) SALDOUSD
c7:
	  --PQC Roberto 16-06-2022		
	  ,SUM(CASE WHEN idxnvl1=2 then abs(SALDO)*-1 WHEN idxnvl1=3 then abs(SALDO) ELSE SALDO END ) SALDO
	  ,SUM(CASE WHEN idxnvl1=2 then abs(ENE  )*-1 WHEN idxnvl1=3 then abs(ENE  ) ELSE ENE   END ) ENE  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(FEB  )*-1 WHEN idxnvl1=3 then abs(FEB  ) ELSE FEB   END ) FEB  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(MAR  )*-1 WHEN idxnvl1=3 then abs(MAR  ) ELSE MAR   END ) MAR  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(ABR  )*-1 WHEN idxnvl1=3 then abs(ABR  ) ELSE ABR   END ) ABR  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(MAY  )*-1 WHEN idxnvl1=3 then abs(MAY  ) ELSE MAY   END ) MAY  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(JUN  )*-1 WHEN idxnvl1=3 then abs(JUN  ) ELSE JUN   END ) JUN  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(JUL  )*-1 WHEN idxnvl1=3 then abs(JUL  ) ELSE JUL   END ) JUL  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(AGO  )*-1 WHEN idxnvl1=3 then abs(AGO  ) ELSE AGO   END ) AGO  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(SEP  )*-1 WHEN idxnvl1=3 then abs(SEP  ) ELSE SEP   END ) SEP  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(OCT  )*-1 WHEN idxnvl1=3 then abs(OCT  ) ELSE OCT   END ) OCT  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(NOV  )*-1 WHEN idxnvl1=3 then abs(NOV  ) ELSE NOV   END ) NOV  
	  ,SUM(CASE WHEN idxnvl1=2 then abs(DIC  )*-1 WHEN idxnvl1=3 then abs(DIC  ) ELSE DIC   END ) DIC
--posible mejora
		CTE_FECHAS  AS (SELECT DISTINCT TRXDATE FECHA,TASA FROM CTE_FILTRA),
		CTE_TASAS   AS (SELECT FECHA,TASA IDTASA,dbo.f_buscatasadia(FECHA,TASA) NTASA FROM CTE_FECHAS),
		CTE_INICIAL AS (SELECT ANIO,MES,ANIOTRX,ACTNUMST,CURNCYID
								,CASE WHEN @MONEDA= 'USD' and CURNCYID= 'USD' then 'Moneda Extranjera'
									  WHEN @MONEDA= 'USD' and CURNCYID<>'USD' then 'Bolivares al Cambio'
									  WHEN @MONEDA<>'USD' and CURNCYID= 'USD' then 'Dolares al Cambio'
									  WHEN @MONEDA<>'USD' and CURNCYID<>'USD' then 'Moneda Nacional'
								 END  TXTMONEDA
										,ISNULL(IIF(SALDOBSF=0,0,SALDOBSF/T.NTASA)
												,0) SALDOBSF	--,iif(CURNCYID<>'USD',SALDOBSF,0)					
										,ISNULL(IIF(SALDOUSD=0,0,SALDOUSD/T.NTASA)
												,0) SALDOUSD	--,iif(CURNCYID<>'USD',SALDOBSF,0)	 
										
										,dbo.f_buscatasadia(TRXDATE,TASA) CCTASA,TASA
						 FROM CTE_FILTRA F
						 LEFT JOIN CTE_TASAS T ON T.FECHA=F.TRXDATE AND T.IDTASA=F.TASA ),

*/