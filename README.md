# minput — NextUI Hardware Tester

Versão independente do `minput` do NextUI. Este repositório contém somente o programa, suas dependências compartilhadas e os arquivos específicos de plataforma necessários para compilá-lo. Não compila o restante do NextUI.

## Plataformas suportadas

As plataformas de hardware habilitadas no Makefile principal do NextUI na versão de origem deste pacote são:

- `tg5040`
- `tg5050`
- `h700`

O alvo `desktop` do NextUI é um ambiente de desenvolvimento nativo, não uma das plataformas de hardware distribuídas pelo projeto; por isso não está incluído nesta compilação multiplataforma.

## Requisitos no host

- GNU Make
- Git
- Docker ou Podman
- Acesso à internet para clonar a toolchain e baixar a imagem na primeira compilação

Não é necessário instalar compilador ARM no host. Cada plataforma usa a toolchain oficial correspondente, fornecida em container.

## Compilar

Na raiz do repositório:

```sh
make
```

Por padrão, compila para `tg5040` (Trimui Smart Pro). Para escolher outra plataforma:

```sh
make PLATFORM=tg5040
make PLATFORM=tg5050
make PLATFORM=h700
```

Para compilar as três plataformas em sequência:

```sh
make all-platforms
```

O processo prepara a toolchain oficial `LoveRetro/<plataforma>-toolchain`, compila a `libmsettings` daquela plataforma e então compila **somente** o `minput`.

## Saída

Cada plataforma tem seu próprio diretório de saída:

```text
workspace/all/minput/build/tg5040/minput.elf
workspace/all/minput/build/tg5050/minput.elf
workspace/all/minput/build/h700/minput.elf
```

## Outros comandos

Listar as plataformas:

```sh
make list
```

Abrir o container da plataforma selecionada:

```sh
make shell PLATFORM=h700
```

Limpar a saída da plataforma selecionada (por padrão, `tg5040`):

```sh
make clean PLATFORM=tg5040
```

Limpar as saídas de todas as plataformas:

```sh
make clean-all
```

## Estrutura

- `workspace/all/minput/`: fonte e Makefile do programa.
- `workspace/all/common/`: código compartilhado usado pelo `minput` e pelas implementações de plataforma.
- `workspace/<plataforma>/platform/`: implementação e flags específicas de cada hardware.
- `workspace/<plataforma>/libmsettings/`: biblioteca de configurações correspondente à plataforma.
- `Makefile`: interface de compilação executada no host.

## Alteração do Hardware Tester

O `minput.c` incluído mantém a alteração solicitada para que os grupos visuais dos analógicos sejam habilitados quando os eixos `LX/LY` ou `RX/RY` estiverem definidos, mesmo que os botões L3/R3 não estejam mapeados. Nenhuma outra alteração funcional foi aplicada ao fonte do usuário.

## Créditos

O código-fonte é derivado do [NextUI](https://github.com/LoveRetro/NextUI), e as toolchains são mantidas em [LoveRetro](https://github.com/LoveRetro). Os arquivos `LICENSE` e `NOTICE` originais foram preservados.
