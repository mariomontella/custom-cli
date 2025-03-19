# 🚀 custom-cli 

custom-cli è un semplice strumento per generare rapidamente un nuovo progetto Flutter con configurazioni personalizzate.

## 📥 Installazione

### 1️⃣ Requisiti
- [Dart SDK](https://dart.dev/get-dart) installato
- Flutter installato e configurato

### 2️⃣ Clonare il repository
```sh
git clone https://github.com/mariomontella/custom-cli.git
cd custom-cli
```

### 3️⃣ Installazione Globale
Per poter usare la CLI ovunque nel sistema:
```sh
dart pub global activate --source path .
```
⚠️ Se il comando non viene trovato, assicurati di aggiungere Dart al **PATH**:
```sh
export PATH="$HOME/.pub-cache/bin:$PATH"
```
Puoi aggiungerlo in `.bashrc`, `.zshrc` o `.bash_profile` per renderlo permanente.

---

## 🏃‍♂️ Utilizzo
Una volta installata, puoi eseguire la CLI con:
```sh
mia_cli --name "NomeProgetto" --template "bloc" --with-tests
```

### 📜 Opzioni disponibili
| Opzione            | Alias | Descrizione                                      |
|--------------------|-------|--------------------------------------------------|
| `--name`          | `-n`  | Nome del progetto                               |
| `--template`      | `-t`  | Template da usare (`default`, `mvvm`, `bloc`)   |
| `--no-firebase`   |       | Escludi Firebase dalle dipendenze               |
| `--with-tests`    |       | Aggiungi configurazione test unitari            |
| `--with-analytics`|       | Aggiungi configurazione analytics               |
| `--description`   |       | Descrizione del progetto                        |
| `--organization`  |       | ID organizzazione (default: `com.example`)     |
| `--help`          | `-h`  | Mostra l'help                                   |

Esempi di utilizzo:
```sh
mia_cli --name "SuperApp" --template "mvvm" --no-firebase
```
```sh
mia_cli --name "TestApp" --with-tests --with-analytics
```

---

## 🛠 Sviluppo
Per eseguire la CLI localmente senza installarla globalmente:
```sh
dart run bin/main.dart --name "ProvaCLI"
```

Per rendere lo script eseguibile direttamente:
```sh
chmod +x bin/main.dart
./bin/main.dart --help
```

---

## 📝 Contributi
Se vuoi migliorare questa CLI, sentiti libero di fare una pull request o aprire un'issue! 🎯

---

## 📜 Licenza
Questo progetto è rilasciato sotto la licenza MIT.

---

🔥 **Buon coding** 🚀

