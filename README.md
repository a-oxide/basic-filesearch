# filesearch

Compares linear array search vs hash table search for finding files on a filesystem. Uses podman to create a virtual ubuntu filesystem for testing. 

Sources:
https://cp-algorithms.com/string/string-hashing.html
gemma3:4b for line completions.

## How it works

1. Scans a directory for up to 100,000 files
2. Stores file paths in both a flat array and a hash table
3. Lets you search by exact filename, extension (`.txt`), or substring
4. Reports which method was faster and by how much

## Hash table details

- 10,007 buckets with chaining (vectors)
- Polynomial hash function (multiplier 31)
- Two-phase search: O(1) for exact filenames, O(n) fallback for substring/extension

## Usage

```
./demo.sh            interactive menu
./demo.sh test       run automated test suite
./demo.sh shell      drop into a bash shell
./demo.sh clean      remove the podman image
```

## Building locally

```
make
./filesearch
```

Requires `g++` with C++17 support.

## Files

| File | Purpose |
|------|---------|
| main.cpp | Hash table, search logic, CLI |
| Makefile | Builds the project |
| Dockerfile | Ubuntu 24.04 container |
| demo.sh | Podman launcher |
| setup_test_files.sh | Creates ~50k test files |
| test_search.sh | 80 test cases with timing |

