/*
exec pr_periodosEEFF_USD @ANIO=2021,@EMPRESA=N'BALBS'
SELECT * FROM TEMPPERIODO
*/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pr_periodosEEFF_USD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].pr_periodosEEFF_USD
 go
CREATE  PROCEDURE pr_periodosEEFF_USD 
(@ANIO		INT
,@EMPRESA   VARCHAR(100))
AS
BEGIN

	DECLARE @SQLSTR    NVARCHAR(MAX)='',@Parametro nvarchar(500)
	DECLARE @XEMP VARCHAR(15)


	--tabla para llenar datos principales
	if exists(select 1 from sys.tables where name='TEMPPERIODO')
		drop table TEMPPERIODO;
		CREATE TABLE TEMPPERIODO (ID 	INT
								,PERIODO	NVARCHAR(6)
								,PERIODDT   DATE)
		CREATE INDEX idx_ID ON TEMPPERIODO (ID)

	--cursor para poder consolidar las empresas
	DECLARE EMPRESAS CURSOR FOR   
	SELECT TOP 1 Value FROM dbo.Split(@EMPRESA,',')  WHERE VALUE<>''
    --BUSCAR E INSERTAR DE CADA EMPRESA
	OPEN EMPRESAS  
	FETCH NEXT FROM EMPRESAS INTO @XEMP   
	WHILE @@FETCH_STATUS = 0  
		BEGIN  
		--select @XEMP
		--SELECT PERIODID,CONCAT(YEAR(PERIODDT),RIGHT(CONCAT(''00'',MONTH(PERIODDT)),2)) PERIODO,PERIODDT	
			SET @SQLSTR=@SQLSTR+'INSERT INTO TEMPPERIODO (ID,PERIODO,PERIODDT)
									SELECT PERIODID,CONCAT(YEAR1,RIGHT(CONCAT(''00'',PERIODID),2)) PERIODO,PERIODDT									
									  FROM ' + @XEMP +'.dbo.SY40100 
									 WHERE YEAR1=@ANIO AND SERIES=0 AND PERIODID>0
									 ORDER BY PERIODDT;'			
			FETCH NEXT FROM EMPRESAS INTO @XEMP  
		END   
	CLOSE EMPRESAS;  
	DEALLOCATE EMPRESAS;

	SET @Parametro = N'@ANIO int';  
 PRINT @SQLSTR 
EXECUTE sp_executesql @SQLSTR, @Parametro,  
                      @ANIO = @ANIO; 

	--select * from TEMPSALDOS;

END