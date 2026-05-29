CXX = g++
CXXFLAGS = -std=c++17 -Wall
TARGET = filesearch

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $(TARGET) main.cpp

clean:
	rm -f $(TARGET)
