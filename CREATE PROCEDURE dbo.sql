CREATE PROCEDURE dbo.salaryHistogram
    @numIntervalos INT
AS
BEGIN
    SET NOCOUNT ON;

   
    IF @numIntervalos IS NULL OR @numIntervalos <= 0
    BEGIN
        RAISERROR('O número de intervalos deve ser um inteiro positivo.', 16, 1);
        RETURN;
    END

    DECLARE 
        @minSalary NUMERIC(18,2),
        @maxSalary NUMERIC(18,2),
        @intervalo NUMERIC(18,6);

    
    SELECT
        @minSalary = MIN(salary),
        @maxSalary = MAX(salary)
    FROM instructor;

    
    IF @minSalary IS NULL OR @maxSalary IS NULL
    BEGIN
        SELECT CAST(0 AS INT) AS valorMinimo, CAST(0 AS INT) AS valorMaximo, 0 AS total
        WHERE 1 = 0; -- retorna esquema vazio
        RETURN;
    END

    
    IF @maxSalary = @minSalary
    BEGIN
        SET @intervalo = 1;
    END
    ELSE
    BEGIN
        SET @intervalo = (@maxSalary - @minSalary) / @numIntervalos;
    END

   
    ;WITH Faixas AS
    (
        SELECT 0 AS faixa
        UNION ALL
        SELECT faixa + 1 FROM Faixas WHERE faixa + 1 < @numIntervalos
    ),

    Histograma AS
    (
        SELECT
            salary,
            CASE
                WHEN salary = @maxSalary THEN @numIntervalos - 1
                ELSE CAST(FLOOR((salary - @minSalary) / NULLIF(@intervalo,0)) AS INT)
            END AS faixa
        FROM instructor
    ),
    
    Contagens AS
    (
        SELECT
            f.faixa,
            COUNT(h.salary) AS total
        FROM Faixas f
        LEFT JOIN Histograma h ON h.faixa = f.faixa
        GROUP BY f.faixa
    )

    SELECT
        
        CAST(FLOOR(@minSalary + (c.faixa * @intervalo)) AS INT) AS valorMinimo,

        
        CAST(
            CASE
                WHEN c.faixa = @numIntervalos - 1 THEN CEILING(@maxSalary)
                ELSE FLOOR(@minSalary + ((c.faixa + 1) * @intervalo)) - 1
            END
        AS INT) AS valorMaximo,

        c.total
    FROM Contagens c
    ORDER BY c.faixa

    OPTION (MAXRECURSION 0);

END;
GO

-- Exemplo de chamada:
EXEC dbo.salaryHistogram 5;
