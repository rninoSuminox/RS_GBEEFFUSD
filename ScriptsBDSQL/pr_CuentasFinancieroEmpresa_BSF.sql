/*
exec pr_CuentasFinancieroEmpresa_BSF @ANIO=2022,@MES=12,@EMPRESA=N'balbs',@IDREPORTE='RPTBGRAL'
TEMPSALDOSF order by actnumst,TRXDATE, curncyid
*/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_CuentasFinancieroEmpresa_BSF]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].pr_CuentasFinancieroEmpresa_BSF
 go
CREATE  PROCEDURE pr_CuentasFinancieroEmpresa_BSF 
(@ANIO		INT
,@MES		INT
,@EMPRESA   VARCHAR(100)
,@IDREPORTE VARCHAR(15)='')
AS
BEGIN

	DECLARE @INIPERIODO DATE=convert(date,CONCAT(CONVERT(CHAR(4),@ANIO)
						 ,RIGHT(CONCAT('0',RTRIM(CONVERT(CHAR(2),@MES))),2)
						 ,'01'))
	DECLARE @FINPERIODO DATE=EOMONTH(@INIPERIODO)



	DECLARE @SQLSTR    NVARCHAR(MAX)='',@Parametro nvarchar(500)
	DECLARE @XEMP VARCHAR(15)
	DECLARE @FILTRO NVARCHAR(MAX)=' AND 1=1'

	DECLARE @ANIOANT INT=@ANIO-1
	DECLARE @CTACIERRE CHAR(6)=(select RERINDX from GL40000) --BUSCA CUENTA DE CIERRE
	--tabla para llenar datos principales
	if exists(select 1 from sys.tables where name='TEMPSALDOSF')
		drop table TEMPSALDOSF;
		CREATE TABLE TEMPSALDOSF (ANIO			INT
								 ,PERIODID			INT
									,MES			INT
									,TRXDATE		DATE
									,ACTDESCR		CHAR(50)
									,ACTNUMST		CHAR(20)
									,CURNCYID		CHAR(15)
									,DEBITAMT		NUMERIC(19,5)
									,CRDTAMNT		NUMERIC(19,5)
									,ORDBTAMT		NUMERIC(19,5)
									,ORCRDAMT		NUMERIC(19,5)
									,NOTA			CHAR(20)
									,PSTNGTYP		smallint)
		CREATE INDEX idx_ACTNUMST ON TEMPSALDOSF (ACTNUMST)

	--cargar filtros tabla configuracion debo crear esta tabla 
	--FALTA MEJORAR ESTA SECCION
	IF (@IDREPORTE='BALCOMP') SET @FILTRO=' AND LEFT(C.ACTNUMBR_1,1) between (''1'') and (''9'')'

--balance general
	IF (@IDREPORTE='RPTBGRAL')   SET @FILTRO=' AND LEFT(C.ACTNUMBR_1,1) between (''1'') and (''3'')
	          AND (LEFT(ACTNUMST,3) not in (''115'',''117'',''171'',''241'',''281'') or LEFT(ACTNUMST,5) =''115-07'') '
--se agrega cuenta 115.07 - RN 10062022-SOLICITUD DE ROBERTO
	print  @FILTRO
	--cursor para poder consolidar las empresas
	DECLARE EMPRESAS CURSOR FOR   
	SELECT Value FROM dbo.Split(@EMPRESA,',')  WHERE VALUE<>''

    --BUSCAR E INSERTAR DE CADA EMPRESA
	OPEN EMPRESAS  
	FETCH NEXT FROM EMPRESAS INTO @XEMP   
	WHILE @@FETCH_STATUS = 0  
		BEGIN  
		--select @XEMP	 LEFT JOIN ' + @XEMP +'.dbo.GL30000 S ON C.ACTINDX=S.ACTINDX
		-- LEFT JOIN ' + @XEMP +'.dbo.GL20000 S ON C.ACTINDX=S.ACTINDX  
		--AND S.HSTYEAR<=@ANIO AND S.PERIODID<=@PERIODID  RN-PARA QUE FILTRE POR PERIODO CORRECTAMENTE	
		SET @SQLSTR=@SQLSTR+'DECLARE @ASIENTOINICIAL' + @XEMP +' INT = (SELECT TOP 1 JRNENTRY FROM ' + @XEMP +'.dbo.GL30000 WHERE PERIODID=0 ORDER BY TRXDATE);
							DECLARE @FECHAFP' + @XEMP +' DATE = (SELECT TOP 1 EOMONTH(PERIODDT) from ' + @XEMP +'.dbo.SY40100  WHERE YEAR1=@ANIO AND SERIES=0 AND PERIODID=@PERIODID); 
		INSERT INTO TEMPSALDOSF (ANIO,PERIODID,MES,TRXDATE,DEBITAMT,CRDTAMNT,ORDBTAMT,ORCRDAMT,ACTDESCR,ACTNUMST,CURNCYID,PSTNGTYP)
									SELECT   HSTYEAR ANIO									      
											,PERIODID,PERIODID MES
											,S.TRXDATE TRXDATE
											,SUM(S.DEBITAMT) DEBITAMT
											,SUM(S.CRDTAMNT) CRDTAMNT
											,SUM(IIF(RTRIM(CURNCYID)=''USD'',ISNULL(B.ORDBTAMT,S.ORDBTAMT),0)) ORDBTAMT
											,SUM(IIF(RTRIM(CURNCYID)=''USD'',ISNULL(B.ORCRDAMT,S.ORCRDAMT),0)) ORCRDAMT
											,MAX(RTRIM(ACTDESCR)) ACTDESCR
											,MAX(RTRIM(ACTNUMST)) ACTNUMST
											,MAX(IIF(B.ORCRDAMT IS NULL,S.CURNCYID,''USD'')) CURNCYID
											,MAX(PSTNGTYP) PSTNGTYP
									FROM  ' + @XEMP +'.dbo.GL30000 S
									INNER JOIN ' + @XEMP +'.dbo.GL00100 C ON C.ACTINDX=S.ACTINDX
									INNER JOIN ' + @XEMP +'.dbo.GL00105 D ON C.ACTINDX=D.ACTINDX
									 LEFT JOIN ' + @XEMP +'.dbo.BAC02000 B ON S.ACTINDX=B.ACTINDX AND B.JRNENTRY=S.JRNENTRY			
									WHERE  1=1 AND S.TRXDATE<=@FECHAFP' + @XEMP +'   
									  and (PERIODID<>0 or S.ACTINDX='+@CTACIERRE+') AND S.JRNENTRY!=(@ASIENTOINICIAL' + @XEMP +')
									 ' + @FILTRO +'
									  GROUP BY HSTYEAR,PERIODID,TRXDATE,S.ACTINDX,CURNCYID;    							
		INSERT INTO TEMPSALDOSF (ANIO,PERIODID,MES,TRXDATE,DEBITAMT,CRDTAMNT,ORDBTAMT,ORCRDAMT,ACTDESCR,ACTNUMST,CURNCYID,PSTNGTYP)
									SELECT   OPENYEAR ANIO									      
											,PERIODID,PERIODID MES
											,S.TRXDATE TRXDATE
											,SUM(S.DEBITAMT) DEBITAMT
											,SUM(S.CRDTAMNT) CRDTAMNT
											,SUM(IIF(RTRIM(CURNCYID)=''USD'',ISNULL(B.ORDBTAMT,S.ORDBTAMT),0)) ORDBTAMT
											,SUM(IIF(RTRIM(CURNCYID)=''USD'',ISNULL(B.ORCRDAMT,S.ORCRDAMT),0)) ORCRDAMT
											,MAX(RTRIM(ACTDESCR)) ACTDESCR
											,MAX(RTRIM(ACTNUMST)) ACTNUMST
											,MAX(IIF(B.ORCRDAMT IS NULL,S.CURNCYID,''USD'')) CURNCYID
											,MAX(PSTNGTYP) PSTNGTYP
									FROM  ' + @XEMP +'.dbo.GL20000 S
									INNER JOIN ' + @XEMP +'.dbo.GL00100 C ON C.ACTINDX=S.ACTINDX
									INNER JOIN ' + @XEMP +'.dbo.GL00105 D ON C.ACTINDX=D.ACTINDX
									 LEFT JOIN ' + @XEMP +'.dbo.BAC02000 B ON S.ACTINDX=B.ACTINDX AND B.JRNENTRY=S.JRNENTRY			
									WHERE  1=1 AND S.TRXDATE<=@FECHAFP' + @XEMP +'   
									  and (PERIODID<>0 or S.ACTINDX='+@CTACIERRE+')
									 ' + @FILTRO +'
									  GROUP BY OPENYEAR,PERIODID,TRXDATE,S.ACTINDX,CURNCYID;   
		INSERT INTO TEMPSALDOSF (ANIO,PERIODID,MES,TRXDATE,DEBITAMT,CRDTAMNT,ORDBTAMT,ORCRDAMT,ACTDESCR,ACTNUMST,CURNCYID,PSTNGTYP)
									SELECT   @ANIO ANIO									      
											,12 PERIODID,05 MES
											,CONCAT (@ANIO,''0501'') TRXDATE
											,0.00 DEBITAMT
											,0.00 CRDTAMNT
											,0.00 ORDBTAMT
											,0.00 ORCRDAMT
											,C.ACTDESCR
											,D.ACTNUMST
											,''USD''    CURNCYID
											,PSTNGTYP
										FROM  ' + @XEMP +'.dbo.GL00100 C
										INNER JOIN ' + @XEMP +'.dbo.GL00105 D ON C.ACTINDX=D.ACTINDX
										WHERE  1=1  ' + @FILTRO + ' AND D.ACTNUMST NOT IN (SELECT ACTNUMST FROM TEMPSALDOSF); '
												
			FETCH NEXT FROM EMPRESAS INTO @XEMP  
		END   
	CLOSE EMPRESAS;  
	DEALLOCATE EMPRESAS;

	SET @Parametro = N'@FINPERIODO DATE,@ANIO int,@PERIODID INT';  
 PRINT @SQLSTR 
EXECUTE sp_executesql @SQLSTR, @Parametro,  
                      @FINPERIODO = @FINPERIODO,@ANIO = @ANIO,@PERIODID=@MES; 

END

/*
			SET @SQLSTR=@SQLSTR+'INSERT INTO TEMPSALDOSF (ANIO,PERIODID,MES,TRXDATE,DEBITAMT,CRDTAMNT,ORDBTAMT,ORCRDAMT,ACTDESCR,ACTNUMST,CURNCYID,PSTNGTYP)
									SELECT ISNULL(HSTYEAR,@ANIO) ANIO									      
									      ,ISNULL(PERIODID,12) PERIODID,ISNULL(MONTH(S.TRXDATE),5) MES
									      ,ISNULL(S.TRXDATE,EOMONTH(CONCAT(@ANIO,''0501''))) TRXDATE
										  ,ISNULL(SUM(S.DEBITAMT),0) DEBITAMT
										  ,ISNULL(SUM(S.CRDTAMNT),0) CRDTAMNT
										  ,ISNULL(SUM(IIF(RTRIM(CURNCYID)=''USD'',S.ORDBTAMT,0)),0) ORDBTAMT
										  ,ISNULL(SUM(IIF(RTRIM(CURNCYID)=''USD'',S.ORCRDAMT,0)),0) ORCRDAMT
										  ,MAX(RTRIM(ACTDESCR)) ACTDESCR
										  ,MAX(RTRIM(ACTNUMST)) ACTNUMST
										  ,CURNCYID
										  ,max(PSTNGTYP) PSTNGTYP
									 FROM ' + @XEMP +'.dbo.GL00100 C 
									  INNER JOIN ' + @XEMP +'.dbo.GL00105 D ON C.ACTINDX=D.ACTINDX
									  LEFT JOIN ( SELECT S.TRXDATE,S.HSTYEAR,S.DEBITAMT,S.CRDTAMNT' --para el caso de la revalorizacion de activos
												+' ,IIF(B.ORCRDAMT IS NULL,S.CURNCYID,''USD'') CURNCYID 
												 ,S.ACTINDX,S.PERIODID
												 ,ISNULL(B.ORDBTAMT,S.ORDBTAMT)	ORDBTAMT
												 ,ISNULL(B.ORCRDAMT,S.ORCRDAMT)	ORCRDAMT
												 ,S.JRNENTRY
											 FROM ' + @XEMP +'.dbo.GL30000 S
										   LEFT JOIN ' + @XEMP +'.dbo.BAC02000 B ON S.ACTINDX=B.ACTINDX AND B.JRNENTRY=S.JRNENTRY
										   ) S ON C.ACTINDX=S.ACTINDX 
										    AND S.HSTYEAR<=@ANIO AND S.PERIODID<=@PERIODID   --S.TRXDATE<=@FINPERIODO
											 and (PERIODID<>0 or S.ACTINDX='+@CTACIERRE+') --a�o solicitado y anterior
											AND S.JRNENTRY NOT IN (SELECT TOP 1 JRNENTRY FROM GL30000 WHERE PERIODID=0 ORDER BY TRXDATE)
									 WHERE  1=1 ' + @FILTRO +
									 ' GROUP BY HSTYEAR,PERIODID,TRXDATE,S.ACTINDX,CURNCYID ;								
							INSERT INTO TEMPSALDOSF (ANIO,PERIODID,MES,TRXDATE,DEBITAMT,CRDTAMNT,ORDBTAMT,ORCRDAMT,ACTDESCR,ACTNUMST,CURNCYID,PSTNGTYP)
									SELECT ISNULL(OPENYEAR,@ANIO) ANIO
									      ,ISNULL(PERIODID,12) PERIODID,ISNULL(MONTH(S.TRXDATE),5) MES
									      ,ISNULL(S.TRXDATE,EOMONTH(CONCAT(@ANIO,''0501''))) TRXDATE
										  ,ISNULL(SUM(S.DEBITAMT),0) DEBITAMT
										  ,ISNULL(SUM(S.CRDTAMNT),0) CRDTAMNT
										  ,ISNULL(SUM(IIF(RTRIM(CURNCYID)=''USD'',S.ORDBTAMT,0)),0) ORDBTAMT
										  ,ISNULL(SUM(IIF(RTRIM(CURNCYID)=''USD'',S.ORCRDAMT,0)),0) ORCRDAMT
										  ,MAX(RTRIM(ACTDESCR)) ACTDESCR
										  ,MAX(ACTNUMST) ACTNUMST
										  ,CURNCYID
										  ,max(PSTNGTYP) PSTNGTYP
									  FROM ' + @XEMP +'.dbo.GL00100 C 
									  INNER JOIN ' + @XEMP +'.dbo.GL00105 D ON C.ACTINDX=D.ACTINDX
									  LEFT JOIN ( SELECT S.TRXDATE,S.OPENYEAR,S.DEBITAMT,S.CRDTAMNT' --para el caso de la revalorizacion de activos
												+' ,IIF(B.ORCRDAMT IS NULL,S.CURNCYID,''USD'') CURNCYID 
												 ,S.ACTINDX,S.PERIODID
												 ,ISNULL(B.ORDBTAMT,S.ORDBTAMT)	ORDBTAMT
												 ,ISNULL(B.ORCRDAMT,S.ORCRDAMT)	ORCRDAMT
												 ,S.JRNENTRY
											 FROM ' + @XEMP +'.dbo.GL20000 S
										   LEFT JOIN ' + @XEMP +'.dbo.BAC02000 B ON S.ACTINDX=B.ACTINDX AND B.JRNENTRY=S.JRNENTRY
										   ) S ON C.ACTINDX=S.ACTINDX 
									     AND S.OPENYEAR<=@ANIO AND S.PERIODID<=@PERIODID   --S.TRXDATE<=@FINPERIODO
											  and (PERIODID<>0 or S.ACTINDX='+@CTACIERRE+')'+
											--'AND OPENYEAR<='	+ CONVERT(CHAR(6),@ANIO) +
										'WHERE 1=1 ' + @FILTRO +' 	
										GROUP BY OPENYEAR,PERIODID,TRXDATE,S.ACTINDX,CURNCYID;'	
*/