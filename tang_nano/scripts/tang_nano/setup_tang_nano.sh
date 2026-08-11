#!/bin/bash

##############################################################################
# setup_tang_nano.sh
# Script consolidado para configurar ambiente FPGA Tang Nano (1K ou 9K)
# 
# Uso:
#   ./setup_tang_nano.sh [opcoes]
#
# Opções:
#   --version 1k|9k     Versão da placa (padrão: detectar automaticamente)
#   --mode local|global Instalação local ou global (padrão: global)
#   --verify            Apenas verificar instalação (sem instalar)
#   --help              Exibir esta mensagem
#
##############################################################################

set -e

# Caminhos baseados na localização do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parâmetros
PLACA="auto"                              # 1k, 9k, ou auto
MODE="global"                             # global ou local
VERIFY_ONLY=false

LOG_FILE="fpga_setup_${TIMESTAMP}.log"

# ============================================================================
# FUNÇÕES DE LOG
# ============================================================================

log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1" >&2
    exit 1
}

header() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================================================
# PARSING DE ARGUMENTOS
# ============================================================================

show_help() {
    cat << 'EOF'
setup_tang_nano.sh — Configuração de Ambiente FPGA Tang Nano

SINTAXE:
    ./setup_tang_nano.sh [opções]

OPÇÕES:
    --version 1k|9k     Versão da placa (padrão: detectar automaticamente)
    --mode local|global Instalação local ou global (padrão: global)
    --verify            Apenas verificar instalação existente (sem instalar)
    --help              Exibir esta mensagem

EXEMPLOS:

    Setup global completo (detecta placa automaticamente):
    $ ./setup_tang_nano.sh

    Setup para Tang Nano 1K (instalação global):
    $ ./setup_tang_nano.sh --version 1k

    Setup para Tang Nano 9K (instalação local, sem sudo):
    $ ./setup_tang_nano.sh --version 9k --mode local

    Apenas verificar se tudo está configurado:
    $ ./setup_tang_nano.sh --verify

MODOS:

    • global: Instala ferramentas globalmente em /home/tools/
             Requer sudo, configurar ~/.bashrc
             Recomendado para uso compartilhado

    • local:  Instala ferramentas localmente no diretório do script
             Não requer sudo, cria arquivo de configuração local
             Bom para ambiente isolado

EOF
}

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            PLACA="$2"
            if [[ ! "$PLACA" =~ ^(1k|9k|auto)$ ]]; then
                error "Placa inválida: $PLACA (use: 1k, 9k, ou auto)"
            fi
            shift 2
            ;;
        --mode)
            MODE="$2"
            if [[ ! "$MODE" =~ ^(local|global)$ ]]; then
                error "Modo inválido: $MODE (use: local ou global)"
            fi
            shift 2
            ;;
        --verify)
            VERIFY_ONLY=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            error "Argumento desconhecido: $1. Use --help para ajuda."
            ;;
    esac
done

# ============================================================================
# DETECÇÃO DE PLACA
# ============================================================================

detect_board() {
    header "Detectando Placa"
    
    if lsusb 2>/dev/null | grep -qi "sipeed"; then
        log "Tang Nano detectada"
        echo "1k"
    else
        warn "Nenhuma placa Tang Nano detectada via USB"
        echo "auto"
    fi
}

# Se placa em "auto", tentar detectar
if [ "$PLACA" = "auto" ]; then
    PLACA=$(detect_board)
    if [ "$PLACA" = "auto" ]; then
        warn "Não foi possível detectar automaticamente"
        info "Usando configuração padrão para Tang Nano 1K"
        PLACA="1k"
    fi
else
    header "Configuração"
    log "Placa: Tang Nano $PLACA"
fi

# ============================================================================
# CONFIGURAÇÃO DE CAMINHOS
# ============================================================================

if [ "$MODE" = "global" ]; then
    TOOLS_DIR="/home/tools"
    CONFIG_FILE="$HOME/.bashrc"
    CONFIG_MARKER="# TANG_NANO_FPGA_SETUP"
else
    TOOLS_DIR="$SCRIPT_DIR/tools"
    CONFIG_FILE="$SCRIPT_DIR/.bashrc_tang_nano"
    CONFIG_MARKER="# TANG_NANO_FPGA_SETUP_LOCAL"
fi

OSS_CAD_DIR="$TOOLS_DIR/oss-cad-suite"

# ============================================================================
# FUNÇÃO: VERIFICAÇÃO
# ============================================================================

verify_installation() {
    header "Verificação de Instalação"
    
    local success=true
    
    # Verificar oss-cad-suite
    if [ -d "$OSS_CAD_DIR" ]; then
        log "oss-cad-suite encontrado: $OSS_CAD_DIR"
        
        if [ -f "$OSS_CAD_DIR/bin/yosys" ]; then
            local yosys_version=$("$OSS_CAD_DIR/bin/yosys" -version 2>&1 | head -1)
            log "  └─ yosys: $yosys_version"
        else
            warn "  └─ yosys não encontrado"
            success=false
        fi
        
        if [ -f "$OSS_CAD_DIR/bin/nextpnr-gowin" ]; then
            log "  └─ nextpnr-gowin disponível"
        elif [ -f "$OSS_CAD_DIR/bin/nextpnr-nexus" ]; then
            log "  └─ nextpnr-nexus disponível"
        else
            warn "  └─ nextpnr não encontrado"
        fi
    else
        warn "oss-cad-suite não encontrado: $OSS_CAD_DIR"
        success=false
    fi
    
    # Verificar openFPGALoader
    if command -v openFPGALoader &> /dev/null; then
        local loader_version=$(openFPGALoader --version 2>&1 | head -1)
        log "openFPGALoader: $loader_version"
    else
        warn "openFPGALoader não encontrado"
        success=false
    fi
    
    # Verificar PATH
    if [ "$MODE" = "global" ]; then
        if grep -q "$CONFIG_MARKER" "$CONFIG_FILE" 2>/dev/null; then
            log "Configuração em ~/.bashrc detectada"
        else
            warn "Configuração em ~/.bashrc não encontrada"
            info "Execute: source ~/.bashrc"
        fi
    else
        if [ -f "$CONFIG_FILE" ]; then
            log "Configuração local encontrada: $CONFIG_FILE"
            info "Execute: source $CONFIG_FILE"
        else
            warn "Configuração local não encontrada"
        fi
    fi
    
    # Verificar udev
    if [ -f /etc/udev/rules.d/99-fpga.rules ]; then
        log "Regras udev encontradas"
    else
        warn "Regras udev não encontradas"
    fi
    
    # Tentar detectar FPGA
    info "Testando conexão com FPGA..."
    if command -v openFPGALoader &> /dev/null; then
        if openFPGALoader --detect 2>/dev/null | grep -q "found"; then
            log "FPGA detectada!"
            openFPGALoader --detect 2>/dev/null | head -10
        else
            warn "Nenhuma FPGA detectada (normal se desconectada)"
        fi
    fi
    
    echo ""
    if [ "$success" = true ]; then
        log "Verificação bem-sucedida ✓"
        return 0
    else
        warn "Algumas verificações falharam. Veja acima."
        return 1
    fi
}

# ============================================================================
# FUNÇÃO: INSTALAÇÃO
# ============================================================================

install_fpga_environment() {
    header "Instalação do Ambiente FPGA"
    
    info "Modo: $MODE"
    info "Placa: Tang Nano $PLACA"
    info "Ferramentas: $TOOLS_DIR"
    info "Log: $LOG_FILE"
    info ""
    
    # ========================================================================
    # ETAPA 1: Dependências do Sistema
    # ========================================================================
    
    if [ "$MODE" = "global" ]; then
        header "Etapa 1/5: Dependências do Sistema"
        
        # Verificar sudo
        if ! sudo -n true 2>/dev/null; then
            error "Este script requer acesso sudo. Configure 'sudo' sem senha ou execute: sudo bash $SCRIPT_NAME"
        fi
        
        log "Atualizando lista de pacotes..."
        sudo apt-get update >> "$LOG_FILE" 2>&1 || warn "apt update retornou erro (ignorando)"
        
        log "Instalando dependências..."
        sudo apt-get install -y \
            build-essential \
            git \
            cmake \
            pkg-config \
            libusb-1.0-0-dev \
            libusb-1.0-0 \
            libftdi1-dev \
            libftdi-dev \
            libmpsse-dev \
            python3 \
            python3-pip \
            python3-dev \
            wget \
            curl >> "$LOG_FILE" 2>&1
        
        log "Dependências instaladas"
    else
        header "Etapa 1/5: Verificação de Dependências (modo local)"
        log "Modo local: dependências do sistema já devem estar instaladas"
    fi
    
    # ========================================================================
    # ETAPA 2: oss-cad-suite
    # ========================================================================
    
    header "Etapa 2/5: oss-cad-suite (Toolchain)"
    
    # Criar diretório
    if [ "$MODE" = "global" ]; then
        sudo mkdir -p "$TOOLS_DIR" >> "$LOG_FILE" 2>&1 || mkdir -p "$TOOLS_DIR"
    else
        mkdir -p "$TOOLS_DIR"
    fi
    
    if [ -d "$OSS_CAD_DIR" ]; then
        log "oss-cad-suite já instalado em: $OSS_CAD_DIR"
    else
        log "Baixando oss-cad-suite..."
        local release_url="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2024-04-25/oss-cad-suite-linux-x64-20240425.tgz"
        
        cd "$TOOLS_DIR"
        wget -q --show-progress "$release_url" -O oss-cad-suite.tgz >> "$LOG_FILE" 2>&1 || true
        
        log "Extraindo..."
        tar xzf oss-cad-suite.tgz >> "$LOG_FILE" 2>&1
        rm oss-cad-suite.tgz
        
        log "oss-cad-suite instalado com sucesso"
    fi
    
    # Verificar
    if [ ! -f "$OSS_CAD_DIR/bin/yosys" ]; then
        error "Falha ao instalar oss-cad-suite"
    fi
    
    # ========================================================================
    # ETAPA 3: openFPGALoader
    # ========================================================================
    
    header "Etapa 3/5: openFPGALoader"
    
    if [ "$MODE" = "global" ]; then
        log "Instalando openFPGALoader via apt..."
        sudo apt-get install -y openfpgaloader >> "$LOG_FILE" 2>&1 || \
            warn "Instalação via apt falhou, continuando..."
        
        if ! command -v openFPGALoader &> /dev/null; then
            log "Compilando openFPGALoader do source..."
            cd "$TOOLS_DIR"
            
            if [ -d "openFPGALoader" ]; then
                log "openFPGALoader já existe, atualizando..."
                cd openFPGALoader
                git pull >> "$LOG_FILE" 2>&1
            else
                git clone https://github.com/trabucayre/openFPGALoader.git >> "$LOG_FILE" 2>&1
                cd openFPGALoader
            fi
            
            mkdir -p build && cd build
            cmake -DCMAKE_BUILD_TYPE=Release .. >> "$LOG_FILE" 2>&1
            make -j$(nproc) >> "$LOG_FILE" 2>&1
            sudo make install >> "$LOG_FILE" 2>&1
            
            log "openFPGALoader compilado e instalado"
        fi
    else
        log "Modo local: openFPGALoader deve estar instalado globalmente"
        info "Se não tiver, execute primeiro: sudo apt-get install openfpgaloader"
    fi
    
    # ========================================================================
    # ETAPA 4: Variáveis de Ambiente
    # ========================================================================
    
    header "Etapa 4/5: Variáveis de Ambiente"
    
    if grep -q "$CONFIG_MARKER" "$CONFIG_FILE" 2>/dev/null; then
        log "Configuração já existe em: $CONFIG_FILE"
    else
        log "Adicionando configuração em: $CONFIG_FILE"
        
        cat >> "$CONFIG_FILE" << ENVEOF

# $CONFIG_MARKER
# Tang Nano FPGA Environment (added by setup_tang_nano.sh)
export OSS_CAD_SUITE="$OSS_CAD_DIR"
export PATH="\${OSS_CAD_SUITE}/bin:\$PATH"
export LD_LIBRARY_PATH="\${OSS_CAD_SUITE}/lib:\$LD_LIBRARY_PATH"

# Aliases úteis
alias fpga_detect='openFPGALoader --detect'
alias fpga_version='yosys -version && openFPGALoader --version'
ENVEOF
        
        log "Configuração adicionada com sucesso"
    fi
    
    # ========================================================================
    # ETAPA 5: Permissões udev
    # ========================================================================
    
    header "Etapa 5/5: Permissões USB/JTAG (udev)"
    
    if [ "$MODE" = "global" ]; then
        log "Criando regras udev..."
        
        sudo tee /etc/udev/rules.d/99-fpga.rules > /dev/null << 'UDEVEOF'
# FPGA JTAG Devices (Generic - FTDI)
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", MODE="0666"
SUBSYSTEM=="usb_device", ATTR{idVendor}=="0403", MODE="0666"

# Specific JTAG devices
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="0666"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666"
UDEVEOF
        
        log "Recarregando regras udev..."
        sudo udevadm control --reload-rules >> "$LOG_FILE" 2>&1
        sudo udevadm trigger >> "$LOG_FILE" 2>&1
        
        log "Permissões configuradas com sucesso"
    else
        info "Modo local: configure udev manualmente se necessário"
    fi
    
    # ========================================================================
    # CONCLUSÃO
    # ========================================================================
    
    header "✓ Setup Concluído!"
    
    log "Ambiente FPGA Tang Nano $PLACA configurado com sucesso"
    
    echo ""
    echo -e "${YELLOW}Próximos passos:${NC}"
    echo ""
    
    if [ "$MODE" = "global" ]; then
        echo "1. Recarregar configuração do shell:"
        echo "   ${BLUE}source ~/.bashrc${NC}"
        echo ""
        echo "2. Reconecte a placa Tang Nano"
        echo ""
        echo "3. Testar detecção da FPGA:"
        echo "   ${BLUE}openFPGALoader --detect${NC}"
    else
        echo "1. Ativar configuração local:"
        echo "   ${BLUE}source $CONFIG_FILE${NC}"
        echo ""
        echo "2. Adicionar ao seu ~/.bashrc para carregar automaticamente:"
        echo "   ${BLUE}echo 'source $CONFIG_FILE' >> ~/.bashrc${NC}"
        echo ""
        echo "3. Reconecte a placa Tang Nano"
        echo ""
        echo "4. Testar detecção da FPGA:"
        echo "   ${BLUE}openFPGALoader --detect${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Documentação:${NC}"
    echo "  • Instalação: docs/hdl/TANG_NANO_LINUX.md"
    echo "  • Workflow: docs/hdl/WORKFLOW.md"
    echo ""
    echo -e "${GREEN}Log completo: $LOG_FILE${NC}"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    header "Tang Nano Setup Script"
    
    info "Script: $SCRIPT_NAME"
    info "Diretório: $SCRIPT_DIR"
    info "Data: $(date)"
    echo ""
    
    if [ "$VERIFY_ONLY" = true ]; then
        verify_installation
    else
        install_fpga_environment
        
        echo ""
        info "Para verificar a instalação depois, execute:"
        echo "  ${BLUE}$SCRIPT_DIR/$SCRIPT_NAME --verify${NC}"
        echo ""
    fi
}

# Executar
main
