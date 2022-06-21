--funcion:trae el valor de la tasa mas cercano a la fecha dada.
--=============================================
--SELECT  dbo.f_fechafactura('20200417','NC FC01-00000163')
--RAFAEL NIÑO

IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'Split')
	DROP FUNCTION Split
GO

CREATE FUNCTION Split
 (@String nvarchar (4000), @Delimitador nvarchar (10)) 
 returns @ValueTable table ([Value] nvarchar(4000))
begin
 declare @NextString nvarchar(4000)
 declare @Pos int
 declare @NextPos int
 declare @CommaCheck nvarchar(1)
  
 --Inicializa
 set @NextString = ''
 set @CommaCheck = right(@String,1) 
  
 set @String = @String + @Delimitador
  
 --Busca la posición del primer delimitador
 set @Pos = charindex(@Delimitador,@String)
 set @NextPos = 1
  
 --Itera mientras exista un delimitador en el string
 while (@pos <> 0)  
 begin
  set @NextString = substring(@String,1,@Pos - 1)
  
  insert into @ValueTable ( [Value]) Values (@NextString)
  
  set @String = substring(@String,@pos +1,len(@String))
   
  set @NextPos = @Pos
  set @pos  = charindex(@Delimitador,@String)
 end
  
 return
end 