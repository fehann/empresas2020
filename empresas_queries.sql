-- Sheet1: Sócios, pessoa jurídica, com mais empresas ativas
SELECT socio.cnpj_cpf_do_socio, socio.nome_socio, count(empresa.cnpj) AS totalempresas, min(socio.data_entrada_sociedade) AS primeira_sociedade FROM empresa
JOIN socio ON empresa.cnpj = socio.cnpj
WHERE empresa.identificador_matriz_filial = 1 AND empresa.situacao_cadastral = 2 AND socio.identificador_de_socio = 2
GROUP BY socio.cnpj_cpf_do_socio, socio.nome_socio
ORDER BY count(empresa.cnpj) DESC
LIMIT 100;


-- Sheet2: Número de empresas por natureza jurídica com a média de sócios

SELECT natureza_juridica.Codigo, natureza_juridica.Natureza_Juridica, count(*) AS Total_empresas, avg(A.Total_socios) AS Media_socios
FROM natureza_juridica
JOIN (SELECT empresa.codigo_natureza_juridica, empresa.cnpj, count(socio.cnpj_cpf_do_socio) AS Total_socios FROM empresa
JOIN socio ON empresa.cnpj = socio.cnpj
WHERE empresa.identificador_matriz_filial = 1 AND empresa.situacao_cadastral = 2
GROUP BY empresa.codigo_natureza_juridica, empresa.cnpj
ORDER BY empresa.codigo_natureza_juridica, empresa.cnpj) AS A
ON natureza_juridica.Codigo = A.codigo_natureza_juridica
GROUP BY natureza_juridica.Codigo, natureza_juridica.Natureza_Juridica
ORDER BY count(*) DESC

-- Sheet3: Socios per capita por Estado incluindo Brasil 
WITH A AS (
SELECT empresa.uf, count(DISTINCT empresa.cnpj) AS total_empresas, count(*) AS total_socios FROM empresa
JOIN socio ON empresa.cnpj = socio.cnpj
WHERE empresa.identificador_matriz_filial = 1 AND empresa.situacao_cadastral = 2
GROUP BY empresa.uf
),
B AS(
SELECT populacao_UF.cod_uf, populacao_UF.uf, A.total_empresas, A.total_socios, populacao_UF.populacao, CAST(A.total_socios AS REAL)/CAST(populacao_UF.populacao AS REAL) AS socios_per_capita 
FROM A
JOIN populacao_UF ON A.uf = populacao_UF.cod_uf
)
SELECT * FROM B
UNION
SELECT 'BR', 'Brasil', sum(total_empresas), sum(total_socios), sum(populacao), (CAST(sum(total_socios) AS REAL)/CAST(sum(populacao) AS REAL)) FROM B


-- Sheet4: Top 10 Municipios com Maior Sócios per Capita por Estado
WITH A AS (
SELECT empresa.codigo_municipio, count(*) AS total_socios FROM empresa
JOIN socio ON empresa.cnpj = socio.cnpj
WHERE empresa.identificador_matriz_filial = 1 AND empresa.situacao_cadastral = 2
GROUP BY empresa.codigo_municipio
),
B AS (
SELECT populacao_municipios.uf, municipio.id_municipio, municipio.nome, A.total_socios, populacao_municipios.populacao, (CAST(A.total_socios AS REAL)/CAST(populacao_municipios.populacao AS REAL)) AS socios_per_capita FROM A
JOIN municipio ON A.codigo_municipio = municipio.id_municipio_rf
JOIN populacao_municipios ON municipio.id_municipio = populacao_municipios.cod_uf_municipio
)
SELECT * FROM (SELECT uf, id_municipio, nome, total_socios, populacao, socios_per_capita, rank() OVER(PARTITION BY uf ORDER BY socios_per_capita DESC) AS municipio_rank
FROM B)
WHERE municipio_rank <= 10


-- Sheet5: 

-- Ver número de observações acima do 3o quartil, porém ainda são muitos, em torno do 5 milhões para ativas e baixadas
SELECT situacao_cadastral, count(*) AS total, count(*) * 0.75 AS q_three
FROM empresa
WHERE empresa.identificador_matriz_filial = 1 AND empresa.situacao_cadastral IN (2,8)
GROUP BY situacao_cadastral

-- Ver somente as 5 mil empresas mais antigas das ativas e baixadas
WITH A AS (
SELECT cnpj, situacao_cadastral, data_inicio_atividade,
	CASE 
		WHEN situacao_cadastral = 2 THEN '2020-09-20'
		ELSE data_situacao_cadastral
	END AS limite_atividade
FROM empresa
WHERE empresa.identificador_matriz_filial = 1 AND empresa.situacao_cadastral IN (2,8)
),
B AS (
SELECT cnpj, situacao_cadastral, data_inicio_atividade, limite_atividade, (julianday(limite_atividade) - julianday(data_inicio_atividade))/365 AS duracao_anos
FROM A
)
SELECT * FROM (SELECT cnpj, situacao_cadastral, data_inicio_atividade, limite_atividade, duracao_anos, row_number() OVER(PARTITION BY situacao_cadastral ORDER BY duracao_anos DESC) AS row_n
FROM B)
WHERE row_n <= 5000

-- Verificar as empresas anteriores a 1900
SELECT * FROM empresa
WHERE cnpj IN (116000120, 11461683000109, 1372826000144, 18825426000140, 96537196000127)
-- Encontrado um erro na data de abertura da empresa, o restante está OK, realmente há 4 empresas abertas antes de 1900
		
	