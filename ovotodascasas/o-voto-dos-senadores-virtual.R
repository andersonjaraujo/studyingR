################################################################
###                                                          ###
###                   O voto dos senadores                   ###
###                                                          ###
###                      gabriela caesar                     ###
###                                                          ###
################################################################

################################################################
###                 Inclusão de votação nova                 ###
################################################################

################################################################
###                     Votação virtual                      ###
################################################################

#1. instalar as bibliotecas
install.packages("tidyverse")
install.packages("foreign")
install.packages("rvest")
install.packages("data.table")
install.packages("abjutils")

#2. ler as bibliotecas
library(tidyverse)
library(foreign)
library(rvest)
library(data.table)
library(abjutils)

#3. importar o nosso arquivo com o registro de todos os senadores
# fazer o download da aba 'politicos' da planilha
senadores_id <- fread("~/Downloads/plenario2019_SF - politicos.csv", 
                      drop = c("foto", "permalink"))

#4. pegar o resultado direto via HTML
## ALTERAR URL
url <- "https://www25.senado.leg.br/web/atividade/materias/-/materia/141297/votacoes#votacao_6163"

### ATT / A FAZER
### coletar tb os motivos
### Impedido (art.306 RISF) >>> naovotou

# número maáximo de votantes
number <- c(1:100)

get_resultado_url <- function(x){
  url %>%
    read_html() %>%
    html_nodes("table") %>%
    .[x] %>%
    html_nodes("td") %>%
    html_text() %>%
    as.data.frame() %>%
    rename("content" = ".") %>%
    mutate(content = as.character(content)) %>%
    mutate(voto = case_when(content == "Simone Tebet" ~ NA_character_,
                            content == "Sim" ~ "Sim",
                            content == "-" ~ "-",
                            content == "Não" ~ "Não",
                            content == "Abstenção" ~ "Abstenção")) %>%
    fill(voto, .direction = "up") %>%
    mutate(n_order = ifelse(str_detect(str_trim(content), 
                                       paste(number, collapse = "|")), content, NA)) %>%
    fill(n_order, .direction = "down") %>%
    filter(content != voto & 
             content != n_order &
             content != "" &
             content != "Não Compareceu")
}

resultado_votacao <- map_df(2:4, get_resultado_url)

resultado_votacao <- resultado_votacao %>%
  mutate(voto = str_replace_all(voto, "Sim", "sim"),
         voto = str_replace_all(voto, "Não", "nao"),
         voto = str_replace_all(voto, "-", "ausente"),
         voto = str_replace_all(voto, "Abstenção", "abstencao")) %>%
  mutate(nome_upper = toupper(rm_accent(content))) 

#5. cruzar planilhas
joined_data <- resultado_votacao %>%
  left_join(senadores_id, by = "nome_upper") %>%
  arrange(desc(id))

#6. informar infos da proposicao
## ALTERAR INFORMACOES ABAIXO
id_proposicao <- "83"
proposicao <- "PL1166-2020"
permalink <- "limite-de-juros-para-cartao-de-credito-durante-a-pandemia"

#7. selecionar as colunas que queremos no nosso arquivo
votacao_final <- joined_data %>%
  rename("nome_politico" = nome,
         "partido" = partido,
         "uf" = uf,
         "id_politico" = id) %>%
  mutate(id_proposicao = id_proposicao,
         proposicao = proposicao,
         permalink = permalink) %>%
  select("id_proposicao", "proposicao", "partido", "id_politico", 
         "nome_upper", "nome_politico", "uf", "voto", "permalink") %>% 
  arrange(nome_upper)

#8. fazer o download
dir.create(paste0("~/Downloads/votacao_final_", proposicao, Sys.Date()))
setwd(paste0("~/Downloads/votacao_final_", proposicao, Sys.Date()))
write.csv(votacao_final, paste0("votacao_final_", proposicao, Sys.Date(), ".csv"))
