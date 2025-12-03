# YourNes Setup Guide

## Требования для компиляции

Для полной компиляции .den файлов в .nes ROM вам нужно:

### 1. .NET SDK ✅

- .NET 8.0 или новее
- Проверить: `dotnet --version`
- Скачать: https://dotnet.microsoft.com/download

### 2. cc65 Toolchain (ca65 + ld65)

#### Windows:

**Вариант A: Скачать готовые бинарники**

1. Скачайте cc65 с официального сайта:
   - https://github.com/cc65/cc65/releases/latest
   - Найдите файл `cc65-snapshot-win32.zip`

2. Распакуйте архив (например, в `C:\cc65`)

3. Добавьте путь к `bin\` в PATH:
   - Откройте "Система" → "Дополнительные параметры системы"
   - "Переменные среды"
   - В "Системные переменные" найдите `Path`
   - Добавьте путь: `C:\cc65\bin`

4. Проверьте установку:
   ```bash
   ca65 --version
   ld65 --version
   ```

**Вариант B: Через Chocolatey**

Если у вас установлен [Chocolatey](https://chocolatey.org/):

```bash
choco install cc65
```

**Вариант C: Собрать из исходников**

```bash
git clone https://github.com/cc65/cc65.git
cd cc65
make
# Добавьте bin/ в PATH
```

#### Linux:

```bash
# Ubuntu/Debian
sudo apt-get install cc65

# Fedora
sudo dnf install cc65

# Arch
sudo pacman -S cc65
```

#### macOS:

```bash
brew install cc65
```

### 3. NES Emulator (для тестирования)

Выберите любой эмулятор:

- **FCEUX** - https://fceux.com/web/download.html (рекомендуется для отладки)
- **Mesen** - https://www.mesen.ca/ (точный, современный интерфейс)
- **Nestopia** - https://sourceforge.net/projects/nestopia/
- **RetroArch** - https://www.retroarch.com/

## Быстрая проверка

После установки всех компонентов:

```bash
# 1. Соберите компилятор
dotnet build

# 2. Скомпилируйте пример
dotnet run examples/test_sprites.den

# 3. Проверьте, что создался файл
ls NesOutput/test_sprites.nes

# 4. Откройте в эмуляторе
# Windows:
start NesOutput/test_sprites.nes

# Linux:
fceux NesOutput/test_sprites.nes

# macOS:
open NesOutput/test_sprites.nes
```

## Устранение проблем

### "ca65 is not recognized..."

Проблема: ca65 не найден в PATH

Решение:
1. Убедитесь, что cc65 установлен
2. Проверьте PATH: `echo %PATH%` (Windows) или `echo $PATH` (Linux/Mac)
3. Перезапустите терминал после добавления в PATH

### "An error occurred while assembling..."

Проблема: Ошибка в сгенерированном ассемблере

Решение:
1. Проверьте `NesOutput/*.asm` файл на ошибки
2. Посмотрите на вывод компилятора в консоли
3. Попробуйте другой пример: `dotnet run examples/test_arithmetic.den`

### Файл .nes создается, но не работает в эмуляторе

Проблема: Некорректный ROM

Решение:
1. Убедитесь, что используете правильный эмулятор
2. Проверьте, что файл `NesTemplates/defaultchar.chr` существует
3. Попробуйте простой пример: `dotnet run examples/test_sprites.den`

## Альтернатива: Использование только ассемблера

Если вы хотите только генерировать .asm файлы без сборки в .nes:

1. Откройте `src/Program.cs`
2. Закомментируйте строки 94-110 (запуск bat файла)
3. Файлы .asm будут создаваться в `NesOutput/`
4. Собирайте вручную:
   ```bash
   ca65 NesOutput/yourfile.asm -o NesOutput/yourfile.o -t nes
   ld65 NesOutput/yourfile.o -o NesOutput/yourfile.nes -C NesTools/custom_nes.cfg
   ```

## Структура после установки

```
YourNes/
├── src/                # Исходники компилятора
├── examples/           # Примеры программ
├── docs/               # Документация
├── NesTemplates/       # Шаблоны NES
├── NesTools/           # Скрипты сборки
│   ├── generate_nes.bat    # Вызывает ca65/ld65
│   └── custom_nes.cfg      # Конфигурация линковщика
├── NesOutput/          # Генерируемые файлы
│   ├── *.asm           # Ассемблер 6502
│   ├── *.o             # Объектные файлы
│   └── *.nes           # Готовые ROM'ы
└── bin/                # Скомпилированный компилятор
```

## Полезные ссылки

- **cc65 документация**: https://cc65.github.io/doc/
- **NES Dev Wiki**: https://www.nesdev.org/wiki/
- **6502 Assembly**: https://www.masswerk.at/6502/6502_instruction_set.html
- **FCEUX отладчик**: https://fceux.com/web/help/Debugger.html
