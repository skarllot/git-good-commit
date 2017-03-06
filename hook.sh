#!/usr/bin/env bash

#
# git-good-commit(1) - Git hook to help you write good commit messages.
# Released under the MIT License.
#
# Version 0.6.1
#
# https://github.com/tommarshall/git-good-commit
#

COMMIT_MSG_FILE="$1"
COMMIT_MSG_LINES=
HOOK_EDITOR=
SKIP_DISPLAY_WARNINGS=0
WARNINGS=

RED=
YELLOW=
BLUE=
WHITE=
NC=

#
# Add a warning with <line_number> and <msg>.
#

add_warning() {
  local line_number=$1
  local warning=$2
  WARNINGS[$line_number]="${WARNINGS[$line_number]}$warning;"
}

#
# Output warnings.
#

display_warnings() {
  if [ $SKIP_DISPLAY_WARNINGS -eq 1 ]; then
    # if the warnings were skipped then they should be displayed next time
    SKIP_DISPLAY_WARNINGS=0
    return
  fi

  for i in "${!WARNINGS[@]}"; do
    printf "%-74s ${WHITE}%s${NC}\n" "${COMMIT_MSG_LINES[$(($i-1))]}" "[line ${i}]"
    IFS=';' read -ra WARNINGS_ARRAY <<< "${WARNINGS[$i]}"
    for ERROR in "${WARNINGS_ARRAY[@]}"; do
      echo -e " ${YELLOW}- ${ERROR}${NC}"
    done
  done
}

#
# Read the contents of the commit msg into an array of lines.
#

read_commit_message() {
  # reset commit_msg_lines
  COMMIT_MSG_LINES=()

  # read commit message into lines array
  while IFS= read -r; do

    # trim trailing spaces from commit lines
    shopt -s extglob
    REPLY="${REPLY%%*( )}"
    shopt -u extglob

    # ignore comments
    [[ $REPLY =~ ^# ]]
    test $? -eq 0 || COMMIT_MSG_LINES+=("$REPLY")

  done < <(cat $COMMIT_MSG_FILE)
}

#
# Validate the contents of the commmit msg agains the good commit guidelines.
#

validate_commit_message() {
  # reset warnings
  WARNINGS=()

  # capture the subject, and remove the 'squash! ' prefix if present
  COMMIT_SUBJECT=${COMMIT_MSG_LINES[0]/#squash! /}

  # if the commit is empty there's nothing to validate, we can return here
  COMMIT_MSG_STR="${COMMIT_MSG_LINES[*]}"
  test -z "${COMMIT_MSG_STR[*]// }" && return;

  # if the commit subject starts with 'fixup! ' there's nothing to validate, we can return here
  [[ $COMMIT_SUBJECT == 'fixup! '* ]] && return;

  # 1. Separate subject from body with a blank line
  # ------------------------------------------------------------------------------

  test ${#COMMIT_MSG_LINES[@]} -lt 1 || test -z "${COMMIT_MSG_LINES[1]}"
  test $? -eq 0 || add_warning 2 "Separate subject from body with a blank line"

  # 2. Limit the subject line to 50 characters
  # ------------------------------------------------------------------------------

  test "${#COMMIT_SUBJECT}" -le 50
  test $? -eq 0 || add_warning 1 "Limit the subject line to 50 characters (${#COMMIT_SUBJECT} chars)"

  # 3. Capitalize the subject line
  # ------------------------------------------------------------------------------

  [[ ${COMMIT_SUBJECT} =~ ^[[:blank:]]*([[:upper:]]{1}[[:lower:]]*|[[:digit:]]+)([[:blank:]]|[[:punct:]]|$) ]]
  test $? -eq 0 || add_warning 1 "Capitalize the subject line"

  # 4. Do not end the subject line with a period
  # ------------------------------------------------------------------------------

  [[ ${COMMIT_SUBJECT} =~ [^\.]$ ]]
  test $? -eq 0 || add_warning 1 "Do not end the subject line with a period"

  # 5. Use the imperative mood in the subject line
  # ------------------------------------------------------------------------------

  IMPERATIVE_MOOD_BLACKLIST=(
    added          adds          adding
    adjusted       adjusts       adjusting
    amended        amends        amending
    avoided        avoids        avoiding
    bumped         bumps         bumping
    changed        changes       changing
    checked        checks        checking
    committed      commits       committing
    copied         copies        copying
    corrected      corrects      correcting
    created        creates       creating
    decreased      decreases     decreasing
    deleted        deletes       deleting
    disabled       disables      disabling
    dropped        drops         dropping
    enabled        enables       enabling
    excluded       excludes      excluding
    fixed          fixes         fixing
    handled        handles       handling
    implemented    implements    implementing
    improved       improves      improving
    included       includes      including
    increased      increases     increasing
    installed      installs      installing
    introduced     introduces    introducing
    merged         merges        merging
    moved          moves         moving
    pruned         prunes        pruning
    refactored     refactors     refactoring
    removed        removes       removing
    renamed        renames       renaming
    replaced       replaces      replacing
    resolved       resolves      resolving
    reverted       reverts       reverting
    showed         shows         showing
    tested         tests         testing
    tidied         tidies        tidying
    updated        updates       updating
    used           uses          using
  )

    IMPERATIVE_MOOD_BLACKLIST_PTBR=(
    acrescentado    acrescentas     acrescentando   acrescentei
    adicionado      adicionas       adicionando     adicionei       adição          adições
    ajustado        ajustas         ajustando       ajustei
    alterado        alteras         alterando       alterei         alteração       alterações
    ampliado        amplias         ampliando       ampliei
    apagado         apagas          apagando        apaguei
    aprimorado      aprimoradas     aprimorando     aprimorei
    arrumado        arrumas         arrumando       arrumei
    atualizado      atualizas       atualizando     atualizei
    aumentado       aumentas        aumentando      aumentei
    baixado         baixas          baixando        baixei
    cancelado       cancelas        cancelando      cancelei
    conferido       conferes        conferindo      conferi
    consertado      consertas       consertando     consertei
    controlado      controlas       controlando     controlei
    completado      completas       completando     completei
    copiado         copias          copiando        copiei
    corrigido       corriges        corrigindo      corrigi         correção        correções
    criado          crias           criando         criei
    deletado        deletas         deletando       deletei
    desabilitado    desabilitas     desabilitando   desabilitei
    deslocado       deslocas        desalocando     desaloquei
    determinado     determinas      determinando    determinei
    efetuado        efetuas         efetuando       efetuei
    enviado         envias          enviando        enviei
    evitado         evitas          evitando        evitei
    excluido        exclues         excluindo       excluí
    executado       executas        executando      executei
    explicado       explicas        explicando      expliquei
    finalizado      finalizas       finalizando     finalizei       finalização
    habilitado      habilitas       habilitando     habilitei
    implantado      implantas       implantando     implantei
    implementado    implementas     implementando   implementei     implementação   implementações
    importado       importas        importando      importei
    incluido        incluis         incluindo       incluí
    incrementado    incrementas     incrementando   incrementei
    iniciado        inicias         iniciando       iniciei
    inserido        inseres         inserindo       inseri
    instalado       instalas        instalando      instalei
    limpado         limpas          limpando        limpei
    melhorado       melhoras        melhorando      melhorei
    mostrado        mostras         mostrando       mostrei
    movido          moves           movendo         movi
    mudado          mudas           mudando         mudei
    ordenado        ordenas         ordenando       ordenei
    reduzido        reduzes         reduzindo       reduzi
    refatorado      refatoras       refatorando     refatorei
    remodelado      remodelas       remodelando     remodelei
    removido        removes         removendo       removi
    renomeado       renomeias       renomeando      renomeei
    reposto         repões          repondo         repus
    resolvido       resolves        resolvendo      resolvi
    retirado        retiras         retirando       retirei
    revertido       revertes        revertendo      reverti
    substituido     substituis      substituindo    substituí
    testado         testas          testando        testei
    tirado          tiras           tirando         tirei
    transferido     transferes      transferindo    transferi
    usado           usas            usando          usei
    utilizado       utilizas        utilizando      utilizei
    verificado      verificas       verificando     verifiquei
  )

  # enable case insensitive match
  shopt -s nocasematch

  for BLACKLISTED_WORD in "${IMPERATIVE_MOOD_BLACKLIST[@]}"; do
    [[ ${COMMIT_SUBJECT} =~ ^[[:blank:]]*$BLACKLISTED_WORD ]]
    test $? -eq 0 && add_warning 1 "Use the imperative mood in the subject line, e.g 'fix' not 'fixes'" && break
  done

  for BLACKLISTED_WORD in "${IMPERATIVE_MOOD_BLACKLIST_PTBR[@]}"; do
    [[ ${COMMIT_SUBJECT} =~ ^[[:blank:]]*$BLACKLISTED_WORD ]]
    test $? -eq 0 && add_warning 1 "Utilize o modo imperativo no tópico. Ex: 'Corrige' em vez de 'Corrigido'" && break
  done

  # disable case insensitive match
  shopt -u nocasematch

  # 6. Wrap the body at 72 characters
  # ------------------------------------------------------------------------------

  URL_REGEX='^[[:blank:]]*(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

  for i in "${!COMMIT_MSG_LINES[@]}"; do
    LINE_NUMBER=$((i+1))
    test "${#COMMIT_MSG_LINES[$i]}" -le 72 || [[ ${COMMIT_MSG_LINES[$i]} =~ $URL_REGEX ]]
    test $? -eq 0 || add_warning $LINE_NUMBER "Wrap the body at 72 characters (${#COMMIT_MSG_LINES[$i]} chars)"
  done

  # 7. Use the body to explain what and why vs. how
  # ------------------------------------------------------------------------------

  # ?

  # 8. Do no write single worded commits
  # ------------------------------------------------------------------------------

  COMMIT_SUBJECT_WORDS=(${COMMIT_SUBJECT})
  test "${#COMMIT_SUBJECT_WORDS[@]}" -gt 1
  test $? -eq 0 || add_warning 1 "Do no write single worded commits"

  # 9. Do not start the subject line with whitespace
  # ------------------------------------------------------------------------------

  [[ ${COMMIT_SUBJECT} =~ ^[[:blank:]]+ ]]
  test $? -eq 1 || add_warning 1 "Do not start the subject line with whitespace"
}

#
# It's showtime.
#

if tty >/dev/null 2>&1; then
  TTY=$(tty)
else
  TTY=/dev/tty
fi

while true; do

  read_commit_message

  validate_commit_message

  # if there are no WARNINGS are empty then we're good to break out of here
  test ${#WARNINGS[@]} -eq 0 && exit 0;

  display_warnings

  exit 1

done
