# minput — NextUI Hardware Tester

Versão independente do `minput` do NextUI. Este repositório contém o programa, suas dependências compartilhadas e os arquivos específicos de cada plataforma necessários para compilar **somente o minput** e gerar um pacote instalável `.pakz`.

## Plataformas suportadas

- `tg5040`
- `tg5050`
- `h700`

Essas são as plataformas de hardware habilitadas no Makefile principal do NextUI na versão de origem deste pacote. `desktop` é um ambiente de desenvolvimento nativo, não uma plataforma de hardware incluída nesta build.

## Requisitos no host

- GNU Make
- Git
- Docker ou Podman
- `zip`
- Acesso à internet para clonar a toolchain e baixar a imagem na primeira compilação

Não é necessário instalar compilador ARM no host. Cada plataforma usa a toolchain oficial correspondente, fornecida em container.

## Compilar e empacotar

Na raiz do repositório:

```sh
make
```

Por padrão, compila para `tg5040`. Para selecionar outra plataforma:

```sh
make PLATFORM=tg5040
make PLATFORM=tg5050
make PLATFORM=h700
```

Para compilar e empacotar todas as plataformas:

```sh
make all-platforms
```

O alvo padrão prepara a toolchain oficial `LoveRetro/<plataforma>-toolchain`, compila a `libmsettings`, compila somente o `minput` e então monta o pacote `.pakz`.

## Templates de pacote por plataforma

A pasta `Input.pak` fica dentro do diretório de cada plataforma em `workspace/`, junto de `platform/` e `libmsettings/`:

```text
workspace/
├── tg5040/
│   ├── platform/
│   ├── libmsettings/
│   └── Input.pak/
│       └── launch.sh
├── tg5050/
│   ├── platform/
│   ├── libmsettings/
│   └── Input.pak/
│       └── launch.sh
└── h700/
    ├── platform/
    ├── libmsettings/
    └── Input.pak/
        └── launch.sh
```

O `launch.sh` deve ser o script específico do dispositivo e chamar o executável `minput` localizado ao lado dele. Um exemplo simples é:

```sh
#!/bin/sh
cd "$(dirname "$0")"
./minput
```

Se o script tiver configurações específicas do aparelho, mantenha-as nele. O empacotador copia todo o conteúdo da pasta `Input.pak/` sem modificar os arquivos originais e adiciona o binário compilado com o nome `minput`.

## Saída

Os binários são compilados em `out/<PLATFORM>/binaries/`, enquanto os pacotes `.pakz` ficam diretamente em `out/`:

```text
out/
├── tg5040/binaries/minput
├── tg5050/binaries/minput
├── h700/binaries/minput
├── minput-tg5040.pakz
├── minput-tg5050.pakz
└── minput-h700.pakz
```

## Instalar no sistema

Para installar um pacote `.pakz` no NextUI basta coloca-lo na raiz do cartão de memória onde o NextUI está instalado. Ao reiniciar o dispositivo o pacote será automaticamente instalado no sistema.

## Outros comandos

```sh
make list                    # lista as plataformas
make build PLATFORM=h700     # compila sem gerar .pakz
make package PLATFORM=h700   # compila e gera .pakz
make shell PLATFORM=h700     # abre o container da toolchain
make clean PLATFORM=tg5040   # remove os binários da plataforma
make clean-packages          # remove apenas os .pakz de out/
make clean-all               # remove toda a pasta out/
```

O empacotamento requer o utilitário `zip` (por exemplo, `sudo apt install zip`). Se o `launch.sh` da plataforma não existir, a etapa de pacote falha e informa o caminho esperado.

## Alteração do Hardware Tester

O `minput.c` mantém a alteração solicitada para que os grupos visuais dos analógicos sejam habilitados quando os eixos `LX/LY` ou `RX/RY` estiverem definidos, mesmo que os botões L3/R3 não estejam mapeados. Nenhuma outra alteração funcional foi aplicada ao fonte.

## Créditos

O código-fonte é derivado do [NextUI](https://github.com/LoveRetro/NextUI), e as toolchains são mantidas em [LoveRetro](https://github.com/LoveRetro). Os arquivos `LICENSE` e `NOTICE` originais foram preservados.
