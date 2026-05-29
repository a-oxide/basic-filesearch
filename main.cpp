#include <iostream>
#include <string>
#include <vector>
#include <filesystem>
#include <chrono>

using namespace std;
namespace fs = std::filesystem;

const int SIZE = 997;
const int MAX_FILES = 100000;

// pre: path is a valid file path
// post: returns the filename after the last '/'
string getBasename(string path) {
    int lastSlash = -1;
    for (int i = 0; i < path.length(); i++) {
        if (path[i] == '/') {
            lastSlash = i;
        }
    }
    if (lastSlash == -1) {
        return path;
    }
    return path.substr(lastSlash + 1);
}

// pre: filePath and query are valid strings
// post: returns true if query matches by extension
//       or by substring
bool matches(string filePath, string query) {
    string basename = getBasename(filePath);
    int qLen = query.length();
    int bLen = basename.length();
    bool result = false;

    if (qLen == 0) {
        return false;
    }

    if (query[0] == '.') {
        if (bLen >= qLen) {
            bool extMatch = true;
            for (int i = 0; i < qLen; i++) {
                if (basename[bLen - qLen + i] != query[i]) {
                    extMatch = false;
                }
            }
            result = extMatch;
        }
    } else {
        if (bLen >= qLen) {
            for (int i = 0; i <= bLen - qLen; i++) {
                bool subMatch = true;
                for (int j = 0; j < qLen; j++) {
                    if (basename[i + j] != query[j]) {
                        subMatch = false;
                    }
                }
                if (subMatch) {
                    result = true;
                }
            }
        }
    }

    return result;
}

// hash table with chaining
class HashTable {

private:

    vector<string> table[SIZE];

    // sum ascii values, mod SIZE
    int hashFunction(string key) {
        int sum = 0;
        for (int i = 0; i < key.length(); i++) {
            sum = sum + (int)key[i];
        }
        return sum % SIZE;
    }

public:

    // pre: path is a valid string
    // post: path is inserted by the hash of its basename
    void insert(string path) {
        string name = getBasename(path);
        int index = hashFunction(name);
        table[index].push_back(path);
    }

    // pre: query is a search term
    // post: returns all matching file paths
    vector<string> search(string query) {
        vector<string> results;
        for (int i = 0; i < SIZE; i++) {
            for (int j = 0; j < table[i].size(); j++) {
                if (matches(table[i][j], query)) {
                    results.push_back(table[i][j]);
                }
            }
        }
        return results;
    }

    // post: returns total number of stored entries
    int getElementCount() {
        int count = 0;
        for (int i = 0; i < SIZE; i++) {
            count = count + table[i].size();
        }
        return count;
    }
};

// simple timer
class Timer {

private:

    chrono::high_resolution_clock::time_point startTime;

public:

    void start() {
        startTime = chrono::high_resolution_clock::now();
    }

    long long stop() {
        chrono::high_resolution_clock::time_point nowTime
            = chrono::high_resolution_clock::now();
        return chrono::duration_cast<chrono::microseconds>(
            nowTime - startTime).count();
    }
};

// pre: rootPath is a valid directory path
// post: fills fileArray with all file paths, returns count
int scanDirectory(string rootPath, string fileArray[],
                  int maxSize) {
    int count = 0;
    fs::recursive_directory_iterator it(rootPath);
    fs::recursive_directory_iterator end;
    bool more = true;

    while (it != end && more) {
        if (count >= maxSize) {
            more = false;
        } else {
            if (fs::is_regular_file(it->path())) {
                fileArray[count] = it->path().string();
                count++;
            }
            ++it;
        }
    }

    return count;
}

int main() {
    string fileArray[MAX_FILES];
    int fileCount = 0;

    cout << "scanning /home/pi..." << endl;
    fileCount = scanDirectory("/home/pi", fileArray,
                              MAX_FILES);
    cout << "found " << fileCount << " files" << endl
         << endl;

    HashTable ht;
    for (int i = 0; i < fileCount; i++) {
        ht.insert(fileArray[i]);
    }
    cout << "hash table built with "
         << ht.getElementCount() << " entries" << endl
         << endl;

    bool running = true;
    while (running) {
        string query;
        cout << "enter search (or 'quit'):" << endl;
        getline(cin, query);

        if (query == "quit") {
            running = false;
        } else if (query.length() > 0) {

            Timer t1;
            t1.start();
            vector<string> linResults;
            for (int i = 0; i < fileCount; i++) {
                if (matches(fileArray[i], query)) {
                    linResults.push_back(fileArray[i]);
                }
            }
            long long linTime = t1.stop();

            Timer t2;
            t2.start();
            vector<string> hashResults
                = ht.search(query);
            long long hashTime = t2.stop();

            cout << "linear: " << linTime
                 << " us, " << linResults.size()
                 << " results" << endl;
            cout << "hash:   " << hashTime
                 << " us, " << hashResults.size()
                 << " results" << endl;

            if (linTime < hashTime) {
                cout << "linear faster by "
                     << (hashTime - linTime) << " us"
                     << endl;
            } else if (hashTime < linTime) {
                cout << "hash faster by "
                     << (linTime - hashTime) << " us"
                     << endl;
            } else {
                cout << "same time" << endl;
            }

            if (hashResults.size() > 0) {
                cout << "matches:" << endl;
                int showCount = 10;
                if (hashResults.size() < 10) {
                    showCount = hashResults.size();
                }
                for (int i = 0; i < showCount; i++) {
                    string name
                        = getBasename(hashResults[i]);
                    cout << "  " << name << endl;
                }
                if (hashResults.size() > 10) {
                    cout << "  ... and "
                         << (hashResults.size() - 10)
                         << " more" << endl;
                }
            }
            cout << endl;
        }
    }

    return 0;
}
