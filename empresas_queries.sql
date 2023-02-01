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
JOIN populacao_UF ON A.uf = populacao_UF.uf
)
SELECT * FROM B
UNION ALL SELECT 'Brasil', 'BR', sum(total_empresas), sum(total_socios), sum(populacao), (CAST(sum(total_socios) AS REAL)/CAST(sum(populacao) AS REAL)) FROM B





-- Rascunhos
-- Histograma capital social de empresas ativas

with bins as (
	SELECT
		CAST(empresa.capital_social/100000 as INT)*100000 as bin_floor,
		count(empresa.cnpj) as bin_total
	FROM empresa
	WHERE empresa.identificador_matriz_filial = 1 AND empresa.situacao_cadastral = 2
	GROUP BY 1
	ORDER BY 1
)

SELECT 
	bin_floor,
	bin_floor || ' - ' || (bin_floor + 100000) as bin_range,
	bin_total
FROM bins
ORDER BY 1;