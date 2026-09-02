-- ===================================================================
-- PROJETO CLINICACARE - BANCO DE DADOS
-- SCHEMA: clinica_care | ENGINE: InnoDB | CHARSET: utf8mb4
-- 
-- CRIAÇÃO DO BANCO
DROP SCHEMA IF EXISTS clinica_care;
CREATE SCHEMA clinica_care DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clinica_care;

-- CRIAÇÃO DAS TABELAS

CREATE TABLE convenios ( 
    id_convenio INT AUTO_INCREMENT PRIMARY KEY,
    nome_convenio VARCHAR(100) NOT NULL,
    registro_ans VARCHAR(20) UNIQUE NULL,          -- (4) nullable: Particular não possui ANS
    tipo_cobertura VARCHAR(50) NOT NULL,
    telefone_contato VARCHAR(20) NOT NULL,
    email_contato VARCHAR(100) NOT NULL,
    percentual_desconto DECIMAL(5,2) DEFAULT 0.00,
    status_ativo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_desconto CHECK (percentual_desconto BETWEEN 0.00 AND 100.00)
) ENGINE=InnoDB;

CREATE TABLE pacientes (
    id_paciente INT AUTO_INCREMENT PRIMARY KEY,
    id_convenio INT NOT NULL,
    nome_completo VARCHAR(120) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    data_nascimento DATE NOT NULL,
    genero CHAR(1) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    endereco_completo VARCHAR(255) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pacientes_convenios FOREIGN KEY (id_convenio) REFERENCES convenios(id_convenio) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_genero CHECK (genero IN ('M', 'F', 'O'))
) ENGINE=InnoDB;

CREATE TABLE especialidades (
    id_especialidade INT AUTO_INCREMENT PRIMARY KEY,
    nome_especialidade VARCHAR(80) UNIQUE NOT NULL,
    descricao TEXT NOT NULL,
    valor_base_consulta DECIMAL(10,2) NOT NULL,
    tempo_medio_minutos INT NOT NULL,
    retorno_dias_limite INT DEFAULT 30,
    necessita_preparacao BOOLEAN DEFAULT FALSE,
    status_ativa BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_valor_base CHECK (valor_base_consulta > 0)
) ENGINE=InnoDB;

CREATE TABLE medicos (
    id_medico INT AUTO_INCREMENT PRIMARY KEY,
    nome_completo VARCHAR(120) NOT NULL,
    crm VARCHAR(20) UNIQUE NOT NULL,
    uf_crm CHAR(2) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    data_admissao DATE NOT NULL,
    status_ativo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE medico_especialidades (
    id_medico_especialidade INT AUTO_INCREMENT PRIMARY KEY,
    id_medico INT NOT NULL,
    id_especialidade INT NOT NULL,
    data_vinculo DATE NOT NULL,
    RQE VARCHAR(20) UNIQUE,
    atende_convenio BOOLEAN DEFAULT TRUE,
    valor_consulta_medico DECIMAL(10,2) NOT NULL,
    status_vinculo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_med_esp_medicos FOREIGN KEY (id_medico) REFERENCES medicos(id_medico) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_med_esp_especialidades FOREIGN KEY (id_especialidade) REFERENCES especialidades(id_especialidade) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT unq_medico_especialidade UNIQUE (id_medico, id_especialidade)
) ENGINE=InnoDB;

CREATE TABLE consultas (
    id_consulta INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_medico INT NOT NULL,
    id_especialidade INT NOT NULL,
    data_agendamento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_consulta DATE NOT NULL,
    horario_consulta TIME NOT NULL,
    status_consulta VARCHAR(20) NOT NULL,
    valor_consulta DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_consultas_pacientes FOREIGN KEY (id_paciente) REFERENCES pacientes(id_paciente) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_consultas_medicos FOREIGN KEY (id_medico) REFERENCES medicos(id_medico) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_consultas_especialidades FOREIGN KEY (id_especialidade) REFERENCES especialidades(id_especialidade) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_status_consulta CHECK (status_consulta IN ('Agendada', 'Realizada', 'Cancelada', 'No-Show'))
) ENGINE=InnoDB;

-- (2) prontuarios agora só guarda id_consulta; paciente e médico são
-- obtidos via JOIN com consultas (evita dado duplicado/divergente)
CREATE TABLE prontuarios (
    id_prontuario INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta INT UNIQUE NOT NULL,
    queixa_principal TEXT NOT NULL,
    diagnostico TEXT NOT NULL,
    historico_clinico TEXT,
    observacoes_medicas TEXT,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prontuarios_consultas FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- (1) NOVA TABELA — obrigatória pelo briefing ("armazenar prescrições de medicamentos")
CREATE TABLE prescricoes (
    id_prescricao INT AUTO_INCREMENT PRIMARY KEY,
    id_prontuario INT NOT NULL,
    nome_medicamento VARCHAR(100) NOT NULL,
    dosagem VARCHAR(30) NOT NULL,
    frequencia VARCHAR(50) NOT NULL,
    duracao_tratamento VARCHAR(30) NOT NULL,
    observacoes VARCHAR(255),
    data_prescricao DATE NOT NULL,
    CONSTRAINT fk_prescricoes_prontuarios FOREIGN KEY (id_prontuario) REFERENCES prontuarios(id_prontuario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- (2) pagamentos agora só guarda id_consulta; paciente é obtido via JOIN
CREATE TABLE pagamentos (
    id_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta INT UNIQUE NOT NULL,
    valor_pago DECIMAL(10,2) NOT NULL,
    data_pagamento DATETIME,
    metodo_pagamento VARCHAR(30) NOT NULL,
    status_pagamento VARCHAR(20) NOT NULL,
    numero_recibo VARCHAR(50) UNIQUE,
    CONSTRAINT fk_pagamentos_consultas FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_metodo CHECK (metodo_pagamento IN ('Dinheiro', 'Cartao_Credito', 'Cartao_Debito', 'Pix', 'Convenio')),
    CONSTRAINT chk_status_pagamento CHECK (status_pagamento IN ('Pago', 'Pendente', 'Cancelado'))
) ENGINE=InnoDB;


-- INSERÇÃO DOS DADOS

INSERT INTO convenios (nome_convenio, registro_ans, tipo_cobertura, telefone_contato, email_contato, percentual_desconto, status_ativo) VALUES
('Particular', NULL, 'Nenhuma', '(83) 3000-0000', 'atendimento@clinicacare.com.br', 0.00, TRUE),
('Unimed JP', '312456', 'Nacional Amplo', '(83) 3216-8000', 'contato@unimedjp.com.br', 20.00, TRUE),
('Hapvida', '418920', 'Regional Preferencial', '(83) 4002-2820', 'atendimento@hapvida.com.br', 30.00, TRUE),
('Bradesco Saude', '005711', 'Nacional Top', '(83) 3003-1000', 'suporte@bradescosaude.com.br', 15.00, TRUE),
('Amil Saude', '326305', 'Nacional S450', '(83) 3004-1000', 'corporativo@amil.com.br', 15.00, TRUE),
('SulAmerica', '006246', 'Executivo', '(83) 4004-4400', 'contato@sulamerica.com.br', 10.00, TRUE),
('Cassi', '346659', 'Funcional', '(83) 3218-1200', 'atendimento@cassi.com.br', 25.00, TRUE),
('Geap', '002437', 'Saude I', '(83) 3214-3000', 'faleconosco@geap.com.br', 25.00, TRUE),
('Postal Saude', '419110', 'Avançado', '(83) 3216-5000', 'contato@postalsaude.com.br', 20.00, TRUE),
('Capesesp', '302198', 'Plena', '(83) 3222-1000', 'atendimento@capesesp.com.br', 20.00, TRUE),
('Assefaz', '350021', 'Diamante', '(83) 3241-2000', 'convenio@assefaz.com.br', 15.00, TRUE),
('Medial Saude', '339911', 'Basico', '(83) 3000-1122', 'contato@medial.com.br', 35.00, FALSE),
('Golden Cross', '003211', 'Master', '(83) 4002-1111', 'atendimento@goldencross.com.br', 20.00, TRUE),
('Notredame Intermédica', '417891', 'Smart 500', '(83) 4003-2200', 'suporte@gndi.com.br', 25.00, TRUE),
('Allianz Saude', '001290', 'Qualite', '(83) 3003-3333', 'atendimento@allianz.com.br', 10.00, TRUE);

INSERT INTO pacientes (id_convenio, nome_completo, cpf, data_nascimento, genero, telefone, email, endereco_completo) VALUES
(1, 'Lucas Silva Ramos', '111.222.333-01', '1988-04-12', 'M', '(83) 98888-1001', 'lucas.ramos@email.com', 'Av. Epitacio Pessoa, 1200, Tambau, João Pessoa - PB'),
(2, 'Maria Alice Fernandes', '222.333.444-02', '1995-08-25', 'F', '(83) 98777-2002', 'maria.fernandes@email.com', 'Rua Empresario João Rodrigues, 45, Manaíra, João Pessoa - PB'),
(3, 'João Pedro Cavalcanti', '333.444.555-03', '1972-11-03', 'M', '(83) 98666-3003', 'joao.cavalcanti@email.com', 'Rua Coração de Jesus, 210, Centro, João Pessoa - PB'),
(2, 'Ana Clara Barbosa', '444.555.666-04', '2001-01-15', 'F', '(83) 98555-4004', 'ana.barbosa@email.com', 'Av. Cabo Branco, 3000, Cabo Branco, João Pessoa - PB'),
(4, 'Carlos Eduardo Lima', '555.666.777-05', '1965-06-30', 'M', '(83) 98444-5005', 'carlos.lima@email.com', 'Rua Miriam Barreto, 88, Bessa, João Pessoa - PB'),
(1, 'Beatriz Souza Melo', '666.777.888-06', '1992-09-18', 'F', '(83) 98333-6006', 'beatriz.melo@email.com', 'Rua Bancario Sergio Guerra, 500, Bancários, João Pessoa - PB'),
(5, 'Gabriel Lucena Costa', '777.888.999-07', '1983-12-05', 'M', '(83) 98222-7007', 'gabriel.costa@email.com', 'Av. Flamboyant, 102, Altiplano, João Pessoa - PB'),
(3, 'Juliana Paes Santos', '888.999.000-08', '1999-03-22', 'F', '(83) 98111-8008', 'juliana.santos@email.com', 'Rua Maciel Pinheiro, 31, Varadouro, João Pessoa - PB'),
(6, 'Fernando Antonio Rocha', '999.000.111-09', '1958-07-14', 'M', '(83) 99911-9009', 'fernando.rocha@email.com', 'Rua Josefa Taveira, 120, Mangabeira, João Pessoa - PB'),
(2, 'Camila Ribeiro Alencar', '000.111.222-10', '2005-10-10', 'F', '(83) 99922-1010', 'camila.alencar@email.com', 'Av. Esperança, 410, Manaíra, João Pessoa - PB'),
(7, 'Rafael Bezerra Nunes', '123.456.789-11', '1990-02-28', 'M', '(83) 99933-1111', 'rafael.nunes@email.com', 'Rua Amazonas, 75, Estados, João Pessoa - PB'),
(1, 'Patricia Xavier Gondim', '234.567.890-12', '1981-05-19', 'F', '(83) 99944-1212', 'patricia.gondim@email.com', 'Rua das Trincheiras, 300, Jaguaribe, João Pessoa - PB'),
(8, 'Thiago Henrique Neves', '345.678.901-13', '1979-09-08', 'M', '(83) 99955-1313', 'thiago.neves@email.com', 'Rua Walfredo Macedo, 90, Jardim Luna, João Pessoa - PB'),
(4, 'Leticia Maria Farias', '456.789.012-14', '1997-12-30', 'F', '(83) 99966-1414', 'leticia.farias@email.com', 'Av. Argemiro de Figueiredo, 1500, Bessa, João Pessoa - PB'),
(2, 'Roberto Carlos Freire', '567.890.123-15', '1960-04-05', 'M', '(83) 99977-1515', 'roberto.freire@email.com', 'Rua Major Célio de Figueiredo, 55, Aeroclube, João Pessoa - PB');

INSERT INTO especialidades (nome_especialidade, descricao, valor_base_consulta, tempo_medio_minutos, retorno_dias_limite, necessita_preparacao, status_ativa) VALUES
('Cardiologia', 'Atendimento cardiovascular completo e eletrocardiograma', 300.00, 40, 30, FALSE, TRUE),
('Dermatologia', 'Avaliação de pele, mucosas, cabelo e unhas', 250.00, 30, 30, FALSE, TRUE),
('Pediatria', 'Acompanhamento do desenvolvimento infantil e vacinação', 220.00, 40, 15, FALSE, TRUE),
('Ortopedia', 'Tratamento de lesões ósseas e articulares', 280.00, 30, 20, FALSE, TRUE),
('Ginecologia', 'Saúde da mulher e exames preventivos', 260.00, 45, 30, TRUE, TRUE),
('Endocrinologia', 'Tratamento metabólico e hormonal', 290.00, 30, 30, TRUE, TRUE),
('Neurologia', 'Diagnóstico e tratamento de distúrbios do sistema nervoso', 350.00, 50, 30, FALSE, TRUE),
('Oftalmologia', 'Exames de vista e saúde ocular', 240.00, 30, 30, FALSE, TRUE),
('Psiquiatria', 'Saúde mental e acompanhamento psicoterapêutico', 320.00, 50, 15, FALSE, TRUE),
('Gastroenterologia', 'Doenças do aparelho digestivo', 270.00, 30, 30, TRUE, TRUE),
('Otorrinolaringologia', 'Tratamento de ouvido, nariz e garganta', 230.00, 30, 30, FALSE, TRUE),
('Urologia', 'Exames do trato urinário e sistema reprodutor masculino', 280.00, 30, 30, TRUE, TRUE),
('Nutrição', 'Acompanhamento nutricional e reeducação alimentar', 180.00, 45, 30, FALSE, TRUE),
('Fisioterapia', 'Reabilitação física e motora', 150.00, 50, 0, FALSE, TRUE),
('Clinica Geral', 'Consulta e avaliação médica abrangente', 200.00, 30, 15, FALSE, TRUE);

INSERT INTO medicos (nome_completo, crm, uf_crm, telefone, email, data_admissao, status_ativo) VALUES
('Dr. Roberto Alencar', '4521', 'PB', '(83) 97111-0001', 'roberto.alencar@clinicacare.com.br', '2015-03-10', TRUE),
('Dra. Juliana Medeiros', '5890', 'PB', '(83) 97111-0002', 'juliana.medeiros@clinicacare.com.br', '2017-06-15', TRUE),
('Dr. Marcelo Campos', '6123', 'PB', '(83) 97111-0003', 'marcelo.campos@clinicacare.com.br', '2018-01-20', TRUE),
('Dra. Vanessa Dantas', '7412', 'PB', '(83) 97111-0004', 'vanessa.dantas@clinicacare.com.br', '2019-08-01', TRUE),
('Dr. Gustavo Henrique', '8234', 'PB', '(83) 97111-0005', 'gustavo.henrique@clinicacare.com.br', '2020-02-10', TRUE),
('Dra. Patricia Figueiredo', '3910', 'PB', '(83) 97111-0006', 'patricia.figueiredo@clinicacare.com.br', '2012-11-05', TRUE),
('Dr. Andre Luiz Vasconcelos', '9012', 'PB', '(83) 97111-0007', 'andre.vasconcelos@clinicacare.com.br', '2021-04-18', TRUE),
('Dra. Camilla Siqueira', '9543', 'PB', '(83) 97111-0008', 'camilla.siqueira@clinicacare.com.br', '2021-09-01', TRUE),
('Dr. Rodrigo Pessoa', '4122', 'PB', '(83) 97111-0009', 'rodrigo.pessoa@clinicacare.com.br', '2014-05-12', TRUE),
('Dra. Helena Martins', '8812', 'PB', '(83) 97111-0010', 'helena.martins@clinicacare.com.br', '2020-10-25', TRUE),
('Dr. Fabio Nobrega', '6711', 'PB', '(83) 97111-0011', 'fabio.nobrega@clinicacare.com.br', '2018-07-19', TRUE),
('Dra. Renata Guimarães', '7233', 'PB', '(83) 97111-0012', 'renata.guimaraes@clinicacare.com.br', '2019-03-14', TRUE),
('Dr. Lucas Cavalcante', '9910', 'PB', '(83) 97111-0013', 'lucas.cavalcante@clinicacare.com.br', '2022-01-10', TRUE),
('Dra. Sofia Andrade', '10210', 'PB', '(83) 97111-0014', 'sofia.andrade@clinicacare.com.br', '2022-08-01', TRUE),
('Dr. Daniel Meira', '5100', 'PB', '(83) 97111-0015', 'daniel.meira@clinicacare.com.br', '2016-12-01', TRUE);

INSERT INTO medico_especialidades (id_medico, id_especialidade, data_vinculo, RQE, atende_convenio, valor_consulta_medico) VALUES
(1, 1, '2015-03-10', 'RQE-101', TRUE, 300.00),
(2, 2, '2017-06-15', 'RQE-102', TRUE, 250.00),
(3, 3, '2018-01-20', 'RQE-103', TRUE, 220.00),
(4, 4, '2019-08-01', 'RQE-104', TRUE, 280.00),
(5, 5, '2020-02-10', 'RQE-105', TRUE, 260.00),
(6, 6, '2012-11-05', 'RQE-106', TRUE, 290.00),
(7, 7, '2021-04-18', 'RQE-107', FALSE, 350.00),
(8, 8, '2021-09-01', 'RQE-108', TRUE, 240.00),
(9, 9, '2014-05-12', 'RQE-109', FALSE, 320.00),
(10, 10, '2020-10-25', 'RQE-110', TRUE, 270.00),
(11, 11, '2018-07-19', 'RQE-111', TRUE, 230.00),
(12, 12, '2019-03-14', 'RQE-112', TRUE, 280.00),
(13, 13, '2022-01-10', 'RQE-113', TRUE, 180.00),
(14, 14, '2022-08-01', 'RQE-114', TRUE, 150.00),
(15, 15, '2016-12-01', 'RQE-115', TRUE, 200.00);

INSERT INTO consultas (id_paciente, id_medico, id_especialidade, data_agendamento, data_consulta, horario_consulta, status_consulta, valor_consulta) VALUES
(1, 1, 1, '2026-01-02 09:00:00', '2026-01-10', '10:00:00', 'Realizada', 300.00),
(2, 2, 2, '2026-01-03 10:30:00', '2026-01-12', '14:00:00', 'Realizada', 200.00),
(3, 3, 3, '2026-01-01 14:00:00', '2026-01-15', '09:00:00', 'No-Show', 154.00),
(4, 4, 4, '2026-01-05 11:00:00', '2026-01-18', '11:00:00', 'Realizada', 224.00),
(5, 5, 5, '2026-01-08 15:20:00', '2026-01-20', '15:00:00', 'Realizada', 221.00),
(6, 6, 6, '2026-01-02 08:00:00', '2026-01-22', '08:30:00', 'No-Show', 290.00),
(7, 7, 7, '2026-01-10 16:40:00', '2026-01-25', '16:00:00', 'Realizada', 297.50),
(8, 8, 8, '2026-01-12 13:00:00', '2026-01-28', '10:30:00', 'Cancelada', 168.00),
(9, 9, 9, '2026-01-20 09:15:00', '2026-02-05', '14:30:00', 'Realizada', 288.00),
(10, 10, 10, '2026-01-22 10:00:00', '2026-02-10', '09:30:00', 'Realizada', 216.00),
(11, 11, 11, '2026-01-25 14:10:00', '2026-02-12', '11:30:00', 'No-Show', 172.50),
(12, 12, 12, '2026-02-01 11:30:00', '2026-02-15', '15:30:00', 'Realizada', 280.00),
(13, 13, 13, '2026-02-02 16:00:00', '2026-02-18', '16:30:00', 'Realizada', 135.00),
(14, 14, 14, '2026-02-05 08:30:00', '2026-02-20', '08:00:00', 'Realizada', 127.50),
(15, 15, 15, '2026-02-08 10:00:00', '2026-02-22', '10:00:00', 'Realizada', 160.00),
-- Consulta 16 (extra): garante que a tabela "prontuarios" também atinja
-- o mínimo de 12 registros exigido pelo PDF (só consulta 'Realizada' gera prontuário)
(6, 15, 15, '2026-02-01 09:00:00', '2026-02-24', '09:00:00', 'Realizada', 200.00);

-- Prontuários associados estritamente a consultas 'Realizada'
-- (id_paciente/id_medico não são mais gravados aqui — ver correção 2)
-- id_prontuario gerado: 1→consulta1, 2→consulta2, 3→consulta4, 4→consulta5,
-- 5→consulta7, 6→consulta9, 7→consulta10, 8→consulta12, 9→consulta13,
-- 10→consulta14, 11→consulta15, 12→consulta16
INSERT INTO prontuarios (id_consulta, queixa_principal, diagnostico, historico_clinico, observacoes_medicas) VALUES
(1, 'Dor no peito ao caminhar', 'Hipertensão Arterial Estágio 1', 'Paciente sedentário, sem histórico prévio', 'Prescrito anti-hipertensivo e retorno em 30 dias.'),
(2, 'Manchas vermelhas no braço', 'Dermatite de Contato', 'Alergia a sabão em pó relatada', 'Orientado a suspender produto e aplicar pomada.'),
(4, 'Dor no joelho direito após corrida', 'Tendinite Patelar', 'Praticante de corrida de rua', 'Encaminhado para fisioterapia e repouso.'),
(5, 'Check-up preventivo anual', 'Exames sem alterações significativas', 'Rotina anual', 'Solicitado ultrassom e exames de sangue.'),
(7, 'Enxaqueca frequente há 2 meses', 'Enxaqueca Crônica', 'Histórico familiar positivo', 'Iniciado tratamento profilático.'),
(9, 'Ansiedade e insônia', 'Transtorno de Ansiedade Generalizada', 'Estresse no trabalho', 'Encaminhado para terapia e medicação leve.'),
(10, 'Azia constante e refluxo', 'Gastrite Moderada', 'Uso frequente de anti-inflamatórios', 'Solicitada endoscopia digestiva alta.'),
(12, 'Dificuldade para urinar', 'Hiperplasia Prostática Benigna', 'Acompanhamento prévio regular', 'Iniciado tratamento medicamentoso.'),
(13, 'Acompanhamento para perda de peso', 'Sobrepeso Grau 1', 'Dieta desregrada', 'Plano alimentar personalizado montado.'),
(14, 'Dor lombar aguda', 'Lombociatalgia', 'Trabalho sentado por longas horas', 'Iniciada sessão de reabilitação postural.'),
(15, 'Cansaço excessivo e febre leve', 'Quadro Gripal Viral', 'Sintomas há 3 dias', 'Prescrito repouso e hidratação.'),
(16, 'Dor de garganta e mal-estar', 'Faringite Viral', 'Sem comorbidades relevantes', 'Prescrito sintomáticos e repouso.');

-- (1) NOVOS DADOS — prescrições vinculadas aos prontuários acima
-- (alguns prontuários recebem mais de um medicamento, totalizando 17 registros)
INSERT INTO prescricoes (id_prontuario, nome_medicamento, dosagem, frequencia, duracao_tratamento, observacoes, data_prescricao) VALUES
(1, 'Losartana', '50mg', '1x ao dia', '30 dias', 'Uso contínuo', '2026-01-10'),
(1, 'Ácido acetilsalicílico', '100mg', '1x ao dia', '30 dias', 'Uso contínuo', '2026-01-10'),
(2, 'Loratadina', '10mg', '1x ao dia', '10 dias', NULL, '2026-01-12'),
(2, 'Hidrocortisona creme', '1%', '2x ao dia', '7 dias', 'Aplicar na área afetada', '2026-01-12'),
(3, 'Ibuprofeno', '400mg', 'de 8 em 8h', '7 dias', 'Tomar após as refeições', '2026-01-18'),
(4, 'Nenhuma prescrição', '-', '-', '-', 'Consulta de rotina sem prescrição', '2026-01-20'),
(5, 'Propranolol', '40mg', '2x ao dia', '60 dias', 'Profilaxia de enxaqueca', '2026-01-25'),
(6, 'Sertralina', '50mg', '1x ao dia', '60 dias', 'Reavaliar em 60 dias', '2026-02-05'),
(6, 'Clonazepam', '0,5mg', 'à noite se necessário', '30 dias', 'Uso pontual', '2026-02-05'),
(7, 'Omeprazol', '20mg', '1x ao dia em jejum', '20 dias', NULL, '2026-02-10'),
(8, 'Tansulosina', '0,4mg', '1x ao dia', '90 dias', 'Uso contínuo', '2026-02-15'),
(9, 'Orientação nutricional', '-', '-', '90 dias', 'Sem medicamento; plano alimentar anexado', '2026-02-18'),
(10, 'Ciclobenzaprina', '5mg', 'à noite', '10 dias', 'Associado à fisioterapia', '2026-02-20'),
(10, 'Dipirona', '500mg', 'de 6 em 6h se dor', '5 dias', NULL, '2026-02-20'),
(11, 'Paracetamol', '750mg', 'de 6 em 6h se febre', '5 dias', NULL, '2026-02-22'),
(11, 'Soro fisiológico nasal', '0,9%', '3x ao dia', '5 dias', 'Higiene nasal', '2026-02-22'),
(12, 'Paracetamol', '750mg', 'de 6 em 6h se dor', '5 dias', 'Consulta referente à consulta 16', '2026-02-24');

-- (2) pagamentos agora sem id_paciente; (3) numero_recibo só para status 'Pago'
INSERT INTO pagamentos (id_consulta, valor_pago, data_pagamento, metodo_pagamento, status_pagamento, numero_recibo) VALUES
(1, 300.00, '2026-01-10 10:30:00', 'Pix', 'Pago', 'REC-2026-001'),
(2, 200.00, '2026-01-12 14:35:00', 'Cartao_Credito', 'Pago', 'REC-2026-002'),
(3, 0.00, NULL, 'Convenio', 'Pendente', NULL),
(4, 224.00, '2026-01-18 11:40:00', 'Cartao_Debito', 'Pago', 'REC-2026-004'),
(5, 221.00, '2026-01-20 15:45:00', 'Pix', 'Pago', 'REC-2026-005'),
(6, 0.00, NULL, 'Convenio', 'Pendente', NULL),
(7, 297.50, '2026-01-25 16:30:00', 'Dinheiro', 'Pago', 'REC-2026-007'),
(8, 0.00, NULL, 'Convenio', 'Cancelado', NULL),
(9, 288.00, '2026-02-05 15:00:00', 'Pix', 'Pago', 'REC-2026-009'),
(10, 216.00, '2026-02-10 10:00:00', 'Cartao_Credito', 'Pago', 'REC-2026-010'),
(11, 0.00, NULL, 'Convenio', 'Pendente', NULL),
(12, 280.00, '2026-02-15 16:00:00', 'Pix', 'Pago', 'REC-2026-012'),
(13, 135.00, '2026-02-18 17:00:00', 'Dinheiro', 'Pago', 'REC-2026-013'),
(14, 127.50, '2026-02-20 08:45:00', 'Cartao_Debito', 'Pago', 'REC-2026-014'),
(15, 160.00, '2026-02-22 10:40:00', 'Pix', 'Pago', 'REC-2026-015'),
(16, 200.00, '2026-02-24 09:30:00', 'Pix', 'Pago', 'REC-2026-016');


-- ATUALIZAÇÕES

-- UPDATE 1: reajuste de preço da especialidade
UPDATE especialidades SET valor_base_consulta = 320.00 WHERE nome_especialidade = 'Cardiologia';

-- UPDATE 2: confirmação de um pagamento que estava pendente (agora gera recibo)
UPDATE pagamentos
SET status_pagamento = 'Pago', data_pagamento = '2026-02-25 10:00:00',
    valor_pago = 154.00, metodo_pagamento = 'Pix', numero_recibo = 'REC-2026-003'
WHERE id_pagamento = 3;

-- UPDATE 3: atualização cadastral de paciente
UPDATE pacientes SET telefone = '(83) 99999-8888', email = 'lucas.ramos.novo@email.com' WHERE id_paciente = 1;


-- CONSULTAS DE AGREGAÇÃO

-- Query 1: Agregação de Receita por Método de Pagamento
SELECT
    metodo_pagamento,
    COUNT(*) AS total_transacoes,
    SUM(valor_pago) AS receita_total,
    ROUND(AVG(valor_pago), 2) AS ticket_medio,
    MIN(valor_pago) AS valor_minimo,
    MAX(valor_pago) AS valor_maximo
FROM pagamentos
WHERE status_pagamento = 'Pago'
GROUP BY metodo_pagamento
ORDER BY receita_total DESC;

-- Query 2: Performance Financeira e Volume por Especialidade
SELECT
    e.nome_especialidade,
    COUNT(c.id_consulta) AS total_consultas,
    ROUND(AVG(c.valor_consulta), 2) AS valor_medio_praticado,
    SUM(c.valor_consulta) AS faturamento_potencial
FROM consultas c
INNER JOIN especialidades e ON c.id_especialidade = e.id_especialidade
GROUP BY e.nome_especialidade
HAVING total_consultas > 0
ORDER BY total_consultas DESC;

-- Query 3: Share de Pacientes por Convênio com Percentual do Total
SELECT
    conv.nome_convenio,
    COUNT(p.id_paciente) AS total_pacientes,
    ROUND((COUNT(p.id_paciente) * 100.0 / (SELECT COUNT(*) FROM pacientes)), 2) AS pct_share
FROM pacientes p
INNER JOIN convenios conv ON p.id_convenio = conv.id_convenio
GROUP BY conv.nome_convenio
ORDER BY total_pacientes DESC;

-- Query 4: Taxa de No-Show Mensal com Agregação Condicional
SELECT
    DATE_FORMAT(c.data_consulta, '%Y-%m') AS mes_referencia,
    COUNT(*) AS total_agendamentos,
    SUM(CASE WHEN c.status_consulta = 'Realizada' THEN 1 ELSE 0 END) AS total_realizadas,
    SUM(CASE WHEN c.status_consulta = 'No-Show' THEN 1 ELSE 0 END) AS total_noshow,
    ROUND((SUM(CASE WHEN c.status_consulta = 'No-Show' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS taxa_noshow_pct
FROM consultas c
GROUP BY DATE_FORMAT(c.data_consulta, '%Y-%m')
ORDER BY mes_referencia;


-- CONSULTAS COM JOIN

-- Query 5: Extrato Cruzado da Consulta (JOINs múltiplos com COALESCE)
SELECT
    c.id_consulta,
    p.nome_completo AS paciente,
    m.nome_completo AS medico,
    e.nome_especialidade,
    c.data_consulta,
    c.status_consulta,
    COALESCE(pg.status_pagamento, 'Sem Registro') AS status_pagamento,
    COALESCE(pg.valor_pago, 0.00) AS valor_pago
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos m ON c.id_medico = m.id_medico
INNER JOIN especialidades e ON c.id_especialidade = e.id_especialidade
LEFT JOIN pagamentos pg ON c.id_consulta = pg.id_consulta;

-- Query 6: Prontuário Médico Detalhado com Dados Cadastrais
-- (corrigida: paciente e médico agora vêm via JOIN com consultas,
-- já que prontuarios não guarda mais essas FKs redundantes)
SELECT
    pr.id_prontuario,
    p.nome_completo AS paciente,
    p.cpf,
    m.nome_completo AS medico,
    m.crm,
    pr.queixa_principal,
    pr.diagnostico,
    c.data_consulta
FROM prontuarios pr
INNER JOIN consultas c ON pr.id_consulta = c.id_consulta
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos m ON c.id_medico = m.id_medico;

-- Query 6b (extra): Prescrições com paciente e data da consulta de origem
-- (demonstra o uso da nova tabela prescricoes)
SELECT
    p.nome_completo AS paciente,
    pre.nome_medicamento,
    pre.dosagem,
    pre.frequencia,
    c.data_consulta
FROM prescricoes pre
INNER JOIN prontuarios pr ON pre.id_prontuario = pr.id_prontuario
INNER JOIN consultas c ON pr.id_consulta = c.id_consulta
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
ORDER BY c.data_consulta DESC;

-- Query 7: Ranking de Médicos por Faturamento com Window Function (DENSE_RANK)
-- ATENÇÃO: DENSE_RANK() OVER (...) exige MySQL 8.0+ ou MariaDB 10.2+.
-- Em versões anteriores, substituir por uma subquery de ranking manual.
SELECT
    m.nome_completo AS medico,
    e.nome_especialidade,
    COUNT(c.id_consulta) AS total_atendimentos,
    SUM(c.valor_consulta) AS faturamento_total,
    DENSE_RANK() OVER (ORDER BY SUM(c.valor_consulta) DESC) AS ranking_faturamento
FROM consultas c
INNER JOIN medicos m ON c.id_medico = m.id_medico
INNER JOIN especialidades e ON c.id_especialidade = e.id_especialidade
WHERE c.status_consulta = 'Realizada'
GROUP BY m.id_medico, m.nome_completo, e.nome_especialidade;

-- Query 8: Auditoria de Inadimplência e Pendências Financeiras (LEFT JOIN)
SELECT
    p.nome_completo AS paciente,
    conv.nome_convenio,
    c.id_consulta,
    c.data_consulta,
    pg.valor_pago,
    pg.status_pagamento
FROM pacientes p
INNER JOIN convenios conv ON p.id_convenio = conv.id_convenio
INNER JOIN consultas c ON p.id_paciente = c.id_paciente
LEFT JOIN pagamentos pg ON c.id_consulta = pg.id_consulta
WHERE pg.status_pagamento = 'Pendente' OR pg.id_pagamento IS NULL;