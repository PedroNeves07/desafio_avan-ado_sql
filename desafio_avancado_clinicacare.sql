-- ===================================================================
-- DESAFIO AVANÇADO — CLINICACARE
-- ===================================================================
--
-- 1) CENÁRIO DE NEGÓCIO
-- "Qual médico é o maior faturador dentro de cada especialidade, e como
--  podemos classificar automaticamente seu nível de desempenho
--  financeiro (Alto / Médio / Baixo)?"
--
-- Essa pergunta ajuda a clínica a identificar, especialidade por
-- especialidade, quem é o profissional de referência em faturamento
-- e a sinalizar rapidamente médicos com desempenho abaixo do esperado.
--
-- 2) TÉCNICAS COMBINADAS NESTA ÚNICA CONSULTA:
--    - CTE (WITH)                -> faturamento_medico
--    - CASE WHEN                 -> classificacao_desempenho
--    - Função de janela          -> RANK() OVER (PARTITION BY ...)
--    - Sugestão de índice        -> ao final do arquivo
-- ===================================================================

WITH faturamento_medico AS (
    SELECT
        m.id_medico,
        m.nome_completo         AS medico,
        e.id_especialidade,
        e.nome_especialidade,
        COUNT(c.id_consulta)    AS total_consultas,
        SUM(c.valor_consulta)   AS faturamento_total
    FROM consultas c
    INNER JOIN medicos m        ON c.id_medico = m.id_medico
    INNER JOIN especialidades e ON c.id_especialidade = e.id_especialidade
    WHERE c.status_consulta = 'Realizada'
    GROUP BY m.id_medico, m.nome_completo, e.id_especialidade, e.nome_especialidade
)
SELECT
    nome_especialidade,
    medico,
    total_consultas,
    faturamento_total,
    RANK() OVER (
        PARTITION BY id_especialidade
        ORDER BY faturamento_total DESC
    ) AS ranking_na_especialidade,
    CASE
        WHEN faturamento_total >= 300 THEN 'Alto Desempenho'
        WHEN faturamento_total >= 150 THEN 'Médio Desempenho'
        ELSE 'Baixo Desempenho'
    END AS classificacao_desempenho
FROM faturamento_medico
ORDER BY nome_especialidade, ranking_na_especialidade;

-- ===================================================================
-- 3) SUGESTÃO DE ÍNDICE PARA OTIMIZAÇÃO
--
-- A CTE filtra por status_consulta = 'Realizada' e agrupa por
-- id_medico / id_especialidade. Sem índice, o MySQL faz um full scan
-- de "consultas" e depois agrupa em memória/disco. Um índice composto
-- cobrindo o filtro (status_consulta) e as colunas usadas nos JOINs/
-- GROUP BY (id_medico, id_especialidade) evita esse scan completo e
-- acelera tanto a filtragem quanto a agregação:
-- ===================================================================
CREATE INDEX idx_consultas_status_medico_especialidade
    ON consultas (status_consulta, id_medico, id_especialidade);
