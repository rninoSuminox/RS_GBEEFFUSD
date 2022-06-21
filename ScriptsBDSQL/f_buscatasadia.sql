--funcion:trae el valor de la tasa mas cercano a la fecha dada.
--=============================================
--SELECT  dbo.f_buscatasadia('20200417','USD-VEN-DIA')

IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'f_buscatasadia')
	DROP FUNCTION f_buscatasadia
GO

CREATE FUNCTION f_buscatasadia
	(@DOCDATE datetime
	,@EXGTBLID nvarchar(25)
    )
RETURNS numeric(18,7)
AS
BEGIN
   declare @tasa numeric(18,7)

   	    SELECT TOP 1 @tasa=XCHGRATE
		  FROM DYNAMICS.dbo.MC00100 
		 WHERE EXGTBLID=@EXGTBLID AND EXCHDATE<=@DOCDATE 
		 ORDER BY EXCHDATE DESC,TIME1 DESC

	RETURN @tasa
END
GO
