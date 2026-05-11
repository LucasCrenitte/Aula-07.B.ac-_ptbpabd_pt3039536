 CREATE PROCEDURE dbo.salaryHistogram
    @numIntervalos INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validação básica
    IF @numIntervalos IS NULL OR @numIntervalos <= 0
    BEGIN
        RAISERROR('O número de intervalos deve ser um inteiro positivo.', 16, 1);
        RETURN;
    END

    DECLARE 
        @minSalary NUMERIC(18,2),
        @maxSalary NUMERIC(18,2),
        @intervalo NUMERIC(18,6);

    -- Menor e maior salário
    SELECT
        @minSalary = MIN(salary),
        @maxSalary = MAX(salary)
    FROM instructor;

    -- Se não houver dados, retorna vazio
    IF @minSalary IS NULL OR @maxSalary IS NULL
    BEGIN
        SELECT CAST(0 AS INT) AS valorMinimo, CAST(0 AS INT) AS valorMaximo, 0 AS total
        WHERE 1 = 0; -- retorna esquema vazio
        RETURN;
    END

    -- Quando todos os salários são iguais, criar um intervalo de tamanho 1 para evitar divisão por zero
    IF @maxSalary = @minSalary
    BEGIN
        SET @intervalo = 1;
    END
    ELSE
    BEGIN
        SET @intervalo = (@maxSalary - @minSalary) / @numIntervalos;
    END

    -- CTE recursiva para gerar faixas de 0 até @numIntervalos - 1
    ;WITH Faixas AS
    (
        SELECT 0 AS faixa
        UNION ALL
        SELECT faixa + 1 FROM Faixas WHERE faixa + 1 < @numIntervalos
    ),
    -- Associação dos salários às faixas
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
    -- Contagem por faixa (inclui faixas sem registros via LEFT JOIN)
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
        -- limite mínimo arredondado para baixo como inteiro
        CAST(FLOOR(@minSalary + (c.faixa * @intervalo)) AS INT) AS valorMinimo,

        -- limite máximo: para a última faixa usar o salário máximo, senão arredondar o limite superior - 1
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
-- EXEC dbo.salaryHistogram 5;

