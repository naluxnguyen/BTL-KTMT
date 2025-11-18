#include <iostream>
#include <fstream>
#include <cmath>
#include <iomanip>
#include <string>
#include <vector>
using namespace std;

#define MAX_SIZE 10

void computeAutocorrelation(double signal[MAX_SIZE], double autocorr[MAX_SIZE], int N) {
    for (int lag = 0; lag < N; ++lag) {
        double s = 0.0;
        for (int n = 0; n < N - lag; ++n) s += signal[n] * signal[n + lag];
        autocorr[lag] = s;
    }
}

void computeCrosscorrelation(double desired[MAX_SIZE], double input[MAX_SIZE], double crosscorr[MAX_SIZE], int N) {
    for (int lag = 0; lag < N; ++lag) {
        double s = 0.0;
        for (int n = 0; n < N - lag; ++n) s += desired[n + lag] * input[n];
        crosscorr[lag] = s;
    }
}

void createToeplitzMatrix(double autocorr[MAX_SIZE], double R[MAX_SIZE][MAX_SIZE], int N) {
    for (int i = 0; i < N; ++i)
        for (int j = 0; j < N; ++j)
            R[i][j] = autocorr[abs(i - j)];
}

void solveLinearSystem(double A[MAX_SIZE][MAX_SIZE], double b[MAX_SIZE], double x[MAX_SIZE], int N) {
    vector<vector<double>> M(N, vector<double>(N+1));
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) M[i][j] = A[i][j];
        M[i][N] = b[i];
    }

    for (int col = 0; col < N; ++col) {
        int piv = col;
        double maxv = fabs(M[col][col]);
        for (int r = col+1; r < N; ++r) {
            if (fabs(M[r][col]) > maxv) { maxv = fabs(M[r][col]); piv = r; }
        }
        if (piv != col) swap(M[piv], M[col]);

        if (fabs(M[col][col]) < 1e-12) {
            M[col][col] = 1e-12;
        }

        for (int r = col+1; r < N; ++r) {
            double factor = M[r][col] / M[col][col];
            for (int c = col; c <= N; ++c) M[r][c] -= factor * M[col][c];
        }
    }

    vector<double> sol(N, 0.0);
    for (int i = N-1; i >= 0; --i) {
        double s = M[i][N];
        for (int j = i+1; j < N; ++j) s -= M[i][j] * sol[j];
        sol[i] = s / M[i][i];
    }
    for (int i = 0; i < N; ++i) x[i] = sol[i];
}

void computeWienerCoefficients(double desired[MAX_SIZE], double input[MAX_SIZE], int N, double coefficients[MAX_SIZE]) {
    double autocorr[MAX_SIZE];
    double crosscorr[MAX_SIZE];
    double R[MAX_SIZE][MAX_SIZE];

    computeAutocorrelation(input, autocorr, N);
    computeCrosscorrelation(desired, input, crosscorr, N);
    createToeplitzMatrix(autocorr, R, N);
    solveLinearSystem(R, crosscorr, coefficients, N);
}

void applyWienerFilter(double input[MAX_SIZE], double coefficients[MAX_SIZE], double output[MAX_SIZE], int N) {
    for (int n = 0; n < N; ++n) {
        double s = 0.0;
        for (int k = 0; k <= n; ++k) s += coefficients[k] * input[n - k];
        output[n] = s;
    }
}

double computeMMSE(double desired[MAX_SIZE], double output[MAX_SIZE], int N) {
    double sum = 0.0;
    for (int i = 0; i < N; ++i) {
        double err = desired[i] - output[i];
        sum += err * err;
    }
    return sum / N;
}

int readSignalFromFile(const string &filename, double signal[MAX_SIZE]) {
    ifstream file(filename);
    if (!file.is_open()) throw runtime_error("Cannot open file: " + filename);
    int count = 0;
    double val;
    while (file >> val) {
        signal[count++] = val;
        if (count >= MAX_SIZE) break;
    }
    file.close();
    return count;
}

void writeOutputToFile(const string &filename, double output[MAX_SIZE], int N, double mmse) {
    ofstream file(filename);
    if (!file.is_open()) throw runtime_error("Cannot open file: " + filename);

    file << "Filtered output:";
    file << fixed << setprecision(1);
    for (int i = 0; i < N; ++i) {
        double y_display = round(output[i] * 10.0) / 10.0; 
        if (y_display == 0.0) y_display = 0.0; 
        file << " " << y_display;
    }

    double mmse_rounded = round(mmse * 100.0) / 100.0;
    file << "\nMMSE: " << fixed << setprecision(1) << mmse_rounded << endl;
    file.close();
}


int main() {
    try {
        double desired[MAX_SIZE], input[MAX_SIZE], output[MAX_SIZE], coefficients[MAX_SIZE];

        int SIZE = readSignalFromFile("desired.txt", desired);
        int N2 = readSignalFromFile("input.txt", input);

        if (SIZE != N2) {
            ofstream errorFile("output.txt");
            errorFile << "Error: size not match" << endl;
            errorFile.close();
            cerr << "Error: size not match" << endl;
            return 0;
        }

        computeWienerCoefficients(desired, input, SIZE, coefficients);
        applyWienerFilter(input, coefficients, output, SIZE);
        double mmse = computeMMSE(desired, output, SIZE);
        writeOutputToFile("output.txt", output, SIZE, mmse);
        cout << "Done! Check output.txt for results." << endl;

    } catch (const exception &e) {
        cerr << "Error: " << e.what() << endl;
        ofstream errorFile("output.txt");
        errorFile << e.what() << endl;
        errorFile.close();
        return 1;
    }

    return 0;
}